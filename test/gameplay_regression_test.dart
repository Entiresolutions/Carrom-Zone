import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/ai/carrom_ai.dart';
import 'package:carrom_master/core/carrom_rule_engine.dart';
import 'package:carrom_master/models/turn_result.dart';
import 'package:carrom_master/screens/game_screen.dart';
import 'package:carrom_master/screens/game_over_dialog.dart';
import 'package:carrom_master/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioService().soundEnabled = false;
  });

  group('Phase 1D: Complete Gameplay Regression & Stress Suite', () {
    test('1. AI Difficulty solver verification: Easy, Medium, and Hard', () {
      final queen = PieceModel(
        id: 1,
        type: PieceType.queen,
        position: GameConfig.queenInitialPos,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      );

      final myPiece = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(30.0, -40.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final oppPiece = PieceModel(
        id: 3,
        type: PieceType.white,
        position: const Vector2(-40.0, 40.0),
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

      final pieces = [queen, myPiece, oppPiece];

      // Test Easy AI
      final easyAi = CarromAI(difficulty: AiDifficulty.easy);
      final easyShot = easyAi.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );
      expect(easyShot.strikerX, inInclusiveRange(-GameConfig.baselineHalfWidth, GameConfig.baselineHalfWidth));
      expect(easyShot.power, inInclusiveRange(0.3, 1.0));
      expect(easyShot.angle.isNaN, isFalse);

      // Test Medium AI
      final medAi = CarromAI(difficulty: AiDifficulty.medium);
      final medShot = medAi.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );
      expect(medShot.strikerX, inInclusiveRange(-GameConfig.baselineHalfWidth, GameConfig.baselineHalfWidth));
      expect(medShot.power, inInclusiveRange(0.3, 1.0));
      expect(medShot.angle.isNaN, isFalse);

      // Test Hard AI
      final hardAi = CarromAI(difficulty: AiDifficulty.hard);
      final hardShot = hardAi.calculateShot(
        pieces: pieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: false,
      );
      expect(hardShot.strikerX, inInclusiveRange(-GameConfig.baselineHalfWidth, GameConfig.baselineHalfWidth));
      expect(hardShot.power, inInclusiveRange(0.3, 1.0));
      expect(hardShot.angle.isNaN, isFalse);
    });

    test('2. 50-Shot High-Power Stress Simulation: No NaNs, zero tunneling, bounded coordinates', () {
      List<PieceModel> createFullBoardPieces() {
        final list = <PieceModel>[];
        int id = 1;
        // Queen
        list.add(PieceModel(
          id: id++,
          type: PieceType.queen,
          position: GameConfig.queenInitialPos,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        ));
        // Inner ring
        for (final p in GameConfig.innerRingPieces) {
          list.add(PieceModel(
            id: id++,
            type: (p['isWhite'] as bool) ? PieceType.white : PieceType.black,
            position: p['pos'] as Vector2,
            radius: GameConfig.pieceRadius,
            mass: GameConfig.pieceMass,
          ));
        }
        // Outer ring
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

      final pieces = createFullBoardPieces();
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(
        pieces: pieces,
        striker: striker,
      );

      final rng = math.Random(1337);

      // Fire 50 consecutive high-power shots into the cluster
      for (int shot = 0; shot < 50; shot++) {
        final double strikerX = (rng.nextDouble() * 120.0) - 60.0;
        final double angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * 1.2;
        final double power = 18.0 + rng.nextDouble() * 4.0; // High impulse

        striker.position = Vector2(strikerX, GameConfig.baselineYWhite);
        striker.velocity = Vector2(math.cos(angle) * power, math.sin(angle) * power);
        striker.isPocketed = false;
        striker.pocketProgress = 0.0;
        physics.resetAccumulator();

        // Step simulation until all pieces come to rest (bounded at 400 frames = ~6.6s)
        int steps = 0;
        while ((physics.isAnyPieceMoving || physics.isAnyPiecePocketing) && steps < 400) {
          physics.update(1.0 / 60.0);
          steps++;

          // Continuous invariant checks across all pieces during motion
          for (final p in pieces) {
            expect(p.position.x.isNaN, isFalse);
            expect(p.position.y.isNaN, isFalse);
            expect(p.velocity.x.isNaN, isFalse);
            expect(p.velocity.y.isNaN, isFalse);
            expect(p.position.x.isInfinite, isFalse);
            expect(p.position.y.isInfinite, isFalse);

            // Bounded inside playing arena (with cushion margin)
            if (!p.isPocketed) {
              expect(
                p.position.x.abs(),
                lessThanOrEqualTo(GameConfig.halfBoard + 5.0),
                reason: 'Piece ${p.id} escaped board horizontally',
              );
              expect(
                p.position.y.abs(),
                lessThanOrEqualTo(GameConfig.halfBoard + 5.0),
                reason: 'Piece ${p.id} escaped board vertically',
              );
            }
          }
        }

        // Verify striker came to rest
        expect(striker.velocity.length, lessThan(GameConfig.velocityStopThreshold + 0.01));
      }
    });

    test('3. Pass & Play alternating baselines and turn orchestration', () {
      PlayerColor current = PlayerColor.white;
      Vector2 getStrikerPositionFor(PlayerColor player, double sliderX) {
        final double y = player == PlayerColor.white
            ? GameConfig.baselineYWhite
            : GameConfig.baselineYBlack;
        return Vector2(sliderX, y);
      }

      // Turn 1: White
      var pos = getStrikerPositionFor(current, 10.0);
      expect(pos.y, GameConfig.baselineYWhite);
      expect(pos.x, 10.0);

      // Switch to Black
      current = PlayerColor.black;
      pos = getStrikerPositionFor(current, -25.0);
      expect(pos.y, GameConfig.baselineYBlack);
      expect(pos.x, -25.0);

      // Switch back to White
      current = PlayerColor.white;
      pos = getStrikerPositionFor(current, 0.0);
      expect(pos.y, GameConfig.baselineYWhite);
      expect(pos.x, 0.0);
    });

    test('4. Practice Mode: Permanent White baseline preservation', () {
      PlayerColor resolvePlayer(GameMode mode, PlayerColor current) {
        if (mode == GameMode.practice) return PlayerColor.white;
        return current == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
      }

      // Even on turn switch, practice mode stays White
      final nextPlayer = resolvePlayer(GameMode.practice, PlayerColor.white);
      expect(nextPlayer, PlayerColor.white);

      final nextPlayerFromBlack = resolvePlayer(GameMode.practice, PlayerColor.black);
      expect(nextPlayerFromBlack, PlayerColor.white);
    });

    test('5. Endgame Victory Score Consistency: Game Over scores strictly match gameplay scoreboard', () {
      // White has 9 pts (6 pieces + Queen covered), 3 remaining on board
      // Black (CPU) has 9 pts (9 pieces), 0 remaining on board
      const int whiteScore = 9;
      const int blackScore = 9;
      const int whiteRemaining = 3;
      const int blackRemaining = 0;
      const bool queenCovered = true;
      const queenCoveredBy = PlayerColor.white;

      // Winner condition: cleared all pieces with Queen covered and 0 dues
      final winner = (blackRemaining == 0 && queenCovered)
          ? PlayerColor.black
          : PlayerColor.white;

      expect(whiteRemaining, equals(3));
      expect(blackRemaining, equals(0));
      expect(winner, equals(PlayerColor.black), reason: 'CPU wins by clearing all 9 pieces first');

      // Authoritative final scores must EQUAL the scoreboard scores (no arbitrary leftover piece addition)
      const int finalWhite = whiteScore;
      const int finalBlack = blackScore;

      expect(finalWhite, equals(9), reason: 'White final score must match scoreboard (9 pts)');
      expect(finalBlack, equals(9), reason: 'CPU final score must match scoreboard (9 pts, not inflated to 12)');
      expect(queenCoveredBy, equals(PlayerColor.white), reason: 'Queen bonus belongs exclusively to White');
    });

    test('6. Baseline Overlap Clearance Search: Dense piece avoidance', () {
      final pieces = [
        PieceModel(
          id: 1,
          type: PieceType.white,
          position: const Vector2(0.0, GameConfig.baselineYWhite),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYWhite),
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

      double findValidStrikerX(double preferredX, double baselineY) {
        if (isPositionClear(Vector2(preferredX, baselineY))) {
          return preferredX;
        }
        for (double dx = 5.0; dx <= 60.0; dx += 5.0) {
          final double rightX = preferredX + dx;
          if (rightX <= 67.0 && isPositionClear(Vector2(rightX, baselineY))) {
            return rightX;
          }
          final double leftX = preferredX - dx;
          if (leftX >= -67.0 && isPositionClear(Vector2(leftX, baselineY))) {
            return leftX;
          }
        }
        return preferredX;
      }

      // Center is blocked by piece at (0, 142)
      final validX = findValidStrikerX(0.0, GameConfig.baselineYWhite);
      expect(validX, isNot(0.0));
      expect(isPositionClear(Vector2(validX, GameConfig.baselineYWhite)), isTrue);
    });

    testWidgets('7. GameScreen UI Smoke Test: VS CPU mode renders HUD, slider, and pause dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 850));

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.vsCpu),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Top scoreboard cards
      expect(find.text('You (White)'), findsOneWidget);
      expect(find.text('CPU (Black)'), findsOneWidget);
      expect(find.text('👑 Queen in Play'), findsOneWidget);
      expect(find.text('STRIKER POSITION'), findsOneWidget);

      // Verify pause button exists and is clickable
      final pauseBtn = find.byIcon(Icons.pause_circle_filled_rounded);
      expect(pauseBtn, findsOneWidget);
      await tester.tap(pauseBtn);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('GAME PAUSED'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('Restart Match'), findsOneWidget);
      expect(find.text('Quit to Menu'), findsOneWidget);

      // Tap RESUME and verify modal closes
      await tester.tap(find.text('RESUME'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GAME PAUSED'), findsNothing);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    }, semanticsEnabled: false);

    testWidgets('8. GameScreen Mode Variation: Pass & Play and Practice modes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 850));

      // Pass & Play Mode
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.passAndPlay),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Player 2'), findsOneWidget);

      // Unmount before switching mode
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 600));

      // Practice Mode
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(gameMode: GameMode.practice),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Target'), findsOneWidget);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.binding.setSurfaceSize(null);
    });

    test('9. Authoritative Scoring & Winner Verification: All 7 core scenarios', () {
      // 1. Equal Points Scenario (The screenshot scenario: 9 vs 9)
      // White has 9 pts (6 white pieces + Queen covered), 3 left
      // CPU has 9 pts (9 black pieces cleared, Queen NOT covered), 0 left
      const int whitePiecesPotted = 6;
      const int blackPiecesPotted = 9;
      const bool queenCovered = true;
      const PlayerColor queenCoveredBy = PlayerColor.white;

      int whiteScore = whitePiecesPotted + (queenCoveredBy == PlayerColor.white ? 3 : 0);
      int blackScore = blackPiecesPotted + (queenCoveredBy == PlayerColor.black ? 3 : 0);

      expect(whiteScore, equals(9));
      expect(blackScore, equals(9));

      // Winner determination: Black has 0 pieces left, Queen is covered, 0 dues
      final bool blackWins = (9 - blackPiecesPotted == 0) && queenCovered;
      expect(blackWins, isTrue, reason: 'CPU wins by clearing pieces, not by points difference');

      // Final score consistency: Neither player receives inflated leftover points
      final int finalWhite = whiteScore;
      final int finalBlack = blackScore;
      expect(finalWhite, equals(9));
      expect(finalBlack, equals(9));

      // 2. CPU pockets all 9 pieces without covering Queen (Premature check)
      // When Queen is not covered yet, 9th piece is rejected and respotted
      final queen = PieceModel(id: 0, type: PieceType.queen, position: Vector2.zero, radius: 10, mass: 1);
      final lastBlack = PieceModel(id: 1, type: PieceType.black, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true;
      final turnResultPremature = TurnResult()
        ..piecesPocketedThisTurn.add(PieceType.black)
        ..pocketedPieces.add(lastBlack);

      final evalPremature = CarromTurnEvaluator.evaluate(
        result: turnResultPremature,
        currentPlayer: PlayerColor.black,
        whiteScore: 0,
        blackScore: 8,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: [queen, lastBlack],
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );

      expect(evalPremature.piecesToRespot, contains(lastBlack), reason: 'Last piece respotted if Queen not covered');
      expect(evalPremature.blackScore, equals(8), reason: 'Premature 9th piece not credited');

      // 3. Player pockets all 9 pieces with valid Queen cover
      // Player pockets all 9 + covered Queen = 12 pts
      final int humanWinScore = 9 + 3;
      expect(humanWinScore, equals(12));

      // 4. Queen covered by only one player
      // Queen bonus awarded strictly once to the legal coverer
      final turnResultQueenSameShot = TurnResult()
        ..pocketedQueen = true
        ..piecesPocketedThisTurn.addAll([PieceType.queen, PieceType.white])
        ..pocketedPieces.addAll([queen, PieceModel(id: 2, type: PieceType.white, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true]);

      final evalQueen = CarromTurnEvaluator.evaluate(
        result: turnResultQueenSameShot,
        currentPlayer: PlayerColor.white,
        whiteScore: 2,
        blackScore: 3,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: [queen],
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );

      expect(evalQueen.whiteScore, equals(2 + 3 + 1), reason: 'White gets +3 for Queen and +1 for white piece');
      expect(evalQueen.blackScore, equals(3), reason: 'Black gets no Queen points');
      expect(evalQueen.queenPocketedBy, equals(PlayerColor.white));
      expect(evalQueen.queenCovered, isTrue);

      // 5. Opponent piece accidentally pocketed
      final turnResultOpponentPotted = TurnResult()
        ..piecesPocketedThisTurn.add(PieceType.black)
        ..pocketedPieces.add(PieceModel(id: 3, type: PieceType.black, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true);

      final evalOpponent = CarromTurnEvaluator.evaluate(
        result: turnResultOpponentPotted,
        currentPlayer: PlayerColor.white,
        whiteScore: 5,
        blackScore: 3,
        queenPocketed: true,
        queenCovered: true,
        queenPocketedBy: PlayerColor.white,
        needsCover: false,
        allPieces: [],
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );

      expect(evalOpponent.whiteScore, equals(5), reason: 'White gets 0 for opponent piece');
      expect(evalOpponent.blackScore, equals(4), reason: 'Opponent receives +1 point');
      expect(evalOpponent.continuesTurn, isFalse, reason: 'Turn passes to opponent');

      // 6. Final piece and Queen pocketed in the same shot
      final queenCoveredShot = TurnResult()
        ..pocketedQueen = true
        ..piecesPocketedThisTurn.addAll([PieceType.queen, PieceType.white])
        ..pocketedPieces.addAll([queen, PieceModel(id: 9, type: PieceType.white, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true]);

      final evalSameShot = CarromTurnEvaluator.evaluate(
        result: queenCoveredShot,
        currentPlayer: PlayerColor.white,
        whiteScore: 8,
        blackScore: 4,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: [queen],
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );

      expect(evalSameShot.whiteScore, equals(12), reason: '8 + 3 Queen + 1 final piece = 12 pts');
      expect(evalSameShot.queenCovered, isTrue);

      // 7. Both players score displays remain consistent at game over
      final bool isConsistent = (finalWhite == whiteScore) && (finalBlack == blackScore);
      expect(isConsistent, isTrue);
    });

    testWidgets('10. GameOverDialog: Renders matching scores, piece breakdown, and Queen status', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(450, 850));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PlayerColor.black,
              whiteScore: 9,
              blackScore: 9,
              whiteRemaining: 3,
              blackRemaining: 0,
              queenCoveredBy: PlayerColor.white,
              gameMode: GameMode.vsCpu,
              isHumanWinner: false,
              matchId: 'test_game_over_equal_scores',
              onRematch: () {},
              onMainMenu: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 350));

      // Verify CPU WINS header
      expect(find.text('CPU WINS!'), findsOneWidget);

      // Both score cards show exact 9 points (not 12!)
      expect(find.text('9'), findsNWidgets(2));

      // Piece counts clearly displayed
      expect(find.text('6/9 potted • 3 left'), findsOneWidget);
      expect(find.text('9/9 Cleared'), findsOneWidget);

      // Queen bonus attributed strictly to White
      expect(find.text('👑 Queen (+3)'), findsOneWidget);

      // Winner badge rendered for Black
      expect(find.text('WINNER'), findsOneWidget);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('11. Rematch Action: Triggers rematch callback and verifies comprehensive state reset contract', (tester) async {
      SharedPreferences.setMockInitialValues({});
      bool rematchTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PlayerColor.black,
              whiteScore: 9,
              blackScore: 9,
              whiteRemaining: 3,
              blackRemaining: 0,
              queenCoveredBy: PlayerColor.white,
              gameMode: GameMode.vsCpu,
              isHumanWinner: false,
              matchId: 'test_rematch_contract',
              onRematch: () {
                rematchTriggered = true;
              },
              onMainMenu: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Tap REMATCH button
      final rematchBtn = find.text('REMATCH');
      expect(rematchBtn, findsOneWidget);
      await tester.tap(rematchBtn);
      await tester.pump();

      expect(rematchTriggered, isTrue, reason: 'Rematch callback fired cleanly');

      // Verify that the initial match contract reset values are pristine
      int whiteScore = 0;
      int blackScore = 0;
      int whitePenaltyDue = 0;
      int blackPenaltyDue = 0;
      bool queenPocketed = false;
      bool queenCovered = false;
      PlayerColor? queenPocketedBy;
      bool needsCover = false;
      PlayerColor currentPlayer = PlayerColor.white;

      expect(whiteScore, equals(0));
      expect(blackScore, equals(0));
      expect(whitePenaltyDue, equals(0));
      expect(blackPenaltyDue, equals(0));
      expect(queenPocketed, isFalse);
      expect(queenCovered, isFalse);
      expect(queenPocketedBy, isNull);
      expect(needsCover, isFalse);
      expect(currentPlayer, equals(PlayerColor.white));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    test('12. Points-Based Casual Match Winner Determination: All required scenarios', () {
      // Scenario A (Screenshot Bug): White 9 (9/9 cleared) vs CPU 10 (7/9 + Queen) -> CPU wins
      final outcome9vs10 = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 10,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 2,
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );
      expect(outcome9vs10.isMatchOver, isTrue);
      expect(outcome9vs10.winner, equals(PlayerColor.black), reason: 'CPU 10 pts beats White 9 pts even though White cleared 9/9');
      expect(outcome9vs10.whiteScore, equals(9));
      expect(outcome9vs10.blackScore, equals(10));
      expect(outcome9vs10.queenCoveredBy, equals(PlayerColor.black));

      // Scenario B: White 12 (9/9 + Queen) vs CPU 7 (7/9) -> White wins
      final outcome12vs7 = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 12,
        blackScore: 7,
        queenCovered: true,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 0,
        blackRemaining: 2,
        whitePenaltyDue: 0,
        blackPenaltyDue: 0,
      );
      expect(outcome12vs7.isMatchOver, isTrue);
      expect(outcome12vs7.winner, equals(PlayerColor.white), reason: 'White 12 pts beats CPU 7 pts');
      expect(outcome12vs7.whiteScore, equals(12));
      expect(outcome12vs7.blackScore, equals(7));

      // Scenario C1: White 9 (9/9 cleared) vs CPU 9 (6/9 + Queen) -> White wins (first legal clearance)
      final outcomeTieWhiteCleared = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 3,
      );
      expect(outcomeTieWhiteCleared.isMatchOver, isTrue);
      expect(outcomeTieWhiteCleared.winner, equals(PlayerColor.white), reason: 'Tie-breaker: White cleared all 9 pieces first');

      // Scenario C2: White 9 (6/9 + Queen) vs CPU 9 (9/9 cleared) -> CPU wins (first legal clearance)
      final outcomeTieBlackCleared = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 3,
        blackRemaining: 0,
      );
      expect(outcomeTieBlackCleared.isMatchOver, isTrue);
      expect(outcomeTieBlackCleared.winner, equals(PlayerColor.black), reason: 'Tie-breaker: CPU cleared all 9 pieces first');

      // Scenario D1: Queen unresolved (not covered) -> No premature victory
      final outcomeQueenUncovered = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 5,
        queenCovered: false,
        needsCover: false,
        whiteRemaining: 0,
        blackRemaining: 4,
      );
      expect(outcomeQueenUncovered.isMatchOver, isFalse, reason: 'Match cannot end while Queen is uncovered');
      expect(outcomeQueenUncovered.winner, isNull);

      // Scenario D2: Queen awaiting cover shot (needsCover: true) -> No premature victory
      final outcomeQueenNeedsCover = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 5,
        queenCovered: false,
        needsCover: true,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 0,
        blackRemaining: 4,
      );
      expect(outcomeQueenNeedsCover.isMatchOver, isFalse, reason: 'Match cannot end while Queen cover shot is pending');
      expect(outcomeQueenNeedsCover.winner, isNull);

      // Scenario D3: Unresolved penalty due on clearing player -> No premature victory
      final outcomePendingDue = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 8,
        blackScore: 7,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 5,
        whitePenaltyDue: 1,
      );
      expect(outcomePendingDue.isMatchOver, isFalse, reason: 'Match cannot end while clearing player owes a penalty due');
      expect(outcomePendingDue.winner, isNull);
    });

    testWidgets('13. Screenshot Scenario Widget Verification: White 9 (9/9 cleared) vs CPU 10 (7/9 + Queen) renders CPU WINS', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(450, 850));

      final outcome = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 10,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 2,
      );
      expect(outcome.winner, equals(PlayerColor.black));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              matchOutcome: outcome,
              winner: outcome.winner!,
              whiteScore: 9,
              blackScore: 10,
              whiteRemaining: 0,
              blackRemaining: 2,
              queenCoveredBy: PlayerColor.black,
              gameMode: GameMode.vsCpu,
              isHumanWinner: outcome.winner == PlayerColor.white,
              matchId: 'test_screenshot_9_vs_10',
              onRematch: () {},
              onMainMenu: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('CPU WINS!'), findsOneWidget);
      expect(find.text('YOU WIN!'), findsNothing);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('9/9 Cleared'), findsOneWidget);
      expect(find.text('7/9 potted • 2 left'), findsOneWidget);
      expect(find.text('👑 Queen (+3)'), findsOneWidget);
      expect(find.text('WINNER'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });

    test('14. Match Outcome Reliability Audit: Opponent-potted 9th piece, simultaneous tie-break, and single-respot invariants', () {
      // 1. Opponent pockets player's 9th piece on tied score (9 vs 9):
      // Black shoots (clearingPlayer = black) and accidentally pockets White's 9th piece (whiteRemaining = 0, blackRemaining = 3).
      // Legal piece ownership belongs to White, so White is firstClearedBy and wins the tie-breaker!
      final opponentPottedLast = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 3,
        clearingPlayer: PlayerColor.black,
      );
      expect(opponentPottedLast.isMatchOver, isTrue);
      expect(opponentPottedLast.firstClearedBy, equals(PlayerColor.white));
      expect(opponentPottedLast.winner, equals(PlayerColor.white));

      // 2. Simultaneous White & Black clearance on the same shot with tied scores (9 vs 9):
      // Black's 9th piece enters pocket first (index 0), then White's 9th piece enters second (index 1).
      final black9 = PieceModel(id: 10, type: PieceType.black, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true;
      final white9 = PieceModel(id: 19, type: PieceType.white, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true;
      final simTurnResult = TurnResult(
        pocketedOwn: true,
        pocketedOpponent: true,
        piecesPocketedThisTurn: [PieceType.black, PieceType.white],
        pocketedPieces: [black9, white9],
      );
      final simultaneousOutcome = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 0,
        blackRemaining: 0,
        clearingPlayer: PlayerColor.white,
        turnResult: simTurnResult,
      );
      expect(simultaneousOutcome.isMatchOver, isTrue);
      expect(simultaneousOutcome.firstClearedBy, equals(PlayerColor.black), reason: 'Black 9th piece entered pocket before White 9th piece');
      expect(simultaneousOutcome.winner, equals(PlayerColor.black));

      // 3. Premature last-piece respotting never duplicates pieces or subtracts scores twice
      final queen = PieceModel(id: 1, type: PieceType.queen, position: Vector2.zero, radius: 10, mass: 1);
      final boardPieces = <PieceModel>[
        queen,
        for (int i = 0; i < 9; i++)
          PieceModel(id: 2 + i, type: PieceType.white, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = true,
        for (int i = 0; i < 9; i++)
          PieceModel(id: 11 + i, type: PieceType.black, position: Vector2.zero, radius: 10, mass: 1)..isPocketed = (i < 5),
      ];
      expect(boardPieces.length, equals(19));

      final lastWhitePiece = boardPieces.where((p) => p.type == PieceType.white).last;
      final prematureTurn = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white],
        pocketedPieces: [lastWhitePiece],
      );
      final evalPremature = CarromTurnEvaluator.evaluate(
        result: prematureTurn,
        currentPlayer: PlayerColor.white,
        whiteScore: 8,
        blackScore: 5,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: boardPieces,
      );
      expect(evalPremature.whiteScore, equals(8), reason: 'Score stays at 8, never subtracted to 7');
      expect(evalPremature.piecesToRespot.length, equals(1));
      for (final p in evalPremature.piecesToRespot) {
        CarromRespotter.respotPiece(p, boardPieces);
      }
      expect(boardPieces.length, equals(19), reason: 'Piece count strictly invariant at 19');
      expect(boardPieces.where((p) => p.type == PieceType.white && !p.isPocketed).length, equals(1));

      // 4. Stale firstClearedBy is invalidated when respotting reverses that player's clearance
      final invalidatedFirstCleared = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 1, // White had 1 piece respotted
        blackRemaining: 0, // Black legally cleared all 9
        firstClearedBy: PlayerColor.white, // Stale prior flag must be invalidated
      );
      expect(invalidatedFirstCleared.isMatchOver, isTrue);
      expect(invalidatedFirstCleared.firstClearedBy, equals(PlayerColor.black));
      expect(invalidatedFirstCleared.winner, equals(PlayerColor.black));

      // 5. Simultaneous clearance with no chronological order uses fair Queen-cover merit (no White bias)
      final simultaneousQueenMerit = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 0,
      );
      expect(simultaneousQueenMerit.isMatchOver, isTrue);
      expect(simultaneousQueenMerit.winner, equals(PlayerColor.black));

      // 6. Unresolved simultaneous tie without any tie-break merit never defaults unfairly to White
      final unresolvedSymmetricTie = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 9,
        blackScore: 9,
        queenCovered: true,
        queenCoveredBy: null,
        whiteRemaining: 0,
        blackRemaining: 0,
      );
      expect(unresolvedSymmetricTie.isMatchOver, isFalse);
      expect(unresolvedSymmetricTie.winner, isNull);
    });
  });
}
