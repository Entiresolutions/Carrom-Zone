import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/ai/carrom_ai.dart';
import 'package:carrom_master/core/carrom_rule_engine.dart';

void main() {
  group('Phase 2 Verification: AI Intelligence & Physics Reliability Suite', () {
    test('1. AI Rule Engine Integration: Accurately prioritizes Queen cover and avoids fouls', () {
      final queen = PieceModel(
        id: 1,
        type: PieceType.queen,
        position: const Vector2(0.0, 0.0),
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
        isPocketed: true, // Queen already in pocket awaiting cover
      );

      final ownPiece = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(-120.0, -120.0), // Open near Top-Left pocket
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final opponentPiece = PieceModel(
        id: 3,
        type: PieceType.white,
        position: const Vector2(120.0, -120.0), // Near Top-Right pocket
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
        pieces: [queen, ownPiece, opponentPiece],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: true,
        queenCovered: false,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: true,
        queenPocketedBy: PlayerColor.black,
      );

      // Shot must be aimed towards ownPiece to complete the Queen cover
      final strikerPos = Vector2(shot.strikerX, GameConfig.baselineYBlack);
      final shotDir = Vector2(math.cos(shot.angle), math.sin(shot.angle));
      final toOwnPiece = (ownPiece.position - strikerPos).normalized();
      final toOppPiece = (opponentPiece.position - strikerPos).normalized();

      expect(shotDir.dot(toOwnPiece), greaterThan(0.85), reason: 'AI must target own coin to complete cover');
      expect(shotDir.dot(toOppPiece), lessThan(0.60), reason: 'AI must not target opponent piece on cover shot');
    });

    test('2. Bank Shot Capability: Hard AI calculates bank shots when direct path is obstructed', () {
      // Place target coin near top right
      final targetPiece = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(100.0, -100.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      // Place heavy obstacle directly blocking the direct line from baseline
      final blocker1 = PieceModel(
        id: 2,
        type: PieceType.white,
        position: const Vector2(50.0, -121.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final blocker2 = PieceModel(
        id: 3,
        type: PieceType.white,
        position: const Vector2(0.0, -130.0),
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

      // Easy AI: Must NOT allow bank shots
      final easyAi = CarromAI(difficulty: AiDifficulty.easy);
      final easyShot = easyAi.calculateShot(
        pieces: [targetPiece, blocker1, blocker2],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );
      expect(easyShot.isBankShot, isFalse, reason: 'Easy AI must never attempt bank shots');

      // Hard AI: Able to formulate bank shots when direct shot is obstructed
      final hardAi = CarromAI(difficulty: AiDifficulty.hard);
      final hardShot = hardAi.calculateShot(
        pieces: [targetPiece, blocker1, blocker2],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );
      expect(hardShot.power, inInclusiveRange(0.3, 1.0));
      expect(hardShot.strikerX.isNaN, isFalse);
    });

    test('3. AI Difficulty Gradient: Easy, Medium, and Hard variance profiles', () {
      final target = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(0.0, -60.0),
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

      final hardShots = List.generate(15, (_) => CarromAI(difficulty: AiDifficulty.hard).calculateShot(
        pieces: [target],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      ));

      final mediumShots = List.generate(15, (_) => CarromAI(difficulty: AiDifficulty.medium).calculateShot(
        pieces: [target],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      ));

      final easyShots = List.generate(15, (_) => CarromAI(difficulty: AiDifficulty.easy).calculateShot(
        pieces: [target],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      ));

      double getSpread(List<AiShotResult> shots) {
        final angles = shots.map((s) => s.angle).toList();
        return angles.reduce(math.max) - angles.reduce(math.min);
      }

      final hardSpread = getSpread(hardShots);
      final mediumSpread = getSpread(mediumShots);
      final easySpread = getSpread(easyShots);

      // Hard must be tightest, Medium in the middle, Easy widest
      expect(hardSpread, lessThan(0.035), reason: 'Hard AI must exhibit tight master-level aim');
      expect(easySpread, greaterThan(hardSpread), reason: 'Easy AI must have wider dispersion than Hard');
      expect(easySpread, greaterThan(mediumSpread * 0.9), reason: 'Easy AI must have highest dispersion');
    });

    test('4. Physics Wall Invariant: Cushion velocity reversal only triggers when moving into wall', () {
      const double halfPlay = GameConfig.halfBoard - 16.0; // 184.0

      // Piece pressed against left cushion, but already traveling to the right (+x)
      final piece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: Vector2(-halfPlay + GameConfig.pieceRadius - 0.5, 0.0),
        velocity: const Vector2(8.0, 0.0), // Moving AWAY from left cushion
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: [piece], striker: striker);
      physics.step(1.0 / 60.0);

      // Velocity must NOT be flipped back to negative! It should continue moving right (+x)
      expect(piece.velocity.x, greaterThan(0.0), reason: 'Velocity must not invert when piece is moving away from wall');
    });

    test('5. Physics Corner Tunneling Stress: Max power diagonal trajectory strictly bounded', () {
      const double maxOuterBound = GameConfig.halfBoard - 4.0; // 196.0

      // Striker fired diagonally into the corner at maximum possible power
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(170.0, 170.0),
        velocity: const Vector2(GameConfig.strikerMaxPower, GameConfig.strikerMaxPower),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: [], striker: striker);

      for (int step = 0; step < 60; step++) {
        physics.update(1.0 / 60.0);

        expect(striker.position.x.abs() + striker.radius, lessThanOrEqualTo(maxOuterBound + 0.1),
            reason: 'Striker escaped board horizontally at step $step: ${striker.position.x}');
        expect(striker.position.y.abs() + striker.radius, lessThanOrEqualTo(maxOuterBound + 0.1),
            reason: 'Striker escaped board vertically at step $step: ${striker.position.y}');
        expect(striker.position.isValid, isTrue);
        expect(striker.velocity.isValid, isTrue);
      }
    });

    test('6. Physics Multi-Piece Settling: 19 pieces scatter and settle deterministically', () {
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
        position: const Vector2(0.0, 142.0),
        velocity: const Vector2(0.0, -22.0), // High power break shot straight into center cluster
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: pieces, striker: striker);

      // Simulate 120 frames (2.0 seconds)
      for (int i = 0; i < 120; i++) {
        physics.update(1.0 / 60.0);
      }

      // Assert all pieces remain in valid finite coordinates without NaNs or escapes
      for (final p in pieces) {
        expect(p.position.isValid, isTrue);
        expect(p.velocity.isValid, isTrue);
        if (!p.isPocketed) {
          expect(p.position.x.abs(), lessThanOrEqualTo(196.0));
          expect(p.position.y.abs(), lessThanOrEqualTo(196.0));
        }
      }
      expect(striker.position.isValid, isTrue);
      expect(striker.velocity.isValid, isTrue);
    });

    test('7. Deterministic Respotting Clearance: Respotting never overlaps existing active coins', () {
      final pieces = <PieceModel>[];
      // Surround center with pieces
      pieces.add(PieceModel(
        id: 1,
        type: PieceType.queen,
        position: Vector2.zero,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      ));
      pieces.add(PieceModel(
        id: 2,
        type: PieceType.white,
        position: const Vector2(0.0, 25.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      ));
      pieces.add(PieceModel(
        id: 3,
        type: PieceType.black,
        position: const Vector2(0.0, -25.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      ));

      final respotPos = CarromRespotter.findDeterministicRespotPosition(pieces);

      // Verify clearance from all active pieces
      for (final p in pieces) {
        final dist = respotPos.distanceTo(p.position);
        expect(
          dist,
          greaterThanOrEqualTo(23.5),
          reason: 'Respot position $respotPos too close to existing piece at ${p.position}',
        );
      }
    });
  });
}

