import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/ai/carrom_ai.dart';
import 'package:carrom_master/core/carrom_rule_engine.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/turn_timer_controller.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/models/turn_result.dart';
import 'package:carrom_master/screens/game_over_dialog.dart';
import 'package:carrom_master/screens/game_screen.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/services/audio_service.dart';

List<PieceModel> _createStandardPieces() {
  final pieces = <PieceModel>[
    PieceModel(
      id: 1,
      type: PieceType.queen,
      position: GameConfig.queenInitialPos,
      radius: GameConfig.queenRadius,
      mass: GameConfig.pieceMass,
    ),
  ];
  int id = 2;
  for (int i = 0; i < 9; i++) {
    pieces.add(
      PieceModel(
        id: id++,
        type: PieceType.white,
        position: Vector2(-30.0 + i * 5.0, 20.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      ),
    );
  }
  for (int i = 0; i < 9; i++) {
    pieces.add(
      PieceModel(
        id: id++,
        type: PieceType.black,
        position: Vector2(-30.0 + i * 5.0, -20.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      ),
    );
  }
  return pieces;
}

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

  group('Freestyle Points Mode & Ludo Star-Style Turn Countdown Suite', () {
    test('1. Freestyle scoring for White (10), Black (20), and either player pocketing any coin', () {
      final pieces = _createStandardPieces();
      final whiteCoin = pieces.firstWhere((p) => p.type == PieceType.white);
      final blackCoin = pieces.firstWhere((p) => p.type == PieceType.black);

      // Player 1 (white) pockets a Black coin -> +20 to Player 1, continuesTurn: true
      blackCoin.isPocketed = true;
      final evalP1Black = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          piecesPocketedThisTurn: [PieceType.black],
          pocketedPieces: [blackCoin],
        ),
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        ruleset: CarromRuleset.freestyle,
      );
      expect(evalP1Black.whiteScore, equals(20));
      expect(evalP1Black.blackScore, equals(0));
      expect(evalP1Black.continuesTurn, isTrue);

      // Player 2 (black) pockets both a White (10) and a Black (20) coin -> +30 to Player 2
      final secondBlack = pieces
          .where((p) => p.type == PieceType.black && !p.isPocketed)
          .first;
      whiteCoin.isPocketed = true;
      secondBlack.isPocketed = true;
      final evalP2Multi = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          piecesPocketedThisTurn: [PieceType.white, PieceType.black],
          pocketedPieces: [whiteCoin, secondBlack],
        ),
        currentPlayer: PlayerColor.black,
        whiteScore: evalP1Black.whiteScore,
        blackScore: evalP1Black.blackScore,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        ruleset: CarromRuleset.freestyle,
      );
      expect(evalP2Multi.whiteScore, equals(20));
      expect(evalP2Multi.blackScore, equals(30));
      expect(evalP2Multi.continuesTurn, isTrue);
    });

    test('2. Freestyle same-shot and next-shot Queen cover (50 pts + cover coin pts)', () {
      // Case A: Same-shot Queen + Black coin -> 50 + 20 = 70 points
      final piecesSame = _createStandardPieces();
      final queenSame = piecesSame.firstWhere((p) => p.type == PieceType.queen)
        ..isPocketed = true;
      final blackSame = piecesSame.firstWhere((p) => p.type == PieceType.black)
        ..isPocketed = true;

      final sameShotEval = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          pocketedQueen: true,
          piecesPocketedThisTurn: [PieceType.queen, PieceType.black],
          pocketedPieces: [queenSame, blackSame],
        ),
        currentPlayer: PlayerColor.white,
        whiteScore: 10,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: piecesSame,
        ruleset: CarromRuleset.freestyle,
      );
      expect(sameShotEval.queenCovered, isTrue);
      expect(sameShotEval.needsCover, isFalse);
      expect(sameShotEval.queenPocketedBy, equals(PlayerColor.white));
      expect(sameShotEval.whiteScore, equals(80)); // 10 + 50 + 20
      expect(sameShotEval.continuesTurn, isTrue);

      // Case B: Next-shot Queen cover with White coin -> 50 + 10 = 60 points
      final piecesNext = _createStandardPieces();
      final queenNext = piecesNext.firstWhere((p) => p.type == PieceType.queen)
        ..isPocketed = true;

      final potQueenAlone = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedQueen: true,
          piecesPocketedThisTurn: [PieceType.queen],
          pocketedPieces: [queenNext],
        ),
        currentPlayer: PlayerColor.black,
        whiteScore: 20,
        blackScore: 40,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: piecesNext,
        ruleset: CarromRuleset.freestyle,
      );
      expect(potQueenAlone.queenPocketed, isTrue);
      expect(potQueenAlone.queenCovered, isFalse);
      expect(potQueenAlone.needsCover, isTrue);
      expect(potQueenAlone.blackScore, equals(40)); // Not awarded until covered
      expect(potQueenAlone.continuesTurn, isTrue);

      // Follow-up shot pockets a White coin (10 pts) to cover Queen (+50 pts)
      final whiteCover = piecesNext.firstWhere((p) => p.type == PieceType.white)
        ..isPocketed = true;
      final coverShotEval = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          piecesPocketedThisTurn: [PieceType.white],
          pocketedPieces: [whiteCover],
        ),
        currentPlayer: PlayerColor.black,
        whiteScore: potQueenAlone.whiteScore,
        blackScore: potQueenAlone.blackScore,
        queenPocketed: potQueenAlone.queenPocketed,
        queenCovered: potQueenAlone.queenCovered,
        queenPocketedBy: potQueenAlone.queenPocketedBy,
        needsCover: potQueenAlone.needsCover,
        allPieces: piecesNext,
        ruleset: CarromRuleset.freestyle,
      );
      expect(coverShotEval.queenCovered, isTrue);
      expect(coverShotEval.needsCover, isFalse);
      expect(coverShotEval.blackScore, equals(100)); // 40 + 50 + 10
      expect(coverShotEval.continuesTurn, isTrue);
    });

    test('3. Failed Queen cover returns Queen without 50 pts & prevents last-coin Queen deadlock', () {
      final pieces = _createStandardPieces();
      final queen = pieces.firstWhere((p) => p.type == PieceType.queen)
        ..isPocketed = true;

      // Player misses cover shot -> Queen respotted, 0 points added, turn passes
      final failedCover = CarromTurnEvaluator.evaluate(
        result: TurnResult(),
        currentPlayer: PlayerColor.white,
        whiteScore: 30,
        blackScore: 20,
        queenPocketed: true,
        queenCovered: false,
        queenPocketedBy: PlayerColor.white,
        needsCover: true,
        allPieces: pieces,
        ruleset: CarromRuleset.freestyle,
      );
      expect(failedCover.queenCovered, isFalse);
      expect(failedCover.queenPocketed, isFalse);
      expect(failedCover.needsCover, isFalse);
      expect(failedCover.whiteScore, equals(30));
      expect(failedCover.continuesTurn, isFalse);
      expect(failedCover.piecesToRespot, contains(queen));

      // Deadlock prevention: All normal coins pocketed while Queen is still on board uncovered
      final deadlockPieces = _createStandardPieces();
      for (final p in deadlockPieces) {
        if (p.type == PieceType.white || p.type == PieceType.black) {
          p.isPocketed = true;
        }
      }
      final lastNormal = deadlockPieces.firstWhere((p) => p.type == PieceType.black);
      final prematureLastCoinEval = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          piecesPocketedThisTurn: [PieceType.black],
          pocketedPieces: [lastNormal],
        ),
        currentPlayer: PlayerColor.white,
        whiteScore: 120,
        blackScore: 100,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: deadlockPieces,
        ruleset: CarromRuleset.freestyle,
      );
      expect(prematureLastCoinEval.whiteScore, equals(120),
          reason: 'Points not awarded when pocketing last normal coin before Queen');
      expect(prematureLastCoinEval.piecesToRespot, contains(lastNormal));
      expect(prematureLastCoinEval.continuesTurn, isFalse);
    });

    test('4. Winning at or above 160 points after valid shot resolution', () {
      // Pending Queen cover blocks premature victory even at 160 points
      final pendingCoverOutcome = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 160,
        blackScore: 120,
        queenCovered: false,
        needsCover: true,
        whiteRemaining: 3,
        blackRemaining: 2,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(pendingCoverOutcome.isMatchOver, isFalse);
      expect(pendingCoverOutcome.winner, isNull);

      // Resolved turn at 170 vs 120 -> Player 1 wins immediately
      final validTargetWin = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 170,
        blackScore: 120,
        queenCovered: true,
        needsCover: false,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 3,
        blackRemaining: 2,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(validTargetWin.isMatchOver, isTrue);
      expect(validTargetWin.isDraw, isFalse);
      expect(validTargetWin.winner, equals(PlayerColor.white));
    });

    testWidgets('5. Final-board score comparison and explicit DRAW handling when all coins are cleared below target', (tester) async {
      // Sub-target all coins cleared: 150 vs 140 -> Player 1 wins
      final boardClearedWin = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 150,
        blackScore: 140,
        queenCovered: true,
        needsCover: false,
        queenCoveredBy: PlayerColor.white,
        whiteRemaining: 0,
        blackRemaining: 0,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(boardClearedWin.isMatchOver, isTrue);
      expect(boardClearedWin.isDraw, isFalse);
      expect(boardClearedWin.winner, equals(PlayerColor.white));

      // Sub-target all coins cleared with equal scores: 140 vs 140 -> Explicit DRAW
      final boardClearedDraw = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: 140,
        blackScore: 140,
        queenCovered: true,
        needsCover: false,
        queenCoveredBy: PlayerColor.black,
        whiteRemaining: 0,
        blackRemaining: 0,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(boardClearedDraw.isMatchOver, isTrue);
      expect(boardClearedDraw.isDraw, isTrue);
      expect(boardClearedDraw.winner, isNull);

      // Verify GameOverDialog renders MATCH DRAW! and DRAW badges accurately
      await tester.binding.setSurfaceSize(const Size(450, 850));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              matchOutcome: boardClearedDraw,
              winner: boardClearedDraw.winner,
              whiteScore: 140,
              blackScore: 140,
              whiteRemaining: 0,
              blackRemaining: 0,
              queenCoveredBy: PlayerColor.black,
              gameMode: GameMode.vsCpu,
              ruleset: CarromRuleset.freestyle,
              targetScore: 160,
              isHumanWinner: false,
              onRematch: () {},
              onMainMenu: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('MATCH DRAW!'), findsOneWidget);
      expect(find.text('DRAW'), findsNWidgets(2));
      expect(find.text('👑 Queen (+50)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });

    test('6. Striker fouls and score rollback in Freestyle mode', () {
      final pieces = _createStandardPieces();
      final previouslyPocketedWhite = pieces
          .where((p) => p.type == PieceType.white)
          .first
        ..isPocketed = true;
      final foulShotBlack = pieces
          .where((p) => p.type == PieceType.black)
          .first
        ..isPocketed = true;
      final queen = pieces.firstWhere((p) => p.type == PieceType.queen)
        ..isPocketed = true;

      // Player pockets Black coin + Queen AND scratches striker on the same shot
      final foulEval = CarromTurnEvaluator.evaluate(
        result: TurnResult(
          pocketedOwn: true,
          pocketedQueen: true,
          pocketedStriker: true,
          piecesPocketedThisTurn: [PieceType.black, PieceType.queen],
          pocketedPieces: [foulShotBlack, queen],
        ),
        currentPlayer: PlayerColor.white,
        whiteScore: 30,
        blackScore: 40,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        ruleset: CarromRuleset.freestyle,
      );

      // Score rolled back (no +20 or +50 awarded) AND -10 foul penalty applied (30 -> 20)
      expect(foulEval.whiteScore, equals(20));
      expect(foulEval.blackScore, equals(40));
      expect(foulEval.continuesTurn, isFalse);
      expect(foulEval.queenPocketed, isFalse);
      expect(foulEval.queenCovered, isFalse);
      // Both the foul-shot coins (Queen + Black) AND 1 previously pocketed coin are respotted
      expect(foulEval.piecesToRespot, containsAll([queen, foulShotBlack, previouslyPocketedWhite]));
    });

    test('7, 8 & 9. TurnTimerController: 20s expiration, warning ticks, continuation reset, pause/resume & single-timeout guard', () {
      int timeoutCount = 0;
      int lastTimedOutToken = -1;
      final List<int> warningSeconds = [];

      final timer = TurnTimerController(
        turnDurationSeconds: 20.0,
        warningThresholdSeconds: 5.0,
        enabled: true,
        onTimeout: (token) {
          timeoutCount++;
          lastTimedOutToken = token;
        },
        onWarningTick: (sec) {
          warningSeconds.add(sec);
        },
      );

      // Start initial turn
      final int token1 = timer.startNewTurn();
      expect(timer.isRunning, isTrue);
      expect(timer.remainingSeconds, equals(20.0));
      expect(timer.displaySeconds, equals(20));

      // Advance 8 seconds -> 12s remaining, no warning
      expect(timer.tick(8.0), isFalse);
      expect(timer.remainingSeconds, closeTo(12.0, 1e-6));
      expect(timer.isWarning, isFalse);
      expect(warningSeconds, isEmpty);

      // Pause and verify ticks do not advance countdown while paused
      timer.pause();
      expect(timer.isPaused, isTrue);
      expect(timer.tick(10.0), isFalse);
      expect(timer.remainingSeconds, closeTo(12.0, 1e-6));

      // Resume countdown
      timer.resume();
      expect(timer.isPaused, isFalse);

      // Continuation shot resets countdown back to full 20 seconds with a new token
      final int token2 = timer.startNewTurn();
      expect(token2, greaterThan(token1));
      expect(timer.remainingSeconds, equals(20.0));

      // Advance into final 5-second warning window (15.2s elapsed -> 4.8s left -> ceil is 5s)
      expect(timer.tick(15.2), isFalse);
      expect(timer.isWarning, isTrue);
      expect(warningSeconds, contains(5));

      // Advance 1s at a time down to 0
      expect(timer.tick(1.0), isFalse); // 3.8s -> 4s
      expect(timer.tick(1.0), isFalse); // 2.8s -> 3s
      expect(timer.tick(1.0), isFalse); // 1.8s -> 2s
      expect(timer.tick(1.0), isFalse); // 0.8s -> 1s
      expect(warningSeconds, equals([5, 4, 3, 2, 1]));

      // Expire timer
      expect(timer.tick(1.0), isTrue);
      expect(timer.isRunning, isFalse);
      expect(timer.remainingSeconds, equals(0.0));
      expect(timeoutCount, equals(1));
      expect(lastTimedOutToken, equals(token2));

      // Further ticks after expiration never trigger a duplicate timeout
      expect(timer.tick(5.0), isFalse);
      expect(timeoutCount, equals(1));

      // Timeout during pending Queen cover returns Queen to center and passes turn
      final pieces = _createStandardPieces();
      final queen = pieces.firstWhere((p) => p.type == PieceType.queen)
        ..isPocketed = true;
      final timeoutCoverEval = CarromTurnEvaluator.evaluateTimeout(
        currentPlayer: PlayerColor.white,
        whiteScore: 40,
        blackScore: 20,
        queenPocketed: true,
        queenCovered: false,
        queenPocketedBy: PlayerColor.white,
        needsCover: true,
        allPieces: pieces,
      );
      expect(timeoutCoverEval.continuesTurn, isFalse);
      expect(timeoutCoverEval.queenPocketed, isFalse);
      expect(timeoutCoverEval.needsCover, isFalse);
      expect(timeoutCoverEval.piecesToRespot, contains(queen));
    });

    test('10. CPU AI behavior in both Classic and Freestyle modes', () {
      // In Freestyle, even when only White coins remain on the board, Black CPU targets them!
      final whiteOnlyPieces = <PieceModel>[
        PieceModel(
          id: 1,
          type: PieceType.queen,
          position: Vector2.zero,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
          isPocketed: true,
        ),
        PieceModel(
          id: 2,
          type: PieceType.white,
          position: const Vector2(120.0, -120.0), // Near top-right pocket
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYBlack),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final hardAi = CarromAI(difficulty: AiDifficulty.hard);
      final freestyleShot = hardAi.calculateShot(
        pieces: whiteOnlyPieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: false,
        queenCovered: true,
        whiteScore: 60,
        blackScore: 150,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(freestyleShot.strikerX,
          inInclusiveRange(-GameConfig.baselineHalfWidth, GameConfig.baselineHalfWidth));
      expect(freestyleShot.power, inInclusiveRange(0.30, 1.0));
      expect(freestyleShot.angle.isNaN, isFalse);
      expect(freestyleShot.confidenceScore, greaterThan(100.0),
          reason: 'Freestyle CPU actively targets and scores the White coin to reach 160');

      // Also verify Queen cover in Freestyle when only White coins remain
      final coverShot = hardAi.calculateShot(
        pieces: whiteOnlyPieces,
        striker: striker,
        aiColor: PlayerColor.black,
        needsQueenCover: true,
        queenCovered: false,
        queenPocketed: true,
        queenPocketedBy: PlayerColor.black,
        whiteScore: 40,
        blackScore: 80,
        ruleset: CarromRuleset.freestyle,
        targetScore: 160,
      );
      expect(coverShot.confidenceScore, greaterThan(100.0),
          reason: 'Freestyle CPU covers Queen using an available White coin');
    });

    testWidgets('11. MenuScreen ruleset selection & GameScreen Freestyle HUD + Turn Timer integration', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 880));
      await tester.pumpWidget(
        const MaterialApp(
          home: MenuScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify both ruleset options appear on MenuScreen
      expect(find.text('CLASSIC CARROM'), findsOneWidget);
      expect(find.text('FREESTYLE POINTS'), findsOneWidget);

      // Select FREESTYLE POINTS
      await tester.tap(find.text('FREESTYLE POINTS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('FREESTYLE POINTS • 160 TARGET'), findsOneWidget);

      // Launch VS CPU in Freestyle mode
      await tester.tap(find.text('VS CPU'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('You (P1)'), findsOneWidget);
      expect(find.text('CPU (P2)'), findsOneWidget);
      expect(find.text('👑 Q:50 • W:10 • B:20'), findsOneWidget);
      expect(find.byType(ClubTurnTimerRing), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });
  });
}

