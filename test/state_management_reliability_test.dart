import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/models/game_state.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/core/game_state_machine.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';

void main() {
  group('Phase 1C: Game State & Turn Management Reliability Suite', () {
    late GameStateMachine fsm;

    setUp(() {
      fsm = GameStateMachine(GameState.placingStriker);
    });

    test('1. Normal turn lifecycle transition sequence', () {
      expect(fsm.currentState, GameState.placingStriker);
      expect(fsm.isInteractive, isTrue);

      // Player touches board to aim
      expect(fsm.transitionTo(GameState.aiming), isTrue);
      expect(fsm.currentState, GameState.aiming);
      expect(fsm.isAiming, isTrue);
      expect(fsm.isInteractive, isFalse);

      // Player releases drag with sufficient power
      expect(fsm.transitionTo(GameState.simulating), isTrue);
      expect(fsm.currentState, GameState.simulating);
      expect(fsm.isSimulating, isTrue);

      // Physics engine settles; shot evaluation begins
      expect(fsm.transitionTo(GameState.evaluating), isTrue);
      expect(fsm.currentState, GameState.evaluating);
      expect(fsm.isSimulating, isFalse);

      // Designated pieces return to center
      expect(fsm.transitionTo(GameState.respotting), isTrue);
      expect(fsm.currentState, GameState.respotting);

      // Turn resets for next player
      expect(fsm.transitionTo(GameState.placingStriker), isTrue);
      expect(fsm.currentState, GameState.placingStriker);
      expect(fsm.isInteractive, isTrue);
    });

    test('2. Input protection: Direct double-tap / mid-simulation input is rejected', () {
      fsm.transitionTo(GameState.aiming);
      fsm.transitionTo(GameState.simulating);

      // Player tries to aim or fire again while pieces are simulating
      expect(fsm.canTransitionTo(GameState.aiming), isFalse);
      expect(fsm.transitionTo(GameState.aiming), isFalse);
      expect(fsm.currentState, GameState.simulating);

      // Player tries to force cpuThinking while simulating
      expect(fsm.canTransitionTo(GameState.cpuThinking), isFalse);
      expect(fsm.transitionTo(GameState.cpuThinking), isFalse);
      expect(fsm.currentState, GameState.simulating);
    });

    test('3. Gesture cancellation returns safely to placingStriker', () {
      fsm.transitionTo(GameState.aiming);
      expect(fsm.currentState, GameState.aiming);

      // Drag cancelled or released with distance <= 15px
      expect(fsm.transitionTo(GameState.placingStriker), isTrue);
      expect(fsm.currentState, GameState.placingStriker);
      expect(fsm.isInteractive, isTrue);
    });

    test('4. Comprehensive Pause & Resume matrix', () {
      // 4A: Pause from placingStriker
      fsm.reset(GameState.placingStriker);
      expect(fsm.transitionTo(GameState.paused), isTrue);
      expect(fsm.currentState, GameState.paused);
      expect(fsm.resolveResumeState(), GameState.placingStriker);
      expect(fsm.transitionTo(fsm.resolveResumeState()), isTrue);
      expect(fsm.currentState, GameState.placingStriker);

      // 4B: Pause during simulation (preserves rolling pieces)
      fsm.transitionTo(GameState.aiming);
      fsm.transitionTo(GameState.simulating);
      expect(fsm.transitionTo(GameState.paused), isTrue);
      expect(fsm.currentState, GameState.paused);
      expect(fsm.resolveResumeState(), GameState.simulating);
      expect(fsm.transitionTo(fsm.resolveResumeState()), isTrue);
      expect(fsm.currentState, GameState.simulating);

      // 4C: Pause during aiming (interrupted drag must revert to placingStriker)
      fsm.reset(GameState.aiming);
      expect(fsm.transitionTo(GameState.paused), isTrue);
      expect(fsm.resolveResumeState(), GameState.placingStriker);
      expect(fsm.transitionTo(fsm.resolveResumeState()), isTrue);
      expect(fsm.currentState, GameState.placingStriker);

      // 4D: Pause during CPU thinking
      fsm.reset(GameState.cpuThinking);
      expect(fsm.transitionTo(GameState.paused), isTrue);
      expect(fsm.resolveResumeState(), GameState.cpuThinking);
      expect(fsm.transitionTo(fsm.resolveResumeState()), isTrue);
      expect(fsm.currentState, GameState.cpuThinking);
    });

    test('5. Turn Evaluation Single-Fire: Prevents duplicate scoring', () {
      fsm.transitionTo(GameState.aiming);
      fsm.transitionTo(GameState.simulating);

      int evaluationCount = 0;
      void onSimulationComplete() {
        if (fsm.transitionTo(GameState.evaluating)) {
          evaluationCount++;
        }
      }

      // Simulate first ticker event detecting piece stop
      onSimulationComplete();
      expect(evaluationCount, equals(1));
      expect(fsm.currentState, GameState.evaluating);

      // Subsequent ticks while evaluation is running
      onSimulationComplete();
      expect(evaluationCount, equals(1), reason: 'Evaluation must not run twice');
    });

    test('6. CPU Generational Cancellation on match restart/pause', () async {
      int turnExecutionId = 0;
      bool shotFired = false;
      Timer? cpuThinkingTimer;
      Timer? cpuAimTimer;

      void cancelCpu() {
        turnExecutionId++;
        cpuThinkingTimer?.cancel();
        cpuThinkingTimer = null;
        cpuAimTimer?.cancel();
        cpuAimTimer = null;
      }

      void scheduleCpu() {
        fsm.transitionTo(GameState.cpuThinking);
        cancelCpu();
        final int scheduledId = turnExecutionId;

        cpuThinkingTimer = Timer(const Duration(milliseconds: 50), () {
          if (scheduledId != turnExecutionId) return;
          if (fsm.currentState != GameState.cpuThinking) return;

          cpuAimTimer = Timer(const Duration(milliseconds: 50), () {
            if (scheduledId != turnExecutionId) return;
            if (fsm.currentState != GameState.cpuThinking) return;

            shotFired = true;
          });
        });
      }

      // Start CPU schedule
      scheduleCpu();
      expect(fsm.currentState, GameState.cpuThinking);

      // Rapidly restart match before CPU timers elapse (20ms)
      await Future.delayed(const Duration(milliseconds: 20));
      cancelCpu();
      fsm.reset(GameState.placingStriker);

      // Wait for original timers to pass
      await Future.delayed(const Duration(milliseconds: 120));

      expect(shotFired, isFalse, reason: 'Stale CPU timer must be cancelled');
      expect(fsm.currentState, GameState.placingStriker);
    });

    test('7. Striker Placement Validation: Overlap detection and bounds', () {
      final List<PieceModel> pieces = [
        PieceModel(
          id: 1,
          type: PieceType.white,
          position: Vector2(0.0, GameConfig.baselineYWhite),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: Vector2(0.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      bool isPositionClear(Vector2 pos) {
        final double minSeparation = striker.radius + GameConfig.pieceRadius - 0.5;
        for (final p in pieces) {
          if (!p.isPocketed) {
            if ((p.position - pos).length < minSeparation) {
              return false;
            }
          }
        }
        return true;
      }

      // Striker positioned directly on top of white piece (0, 142)
      expect(isPositionClear(Vector2(0.0, GameConfig.baselineYWhite)), isFalse);

      // Striker positioned tangentially overlapping (dist = 20 < 28 - 0.5)
      expect(isPositionClear(Vector2(20.0, GameConfig.baselineYWhite)), isFalse);

      // Striker positioned with clear separation (dist = 35 >= 27.5)
      expect(isPositionClear(Vector2(35.0, GameConfig.baselineYWhite)), isTrue);
    });

    test('8. Game Mode Turn Transitions: VS CPU vs Pass & Play vs Practice', () {
      // 8A: VS CPU mode -> Switch from White to Black transitions to cpuThinking
      GameState resolveNextTurnState({
        required GameMode mode,
        required PlayerColor nextPlayer,
      }) {
        if (mode == GameMode.practice) {
          return GameState.placingStriker;
        }
        if (mode == GameMode.vsCpu && nextPlayer == PlayerColor.black) {
          return GameState.cpuThinking;
        }
        return GameState.placingStriker;
      }

      expect(
        resolveNextTurnState(mode: GameMode.vsCpu, nextPlayer: PlayerColor.black),
        GameState.cpuThinking,
      );

      // 8B: Pass & Play mode -> Switch to Black transitions to placingStriker
      expect(
        resolveNextTurnState(mode: GameMode.passAndPlay, nextPlayer: PlayerColor.black),
        GameState.placingStriker,
      );

      // 8C: Practice mode -> Stays placingStriker
      expect(
        resolveNextTurnState(mode: GameMode.practice, nextPlayer: PlayerColor.white),
        GameState.placingStriker,
      );
    });

    test('9. Game Over Lock: Disallows game simulation and inputs until rematch', () {
      fsm.reset(GameState.evaluating);
      expect(fsm.transitionTo(GameState.gameOver), isTrue);
      expect(fsm.currentState, GameState.gameOver);
      expect(fsm.isGameOver, isTrue);

      // Cannot aim or simulate while match is over
      expect(fsm.canTransitionTo(GameState.aiming), isFalse);
      expect(fsm.canTransitionTo(GameState.simulating), isFalse);
      expect(fsm.canTransitionTo(GameState.cpuThinking), isFalse);

      // Only valid transition is rematch / new match
      expect(fsm.canTransitionTo(GameState.placingStriker), isTrue);
      expect(fsm.transitionTo(GameState.placingStriker), isTrue);
      expect(fsm.currentState, GameState.placingStriker);
    });

    test('10. Rapid pause toggle stability (no state degradation)', () {
      fsm.reset(GameState.simulating);

      for (int i = 0; i < 5; i++) {
        expect(fsm.transitionTo(GameState.paused), isTrue);
        expect(fsm.currentState, GameState.paused);
        expect(fsm.transitionTo(fsm.resolveResumeState()), isTrue);
        expect(fsm.currentState, GameState.simulating);
      }
    });
  });
}
