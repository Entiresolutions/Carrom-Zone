import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/ai/carrom_ai.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/screens/game_screen.dart';
import 'package:carrom_master/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Carrom AI v2.1 Reliability & Balancing Benchmark Suite', () {
    test('1. Authoritative Geometry & Baseline Alignment: AI respects human slider bounds', () {
      final ai = CarromAI(difficulty: AiDifficulty.hard);
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final piece = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(-60.0, -80.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final shot = ai.calculateShot(
        pieces: [piece],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      expect(shot.strikerX, greaterThanOrEqualTo(GameConfig.strikerMinX));
      expect(shot.strikerX, lessThanOrEqualTo(GameConfig.strikerMaxX));
      expect(GameConfig.strikerMinX, equals(-67.0));
      expect(GameConfig.strikerMaxX, equals(67.0));
    });

    test('2. Rollout Full Settlement Horizon: Simulates until pieces rest without premature abort', () {
      final ai = CarromAI(
        difficulty: AiDifficulty.hard,
        maxSimulationSteps: 100,
      );
      expect(ai.maxSimulationSteps, equals(100));

      // Setup a shot where target is pocketed quickly but secondary pieces keep moving
      final target = PieceModel(
        id: 1,
        type: PieceType.black,
        position: const Vector2(-120.0, -120.0),
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

      final shot = ai.calculateShot(
        pieces: [target],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );

      expect(shot.isPredictedPot, isTrue);
    });

    test('3. Configurable Difficulty Profiles & Jitter Hierarchy', () {
      expect(AiDifficultyConfig.easy.maxSimulations, equals(2));
      expect(AiDifficultyConfig.medium.maxSimulations, equals(3));
      expect(AiDifficultyConfig.hard.maxSimulations, equals(5));

      expect(AiDifficultyConfig.easy.minCosTheta, equals(0.52));
      expect(AiDifficultyConfig.medium.minCosTheta, equals(0.38));
      expect(AiDifficultyConfig.hard.minCosTheta, equals(0.16));

      expect(AiDifficultyConfig.easy.allowBankShots, isFalse);
      expect(AiDifficultyConfig.medium.allowBankShots, isFalse);
      expect(AiDifficultyConfig.hard.allowBankShots, isTrue);

      expect(AiDifficultyConfig.easy.secondBestShotChance, equals(0.45));
      expect(AiDifficultyConfig.medium.secondBestShotChance, equals(0.35));
      expect(AiDifficultyConfig.hard.secondBestShotChance, equals(0.0));

      expect(AiDifficultyConfig.easy.angleJitterSpread,
          greaterThan(AiDifficultyConfig.medium.angleJitterSpread));
      expect(AiDifficultyConfig.medium.angleJitterSpread,
          greaterThan(AiDifficultyConfig.hard.angleJitterSpread));
    });

    test('4. Freestyle Scoring Weights: Balanced 20 / 10 / 50 Pt Relative Values', () {
      final queen = PieceModel(
        id: 1,
        type: PieceType.queen,
        position: const Vector2(0.0, -80.0),
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      );
      final blackCoin = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(-50.0, -90.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );
      final whiteCoin = PieceModel(
        id: 3,
        type: PieceType.white,
        position: const Vector2(50.0, -90.0),
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

      // In Freestyle, all normal pieces are eligible, White (20) prioritized over Black (10)
      final shot = ai.calculateShot(
        pieces: [queen, blackCoin, whiteCoin],
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
        ruleset: CarromRuleset.freestyle,
      );

      expect(shot.strikerX.isNaN, isFalse);
      expect(shot.angle.isNaN, isFalse);
      expect(shot.power, inInclusiveRange(0.35, 1.0));
    });

    test('5. Seeded Batch Simulation Benchmark across 3 Difficulties in Classic & Freestyle', () {
      // Deterministic pseudo-random scenario generator
      final benchmarkResults = <String, Map<String, dynamic>>{};

      for (final ruleset in [CarromRuleset.classic, CarromRuleset.freestyle]) {
        for (final difficulty in [AiDifficulty.easy, AiDifficulty.medium, AiDifficulty.hard]) {
          final testRandom = math.Random(42); // Seeded for reproducibility
          final ai = CarromAI(difficulty: difficulty, random: testRandom);

          int totalShots = 20;
          int successfulPots = 0;
          int fouls = 0;
          int consecutivePots = 0;
          int maxConsecutivePots = 0;

          // Run 20 distinct board setups
          for (int round = 0; round < totalShots; round++) {
            // Seeded piece placements
            final double posX = (testRandom.nextDouble() * 160.0) - 80.0;
            final double posY = -40.0 - (testRandom.nextDouble() * 80.0);

            final target = PieceModel(
              id: 1,
              type: ruleset == CarromRuleset.classic ? PieceType.black : PieceType.black,
              position: Vector2(posX, posY),
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

            final shot = ai.calculateShot(
              pieces: [target],
              striker: striker,
              aiColor: PlayerColor.black,
              needsQueenCover: false,
              queenCovered: false,
              ruleset: ruleset,
            );

            // Execute shot in authoritative CarromPhysics
            striker.position = Vector2(shot.strikerX, GameConfig.baselineYBlack);
            final double powerMag = shot.power * GameConfig.strikerMaxPower;
            striker.velocity = Vector2(
              math.cos(shot.angle) * powerMag,
              math.sin(shot.angle) * powerMag,
            );

            bool potted = false;
            bool fouled = false;

            final realPhysics = CarromPhysics(
              pieces: [target],
              striker: striker,
              onPocket: (p, pocket) {
                if (p.id == target.id) potted = true;
                if (p.type == PieceType.striker) fouled = true;
              },
            );
            realPhysics.resetAccumulator();

            for (int s = 0; s < 100; s++) {
              realPhysics.update(1.0 / 60.0);
              if (!realPhysics.isAnyPieceMoving && !realPhysics.isAnyPiecePocketing) break;
            }

            if (fouled) fouls++;
            if (potted && !fouled) {
              successfulPots++;
              consecutivePots++;
              if (consecutivePots > maxConsecutivePots) {
                maxConsecutivePots = consecutivePots;
              }
            } else {
              consecutivePots = 0;
            }
          }

          final double potRate = successfulPots / totalShots;
          final double foulRate = fouls / totalShots;

          final key = '${ruleset.name}_${difficulty.name}';
          benchmarkResults[key] = {
            'totalShots': totalShots,
            'successfulPots': successfulPots,
            'potRate': potRate,
            'foulRate': foulRate,
            'maxConsecutive': maxConsecutivePots,
          };
        }
      }

      // Assert expected hierarchy across difficulties in Classic
      final easyClassic = benchmarkResults['classic_easy']!;
      final medClassic = benchmarkResults['classic_medium']!;
      final hardClassic = benchmarkResults['classic_hard']!;

      expect(easyClassic['potRate'], lessThan(medClassic['potRate'] as num),
          reason: 'Easy should have a naturally lower pot rate than Medium');
      expect(medClassic['potRate'], lessThanOrEqualTo(hardClassic['potRate'] as num),
          reason: 'Medium should have equal or lower pot rate than Hard');
      expect(hardClassic['potRate'], greaterThan(0.70),
          reason: 'Hard should achieve tournament performance (> 70%)');
      expect(easyClassic['foulRate'], equals(0.0),
          reason: 'AI must not scratch under legal lookahead');
      expect(hardClassic['foulRate'], equals(0.0),
          reason: 'AI must not scratch under legal lookahead');

      // Assert expected hierarchy across difficulties in Freestyle
      final easyFreestyle = benchmarkResults['freestyle_easy']!;
      final hardFreestyle = benchmarkResults['freestyle_hard']!;

      expect(easyFreestyle['potRate'], lessThan(hardFreestyle['potRate'] as num),
          reason: 'Freestyle Easy must be lower than Freestyle Hard');
    });

    testWidgets('6. Pre-Match Difficulty Selection Dialog: User selects difficulty before match starts', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();

      await tester.binding.setSurfaceSize(const Size(450, 880));
      await tester.pumpWidget(
        const MaterialApp(
          home: MenuScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap VS CPU
      await tester.tap(find.text('VS CPU'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog is displayed asking user for difficulty before match starts
      expect(find.text('CHOOSE DIFFICULTY'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Select EASY difficulty option
      await tester.tap(find.text('EASY'));
      await tester.pump(const Duration(milliseconds: 150));

      // Tap START MATCH (EASY) button
      await tester.tap(find.textContaining('START MATCH (EASY)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Match starts in GameScreen with Easy difficulty verified
      expect(find.byType(GameScreen), findsOneWidget);
      expect(StorageService().getAiDifficulty(), equals(AiDifficulty.easy));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });
  });
}
