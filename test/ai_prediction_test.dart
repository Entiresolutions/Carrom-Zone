import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/ai/carrom_ai.dart';

void main() {
  group('Phase 2A: Intelligent AI & Physics-Based Prediction Suite', () {
    test('1. Live State Isolation: Prediction never mutates live pieces or striker', () {
      final queen = PieceModel(
        id: 1,
        type: PieceType.queen,
        position: const Vector2(0.0, 0.0),
        velocity: Vector2.zero,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
        isPocketed: false,
      );

      final whitePiece = PieceModel(
        id: 2,
        type: PieceType.white,
        position: const Vector2(-30.0, 40.0),
        velocity: Vector2.zero,
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
        isPocketed: false,
      );

      final blackPiece = PieceModel(
        id: 3,
        type: PieceType.black,
        position: const Vector2(40.0, -50.0),
        velocity: Vector2.zero,
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
        isPocketed: false,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        velocity: Vector2.zero,
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
        isPocketed: false,
      );

      final pieces = [queen, whitePiece, blackPiece];

      // Deep record of initial state
      final initialPositions = pieces.map((p) => Vector2(p.position.x, p.position.y)).toList();
      final initialVelocities = pieces.map((p) => Vector2(p.velocity.x, p.velocity.y)).toList();
      final initialPockets = pieces.map((p) => p.isPocketed).toList();
      final initialStrikerPos = Vector2(striker.position.x, striker.position.y);
      final initialStrikerVel = Vector2(striker.velocity.x, striker.velocity.y);

      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final shot = ai.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      // Verify valid shot returned
      expect(shot.strikerX.isNaN, isFalse);
      expect(shot.angle.isNaN, isFalse);
      expect(shot.power, inInclusiveRange(0.3, 1.0));

      // Assert complete isolation: pieces untouched
      for (int i = 0; i < pieces.length; i++) {
        expect(pieces[i].position.x, equals(initialPositions[i].x));
        expect(pieces[i].position.y, equals(initialPositions[i].y));
        expect(pieces[i].velocity.x, equals(initialVelocities[i].x));
        expect(pieces[i].velocity.y, equals(initialVelocities[i].y));
        expect(pieces[i].isPocketed, equals(initialPockets[i]));
      }

      // Assert striker untouched
      expect(striker.position.x, equals(initialStrikerPos.x));
      expect(striker.position.y, equals(initialStrikerPos.y));
      expect(striker.velocity.x, equals(initialStrikerVel.x));
      expect(striker.velocity.y, equals(initialStrikerVel.y));
      expect(striker.isPocketed, isFalse);
    });

    test('2. Physics Prediction Fidelity: Predicted pot succeeds in actual simulation', () {
      // Setup an open black coin aligned with Top-Left pocket (-178, -178)
      final targetPiece = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(-110.0, -110.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final pieces = [targetPiece];

      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final shot = ai.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      expect(shot.isPredictedPot, isTrue, reason: 'AI must predict a successful pot on open coin');

      // Now fire this exact calculated shot in actual CarromPhysics
      striker.position = Vector2(shot.strikerX, GameConfig.baselineYBlack);
      final double powerMag = shot.power * GameConfig.strikerMaxPower;
      striker.velocity = Vector2(
        math.cos(shot.angle) * powerMag,
        math.sin(shot.angle) * powerMag,
      );

      bool targetActuallyPocketed = false;
      bool strikerActuallyFouled = false;

      final realPhysics = CarromPhysics(
        pieces: pieces,
        striker: striker,
        onPocket: (piece, pocket) {
          if (piece.id == targetPiece.id) {
            targetActuallyPocketed = true;
          }
          if (piece.type == PieceType.striker) {
            strikerActuallyFouled = true;
          }
        },
      );
      realPhysics.resetAccumulator();

      for (int step = 0; step < 80; step++) {
        realPhysics.update(1.0 / 60.0);
        if (targetActuallyPocketed && !striker.isMoving) break;
      }

      expect(targetActuallyPocketed, isTrue, reason: 'Predicted pot must successfully drop in pocket');
      expect(strikerActuallyFouled, isFalse, reason: 'AI must not foul the striker on predicted shot');
    });

    test('3. Scratch / Foul Prevention: Rejects shots that would pocket the striker', () {
      // Place a target very close to the pocket where a straight blast would send striker in
      final closePiece = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(160.0, -160.0), // right in front of Top-Right pocket (178, -178)
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final shot = ai.calculateShot(
        pieces: [closePiece],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      // Verify that the chosen shot does not result in a striker foul
      striker.position = Vector2(shot.strikerX, GameConfig.baselineYBlack);
      final double powerMag = shot.power * GameConfig.strikerMaxPower;
      striker.velocity = Vector2(
        math.cos(shot.angle) * powerMag,
        math.sin(shot.angle) * powerMag,
      );

      bool strikerFouled = false;
      final physics = CarromPhysics(
        pieces: [closePiece],
        striker: striker,
        onPocket: (p, pocket) {
          if (p.type == PieceType.striker) strikerFouled = true;
        },
      );
      physics.resetAccumulator();

      for (int i = 0; i < 75; i++) {
        physics.update(1.0 / 60.0);
      }

      expect(strikerFouled, isFalse, reason: 'Simulation lookahead must prevent striker foul');
    });

    test('4. Striker Placement Invariant: Bounds and overlap avoidance', () {
      // Place an obstacle piece directly on the baseline at x = 0.0
      final baselineObstacle = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final targetPiece = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(50.0, 0.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final shot = ai.calculateShot(
        pieces: [baselineObstacle, targetPiece],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      // Must be within legal slider bounds
      expect(shot.strikerX, inInclusiveRange(-67.0, 67.0));

      // Striker position must not overlap baseline obstacle (dist >= 27.5)
      final chosenPos = Vector2(shot.strikerX, GameConfig.baselineYBlack);
      final distToObstacle = chosenPos.distanceTo(baselineObstacle.position);
      expect(
        distToObstacle,
        greaterThanOrEqualTo(GameConfig.strikerRadius + GameConfig.pieceRadius - 0.5),
        reason: 'AI must not choose a striker position overlapping a piece',
      );
    });

    test('5. Queen Cover Priority: Must target own pieces exclusively when cover needed', () {
      final queen = PieceModel(
        id: 1,
        type: PieceType.queen,
        position: const Vector2(20.0, 20.0),
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      );

      final myPiece = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(-80.0, -80.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final oppPiece = PieceModel(
        id: 3,
        type: PieceType.white,
        position: const Vector2(80.0, -80.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final shot = ai.calculateShot(
        pieces: [queen, myPiece, oppPiece],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: true, // Needs cover!
        queenCovered: false,
      );
      // The shot should be aimed toward myPiece, not Queen or opponent piece
      final strikerPos = Vector2(shot.strikerX, GameConfig.baselineYBlack);
      final shotDir = Vector2(math.cos(shot.angle), math.sin(shot.angle));

      final toMyPiece = (myPiece.position - strikerPos).normalized();
      final toOppPiece = (oppPiece.position - strikerPos).normalized();
      final toQueen = (queen.position - strikerPos).normalized();

      expect(shotDir.dot(toMyPiece), greaterThan(0.8), reason: 'Must target own piece for cover');
      expect(shotDir.dot(toOppPiece), lessThan(0.7));
      expect(shotDir.dot(toQueen), lessThan(shotDir.dot(toMyPiece)));
      expect(shotDir.dot(toQueen), lessThan(0.85));
    });

    test('6. Difficulty Jitter Variance: Hard is highly deterministic, Easy has calibrated spread', () {
      final target = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(0.0, -50.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      // Hard AI repeated shots
      final hardAngles = <double>[];
      for (int i = 0; i < 10; i++) {
        final hardAi = CarromAI(difficulty: AiDifficulty.hard);
        final shot = hardAi.calculateShot(
          pieces: [target],
          striker: striker,
          aiColor: PlayerColor.black,
          needsQueenCover: false,
          queenCovered: false,
        );
        hardAngles.add(shot.angle);
      }

      // Hard angle variance should be minimal (< 0.04 rad)
      final hardMin = hardAngles.reduce(math.min);
      final hardMax = hardAngles.reduce(math.max);
      expect(hardMax - hardMin, lessThan(0.05));

      // Easy AI repeated shots
      final easyAngles = <double>[];
      for (int i = 0; i < 10; i++) {
        final easyAi = CarromAI(difficulty: AiDifficulty.easy);
        final shot = easyAi.calculateShot(
          pieces: [target],
          striker: striker,
          aiColor: PlayerColor.black,
          needsQueenCover: false,
          queenCovered: false,
        );
        easyAngles.add(shot.angle);
      }

      final easyMin = easyAngles.reduce(math.min);
      final easyMax = easyAngles.reduce(math.max);
      expect(easyMax - easyMin, greaterThan(hardMax - hardMin), reason: 'Easy must have noticeably wider spread');
    });

    test('7. Decision Time Budget Benchmark: < 10ms average for full 19-piece board', () {
      List<PieceModel> createFullBoard() {
        final list = <PieceModel>[];
        int id = 1;
        list.add(PieceModel(
          id: id++,
          type: PieceType.queen,
          position: GameConfig.queenInitialPos,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        ));
        for (final p in GameConfig.innerRingPieces) {
          list.add(PieceModel(
            id: id++,
            type: (p['isWhite'] as bool) ? PieceType.white : PieceType.black,
            position: p['pos'] as Vector2,
            radius: GameConfig.pieceRadius,
            mass: GameConfig.pieceMass,
          ));
        }
        for (final p in GameConfig.outerRingPieces) {
          list.add(PieceModel(
            id: id++,
            type: (p['isWhite'] as bool) ? PieceType.white : PieceType.black,
            position: p['pos'] as Vector2,
            radius: GameConfig.pieceRadius,
            mass: GameConfig.pieceMass,
          ));
        }
        return list;
      }

      final pieces = createFullBoard();
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final ai = CarromAI(difficulty: AiDifficulty.hard);

      // Warmup
      ai.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      final stopwatch = Stopwatch()..start();
      const int runs = 25;
      for (int i = 0; i < runs; i++) {
        ai.calculateShot(
          pieces: pieces,
          striker: striker,
          aiColor: PlayerColor.black,
          needsQueenCover: false,
          queenCovered: false,
        );
      }
      stopwatch.stop();

      final double avgMs = stopwatch.elapsedMicroseconds / (runs * 1000.0);
      expect(avgMs, lessThan(10.0), reason: 'AI decision time must be under 10ms per frame');
    });
  });
}

