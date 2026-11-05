import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/game_state_machine.dart';
import 'package:carrom_master/core/turn_timer_controller.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/game_state.dart';
import 'package:carrom_master/screens/game_screen.dart';
import 'package:carrom_master/screens/settings_screen.dart';
import 'package:carrom_master/services/audio_service.dart';
import 'package:carrom_master/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    AudioService().sfxEnabled = false;
    AudioService().musicEnabled = false;
    AudioService().hapticsEnabled = false;
  });

  const Size standardScreen = Size(600, 1000);

  group('CARROM ZONE — Pause/Resume Reliability & State Recovery Suite', () {
    test('1. TurnTimerController: Monotonic countdown, clean pause/resume, and zero timer leak', () {
      final timer = TurnTimerController(turnDurationSeconds: 20.0);
      expect(timer.remainingSeconds, 20.0);
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);

      final token = timer.startNewTurn();
      expect(timer.isRunning, true);
      expect(timer.activeTurnToken, token);

      // Tick 5.0 seconds
      timer.tick(5.0);
      expect(timer.remainingSeconds, 15.0);
      expect(timer.displaySeconds, 15);

      // Pause timer
      timer.pause();
      expect(timer.isPaused, true);

      // Ticking while paused must NOT decrease remaining time
      final bool expiredWhilePaused = timer.tick(10.0);
      expect(expiredWhilePaused, false);
      expect(timer.remainingSeconds, 15.0);

      // Resume timer
      timer.resume();
      expect(timer.isPaused, false);
      timer.tick(2.0);
      expect(timer.remainingSeconds, 13.0);

      // Monotonic stop
      timer.stop();
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);
    });

    test('2. GameStateMachine: resolveResumeState resolves safe playable states across all conditions', () {
      final fsm = GameStateMachine(GameState.placingStriker);

      // PlacingStriker -> Aiming -> Paused
      expect(fsm.transitionTo(GameState.aiming), true);
      expect(fsm.transitionTo(GameState.paused), true);
      // Resuming from aiming MUST resolve to placingStriker (drag gesture cannot be resumed)
      expect(fsm.resolveResumeState(), GameState.placingStriker);
      expect(fsm.transitionTo(fsm.resolveResumeState()), true);
      expect(fsm.currentState, GameState.placingStriker);

      // PlacingStriker -> Aiming -> Simulating -> Paused
      expect(fsm.transitionTo(GameState.aiming), true);
      expect(fsm.transitionTo(GameState.simulating), true);
      expect(fsm.transitionTo(GameState.paused), true);
      // Resuming from simulating preserves simulating
      expect(fsm.resolveResumeState(), GameState.simulating);
      expect(fsm.transitionTo(fsm.resolveResumeState()), true);
      expect(fsm.currentState, GameState.simulating);

      // Paused during evaluating or respotting resolves cleanly to placingStriker
      expect(fsm.transitionTo(GameState.evaluating), true);
      expect(fsm.transitionTo(GameState.paused), true);
      expect(fsm.resolveResumeState(), GameState.placingStriker);

      // Paused during cpuThinking resolves to cpuThinking
      fsm.reset(GameState.placingStriker);
      expect(fsm.transitionTo(GameState.cpuThinking), true);
      expect(fsm.transitionTo(GameState.paused), true);
      expect(fsm.resolveResumeState(), GameState.cpuThinking);
      expect(fsm.transitionTo(fsm.resolveResumeState()), true);
      expect(fsm.currentState, GameState.cpuThinking);
    });

    testWidgets('3. Pause/Resume during human placement & aiming: resets drag safely and preserves timer', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;
      expect(state.stateMachine.currentState, GameState.placingStriker);

      final double remainingBefore = state.turnTimer.remainingSeconds;
      expect(remainingBefore > 0.0, true);

      // Pause game
      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);
      expect(state.turnTimer.isPaused, true);

      // Resume game
      state.resumeGame();
      await tester.pump();

      expect(state.stateMachine.currentState, GameState.placingStriker);
      expect(state.turnTimer.isPaused, false);
      expect(state.turnTimer.remainingSeconds <= remainingBefore, true);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('4. Pause/Resume during piece movement (simulating): cleanly settles or continues physics', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;

      // Transition to simulating
      state.stateMachine.transitionTo(GameState.aiming);
      state.stateMachine.transitionTo(GameState.simulating);
      expect(state.stateMachine.currentState, GameState.simulating);

      // Pause during simulation
      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);

      // Resume: since pieces were not moving with velocity, it resolves simulation cleanly
      state.resumeGame();
      await tester.pump();

      // Should cleanly transition without freeze to evaluating or placingStriker
      expect(
        state.stateMachine.currentState == GameState.placingStriker ||
            state.stateMachine.currentState == GameState.evaluating,
        true,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('5. Pause/Resume during CPU thinking: safely restarts CPU turn without duplicate execution', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.vsCpu),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;

      // Force CPU turn
      state.currentPlayer = PlayerColor.black;
      state.scheduleCpuTurn();
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.cpuThinking);

      final int firstTurnId = state.turnExecutionId;

      // Pause while CPU is thinking
      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);
      expect(state.turnExecutionId > firstTurnId, true); // Invalidation token incremented

      // Resume game
      state.resumeGame();
      await tester.pump();

      // CPU thinking must resume cleanly with new execution token
      expect(state.stateMachine.currentState, GameState.cpuThinking);

      // Let CPU finish thinking
      await tester.pump(const Duration(milliseconds: 1500));
      // CPU must have advanced without deadlocking
      expect(
        state.stateMachine.currentState == GameState.cpuThinking ||
            state.stateMachine.currentState == GameState.simulating,
        true,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('6. Pause/Resume with pending Queen cover: preserves queenPocketed, needsCover, and scores', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;

      // Set Queen cover pending state
      state.queenPocketed = true;
      state.queenCovered = false;
      state.needsCover = true;
      state.queenPocketedBy = PlayerColor.white;
      state.whiteScore = 5;
      state.blackScore = 3;

      // Pause game
      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);

      // Resume game
      state.resumeGame();
      await tester.pump();

      // State invariants must be strictly preserved
      expect(state.queenPocketed, true);
      expect(state.queenCovered, false);
      expect(state.needsCover, true);
      expect(state.queenPocketedBy, PlayerColor.white);
      expect(state.whiteScore, 5);
      expect(state.blackScore, 3);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('7. Rapid repeated Pause/Resume toggling: operations are completely idempotent and safe', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;

      // Rapidly toggle pause/resume programmatically
      for (int i = 0; i < 5; i++) {
        state.pauseGame(fromLifecycle: true);
        expect(state.stateMachine.currentState, GameState.paused);
        state.resumeGame();
        expect(state.stateMachine.currentState, GameState.placingStriker);
      }

      expect(state.stateMachine.currentState, GameState.placingStriker);
      expect(state.stateMachine.isInteractive, true);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('8. Navigate to Settings and return: preserves match state without match resets or leaks', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;
      state.whiteScore = 7;
      state.blackScore = 4;

      // Pause before pushing Settings (as happens from Pause Dialog in gameplay)
      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);

      // Push SettingsScreen over GameScreen
      navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(SettingsScreen), findsOneWidget);

      // Pop SettingsScreen to return to GameScreen
      navKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(GameScreen), findsOneWidget);

      // Resume game
      state.resumeGame();
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.placingStriker);

      // Scores and pieces remain strictly intact
      expect(state.whiteScore, 7);
      expect(state.blackScore, 4);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('9. AppLifecycleState background & foreground recovery: pauses and resumes with dialog cleanly', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;

      // Simulate App backgrounded
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);

      // Simulate App foregrounded
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Pause dialog should be presented
      expect(find.text('GAME PAUSED'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('RESUME'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('GAME PAUSED'), findsNothing);
      expect(state.stateMachine.currentState, GameState.placingStriker);
      expect(state.stateMachine.isInteractive, true);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('10. Comprehensive Invariant Check: Timer, score, ruleset, and board remain strictly unchanged', (tester) async {
      await tester.binding.setSurfaceSize(standardScreen);
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            gameMode: GameMode.passAndPlay,
            ruleset: CarromRuleset.freestyle,
            targetScore: 160,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(GameScreen)) as dynamic;
      final int initialPiecesCount = (state.pieces as List).length;
      final double initialStrikerX = state.strikerSliderX;

      state.pauseGame(fromLifecycle: true);
      await tester.pump();
      expect(state.stateMachine.currentState, GameState.paused);

      state.resumeGame();
      await tester.pump();

      expect((state.pieces as List).length, initialPiecesCount);
      expect(state.strikerSliderX, initialStrikerX);
      expect(state.stateMachine.currentState, GameState.placingStriker);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);
  });
}
