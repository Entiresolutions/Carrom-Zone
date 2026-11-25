import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/ai/carrom_ai.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';

void main() {
  group('Striker Movement Boundaries Tests (Carrom Rules)', () {
    test('Striker can move up to on top of the red circle but not outside it', () {
      // The two red positioning circles on the baseline are centered at ±baselineHalfWidth
      const double redCircleCenter = GameConfig.baselineHalfWidth; // 85.0
      expect(redCircleCenter, equals(85.0));

      // According to Carrom rules, striker can be placed within baseline or on top of the red circles,
      // but must NOT go outside/beyond the red circles.
      expect(GameConfig.strikerMinX, equals(-redCircleCenter)); // -85.0
      expect(GameConfig.strikerMaxX, equals(redCircleCenter));  // 85.0

      // Striker radius covers the red circle when centered on it
      expect(GameConfig.strikerRadius, greaterThanOrEqualTo(13.5)); // 16.0 >= 13.5
    });

    test('Striker stays strictly within valid board cushion boundaries', () {
      const double halfPlay = GameConfig.halfBoard - 16.0; // 184.0 (inner cushion wall)
      const double strikerR = GameConfig.strikerRadius; // 16.0

      // At right red circle position (85.0), striker outer edge is 101.0, safely inside cushion
      final double maxRightEdge = GameConfig.strikerMaxX + strikerR;
      expect(maxRightEdge, lessThanOrEqualTo(halfPlay));
      expect(halfPlay - maxRightEdge, greaterThanOrEqualTo(80.0));

      // At left red circle position (-85.0), striker outer edge is -101.0, safely inside cushion
      final double maxLeftEdge = GameConfig.strikerMinX - strikerR;
      expect(maxLeftEdge, greaterThanOrEqualTo(-halfPlay));
      expect(-halfPlay - maxLeftEdge, lessThanOrEqualTo(-80.0));
    });

    test('Striker never overlaps any corner pockets at any baseline position', () {
      const double strikerR = GameConfig.strikerRadius; // 16.0
      const double pocketR = GameConfig.pocketRadius; // 19.0
      const double pocketTrimR = pocketR + 6.5; // 25.5 (outermost visual trim)
      const double minClearance = strikerR + pocketTrimR; // 41.5

      final double baselineY = GameConfig.baselineYWhite; // 142.0

      // Test across the legal baseline range from -85.0 to 85.0
      for (double x = GameConfig.strikerMinX;
          x <= GameConfig.strikerMaxX;
          x += 1.0) {
        final pos = Vector2(x, baselineY);

        for (final pocket in GameConfig.pockets) {
          final double distance = pos.distanceTo(pocket);
          expect(distance, greaterThan(minClearance),
              reason: 'Striker at $pos overlaps pocket at $pocket (distance: $distance <= $minClearance)');
        }

        expect(GameConfig.isStrikerPositionWithinBounds(pos), isTrue);
      }
    });

    test('GameConfig.isStrikerPositionWithinBounds correctly enforces the red circle boundary', () {
      const double y = GameConfig.baselineYWhite;

      // Valid positions: anywhere along baseline and right on top of red circles
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(0.0, y)), isTrue);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(50.0, y)), isTrue);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(-50.0, y)), isTrue);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(85.0, y)), isTrue); // On top of right red circle
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(-85.0, y)), isTrue); // On top of left red circle

      // Invalid positions: outside/beyond the red circles
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(86.0, y)), isFalse); // Outside right red circle
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(-86.0, y)), isFalse); // Outside left red circle
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(100.0, y)), isFalse);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(-100.0, y)), isFalse);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(130.0, y)), isFalse);
      expect(GameConfig.isStrikerPositionWithinBounds(Vector2(178.0, 178.0)), isFalse);
    });

    test('CarromAI calculates shots within the red circle baseline boundaries', () {
      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final List<PieceModel> pieces = [
        PieceModel(
          id: 1,
          type: PieceType.black,
          position: Vector2(30.0, 0.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];

      final shot = ai.calculateShot(
        pieces: pieces,
        striker: PieceModel(
          id: 0,
          type: PieceType.striker,
          position: Vector2(0, GameConfig.baselineYBlack),
          radius: GameConfig.strikerRadius,
          mass: GameConfig.strikerMass,
        ),
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      expect(shot, isNotNull);
      expect(shot.strikerX, greaterThanOrEqualTo(GameConfig.strikerMinX - 0.1));
      expect(shot.strikerX, lessThanOrEqualTo(GameConfig.strikerMaxX + 0.1));
    });
  });
}
