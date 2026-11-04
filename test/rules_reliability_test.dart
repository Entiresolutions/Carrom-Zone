import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/carrom_rule_engine.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/models/turn_result.dart';

void main() {
  group('Carrom Rule Engine Reliability Test Suite (Phase 1B)', () {
    List<PieceModel> createStandardBoard() {
      final List<PieceModel> pieces = [];
      int id = 1;

      // Queen
      pieces.add(PieceModel(
        id: id++,
        type: PieceType.queen,
        position: GameConfig.queenInitialPos,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      ));

      // 9 White and 9 Black pieces
      for (int i = 0; i < 9; i++) {
        pieces.add(PieceModel(
          id: id++,
          type: PieceType.white,
          position: Vector2(-60.0 + i * 15.0, -20.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ));
        pieces.add(PieceModel(
          id: id++,
          type: PieceType.black,
          position: Vector2(-60.0 + i * 15.0, 20.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ));
      }

      return pieces;
    }

    test('1. Queen same-shot cover: Awards +3 Queen AND +1 own piece, turn continues', () {
      final pieces = createStandardBoard();
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);

      whitePiece.isPocketed = true;
      queenPiece.isPocketed = true;

      final turnResult = TurnResult(
        pocketedQueen: true,
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.queen, PieceType.white],
        pocketedPieces: [queenPiece, whitePiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(4), reason: '3 pts for Queen + 1 pt for white piece');
      expect(eval.blackScore, equals(0));
      expect(eval.queenCovered, isTrue);
      expect(eval.queenPocketed, isTrue);
      expect(eval.needsCover, isFalse);
      expect(eval.continuesTurn, isTrue);
      expect(eval.piecesToRespot, isEmpty);
    });

    test('2. Queen next-shot cover: Shot 1 pockets Queen, Shot 2 covers with own piece', () {
      final pieces = createStandardBoard();
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      queenPiece.isPocketed = true;

      // Shot 1: Queen pocketed alone
      final shot1Result = TurnResult(
        pocketedQueen: true,
        piecesPocketedThisTurn: [PieceType.queen],
        pocketedPieces: [queenPiece],
      );

      final eval1 = CarromTurnEvaluator.evaluate(
        result: shot1Result,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval1.whiteScore, equals(0), reason: 'Queen points not awarded until covered');
      expect(eval1.queenPocketed, isTrue);
      expect(eval1.queenPocketedBy, equals(PlayerColor.white));
      expect(eval1.needsCover, isTrue);
      expect(eval1.queenCovered, isFalse);
      expect(eval1.continuesTurn, isTrue);

      // Shot 2: White pockets 2 white pieces to cover
      final whitePiece1 = pieces.where((p) => p.type == PieceType.white).first;
      final whitePiece2 = pieces.where((p) => p.type == PieceType.white).skip(1).first;
      whitePiece1.isPocketed = true;
      whitePiece2.isPocketed = true;

      final shot2Result = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white, PieceType.white],
        pocketedPieces: [whitePiece1, whitePiece2],
      );

      final eval2 = CarromTurnEvaluator.evaluate(
        result: shot2Result,
        currentPlayer: PlayerColor.white,
        whiteScore: eval1.whiteScore,
        blackScore: eval1.blackScore,
        queenPocketed: eval1.queenPocketed,
        queenCovered: eval1.queenCovered,
        queenPocketedBy: eval1.queenPocketedBy,
        needsCover: eval1.needsCover,
        allPieces: pieces,
      );

      expect(eval2.whiteScore, equals(5), reason: '3 pts for Queen + 2 pts for 2 white pieces');
      expect(eval2.queenCovered, isTrue);
      expect(eval2.needsCover, isFalse);
      expect(eval2.continuesTurn, isTrue);
      expect(eval2.piecesToRespot, isEmpty);
    });

    test('3. Queen failed cover: Shot 2 misses, Queen returns to center, turn passes', () {
      final pieces = createStandardBoard();
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      queenPiece.isPocketed = true;

      // Shot 2: Miss (no pieces pocketed)
      final shot2Result = TurnResult();

      final eval2 = CarromTurnEvaluator.evaluate(
        result: shot2Result,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: true,
        queenCovered: false,
        queenPocketedBy: PlayerColor.white,
        needsCover: true,
        allPieces: pieces,
      );

      expect(eval2.whiteScore, equals(0));
      expect(eval2.queenCovered, isFalse);
      expect(eval2.queenPocketed, isFalse);
      expect(eval2.needsCover, isFalse);
      expect(eval2.continuesTurn, isFalse, reason: 'Turn must pass to opponent on failed cover');
      expect(eval2.piecesToRespot, contains(queenPiece));
    });

    test('4. Foul on Queen: Striker and Queen pocketed together cancels cover and respots Queen', () {
      final pieces = createStandardBoard();
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      queenPiece.isPocketed = true;

      // Striker + Queen simultaneously
      final foulResult = TurnResult(
        pocketedStriker: true,
        pocketedQueen: true,
        piecesPocketedThisTurn: [PieceType.queen],
        pocketedPieces: [queenPiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 2,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(1), reason: '1 pt deducted for striker foul');
      expect(eval.queenPocketed, isFalse);
      expect(eval.queenCovered, isFalse);
      expect(eval.needsCover, isFalse);
      expect(eval.continuesTurn, isFalse);
      expect(eval.piecesToRespot, contains(queenPiece), reason: 'Queen must be respotted on foul');
    });

    test('5. Foul on Cover Shot: Striker pocketed during cover shot cancels cover and respots Queen', () {
      final pieces = createStandardBoard();
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      queenPiece.isPocketed = true;

      // Striker pocketed on cover shot
      final foulResult = TurnResult(
        pocketedStriker: true,
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 3,
        blackScore: 0,
        queenPocketed: true,
        queenCovered: false,
        queenPocketedBy: PlayerColor.white,
        needsCover: true,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(2), reason: '1 pt deducted for striker foul');
      expect(eval.queenPocketed, isFalse);
      expect(eval.queenCovered, isFalse);
      expect(eval.needsCover, isFalse);
      expect(eval.continuesTurn, isFalse);
      expect(eval.piecesToRespot, contains(queenPiece));
    });

    test('6. Striker foul with own piece potted: Own piece returned + penalty piece returned', () {
      final pieces = createStandardBoard();
      final whitePiece1 = pieces.where((p) => p.type == PieceType.white).first;
      final whitePiece2 = pieces.where((p) => p.type == PieceType.white).skip(1).first;

      // whitePiece1 was already pocketed on a previous turn
      whitePiece1.isPocketed = true;

      // whitePiece2 is pocketed on THIS foul shot
      whitePiece2.isPocketed = true;

      final foulResult = TurnResult(
        pocketedStriker: true,
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white],
        pocketedPieces: [whitePiece2],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 1,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(0), reason: '1 pt deducted for foul');
      expect(eval.continuesTurn, isFalse);
      // Both the illegally potted piece AND the penalty piece must be respotted
      expect(eval.piecesToRespot, contains(whitePiece2), reason: 'Coin potted on foul shot must return');
      expect(eval.piecesToRespot, contains(whitePiece1), reason: 'Previously potted coin returned as penalty');
    });

    test('7. Striker foul with opponent piece potted: Opponent piece stays pocketed and credited', () {
      final pieces = createStandardBoard();
      final blackPiece = pieces.firstWhere((p) => p.type == PieceType.black);
      blackPiece.isPocketed = true;

      final foulResult = TurnResult(
        pocketedStriker: true,
        pocketedOpponent: true,
        piecesPocketedThisTurn: [PieceType.black],
        pocketedPieces: [blackPiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 2,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(1), reason: 'White loses 1 pt for foul');
      expect(eval.blackScore, equals(1), reason: 'Black gets 1 pt for potted black piece');
      expect(eval.continuesTurn, isFalse);
      expect(eval.piecesToRespot, isNot(contains(blackPiece)), reason: 'Opponent piece stays pocketed');
    });

    test('8. Mixed own + opponent pieces (No foul): Both credited, turn passes', () {
      final pieces = createStandardBoard();
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      final blackPiece = pieces.firstWhere((p) => p.type == PieceType.black);
      whitePiece.isPocketed = true;
      blackPiece.isPocketed = true;

      final turnResult = TurnResult(
        pocketedOwn: true,
        pocketedOpponent: true,
        piecesPocketedThisTurn: [PieceType.white, PieceType.black],
        pocketedPieces: [whitePiece, blackPiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(1), reason: 'White gets 1 pt for white piece');
      expect(eval.blackScore, equals(1), reason: 'Black gets 1 pt for black piece');
      expect(eval.continuesTurn, isFalse, reason: 'Turn passes because opponent piece was pocketed');
      expect(eval.piecesToRespot, isEmpty);
    });

    test('9. Score non-negativity: Foul at 0 score never produces negative score', () {
      final pieces = createStandardBoard();

      final foulResult = TurnResult(
        pocketedStriker: true,
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.whiteScore, equals(0), reason: 'Score floored at 0');
      expect(eval.continuesTurn, isFalse);
    });

    test('10. Premature last piece: Last piece pocketed without Queen is respotted, game not stuck', () {
      final pieces = createStandardBoard();

      // Pocket 8 white pieces previously
      final whitePieces = pieces.where((p) => p.type == PieceType.white).toList();
      for (int i = 0; i < 8; i++) {
        whitePieces[i].isPocketed = true;
      }

      // Pocket 9th (last) white piece on this shot, but Queen is still unpocketed
      final lastWhite = whitePieces[8];
      lastWhite.isPocketed = true;

      final turnResult = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white],
        pocketedPieces: [lastWhite],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 8,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.piecesToRespot, contains(lastWhite), reason: 'Premature last piece must be respotted');
      expect(eval.continuesTurn, isFalse);
      expect(eval.whiteScore, equals(8), reason: 'Premature piece does not score');
    });

    test('11. Deterministic respotting: Respots multiple pieces without overlap (clearance >= 24)', () {
      final pieces = createStandardBoard();
      final p1 = pieces.where((p) => p.type == PieceType.white).first;
      final p2 = pieces.where((p) => p.type == PieceType.white).skip(1).first;
      final p3 = pieces.where((p) => p.type == PieceType.white).skip(2).first;

      // Place a piece at exact center (0, 0)
      p1.position = Vector2.zero;
      p1.isPocketed = false;

      // Respot p2
      CarromRespotter.respotPiece(p2, pieces);
      expect(p2.position.distanceTo(p1.position), greaterThanOrEqualTo(23.5));
      expect(p2.isPocketed, isFalse);

      // Respot p3
      CarromRespotter.respotPiece(p3, pieces);
      expect(p3.position.distanceTo(p1.position), greaterThanOrEqualTo(23.5));
      expect(p3.position.distanceTo(p2.position), greaterThanOrEqualTo(23.5));
      expect(p3.isPocketed, isFalse);
    });

    test('12. Penalty Due Incurred: Foul with 0 pocketed coins records 1 Due, score stays 0, 0 pieces respotted', () {
      final pieces = createStandardBoard();

      // Striker scratch with 0 pieces in pocket
      final foulResult = TurnResult(pocketedStriker: true);

      final eval = CarromTurnEvaluator.evaluate(
        result: foulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 0,
      );

      expect(eval.whitePenaltyDue, equals(1), reason: 'Penalty Due recorded because no piece was in pocket');
      expect(eval.whiteScore, equals(0), reason: 'Score stays floored at 0');
      expect(eval.continuesTurn, isFalse);
      expect(eval.piecesToRespot, isEmpty, reason: 'No previously pocketed piece existed to respot');
    });

    test('13. Penalty Due Paid: Pocketing 1 piece with 1 Due pays off penalty, 0 score gained, turn passes', () {
      final pieces = createStandardBoard();
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      whitePiece.isPocketed = true;

      final turnResult = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white],
        pocketedPieces: [whitePiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 1,
      );

      expect(eval.whitePenaltyDue, equals(0), reason: 'Due is cleared');
      expect(eval.piecesToRespot, contains(whitePiece), reason: 'Potted piece returned to board to pay Due');
      expect(eval.whiteScore, equals(0), reason: 'Paid piece does not count toward score');
      expect(eval.continuesTurn, isFalse, reason: 'Turn passes because net scored pieces is 0');
    });

    test('14. Surplus piece with Penalty Due: Pocketing 2 pieces with 1 Due pays 1 Due, scores 1 piece, turn continues', () {
      final pieces = createStandardBoard();
      final w1 = pieces.where((p) => p.type == PieceType.white).first;
      final w2 = pieces.where((p) => p.type == PieceType.white).skip(1).first;
      w1.isPocketed = true;
      w2.isPocketed = true;

      final turnResult = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white, PieceType.white],
        pocketedPieces: [w1, w2],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 1,
      );

      expect(eval.whitePenaltyDue, equals(0), reason: 'Due paid off');
      expect(eval.piecesToRespot.length, equals(1), reason: '1 piece respotted for Due');
      expect(eval.whiteScore, equals(1), reason: 'Surplus piece awarded (+1 pt)');
      expect(eval.continuesTurn, isTrue, reason: 'Turn continues because 1 net piece was cleanly pocketed');
    });

    test('15. Queen pot with Pending Due: Pocketing Queen + 1 coin with 1 Due pays Due with coin, Queen returned to center, turn passes', () {
      final pieces = createStandardBoard();
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      whitePiece.isPocketed = true;
      queenPiece.isPocketed = true;

      final turnResult = TurnResult(
        pocketedQueen: true,
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.queen, PieceType.white],
        pocketedPieces: [queenPiece, whitePiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 1,
      );

      expect(eval.whitePenaltyDue, equals(0), reason: 'Due paid by the white coin');
      expect(eval.piecesToRespot, contains(whitePiece), reason: 'White coin returned to board');
      expect(eval.piecesToRespot, contains(queenPiece), reason: 'Queen cannot be covered while Due pending, returns to center');
      expect(eval.queenCovered, isFalse);
      expect(eval.queenPocketed, isFalse);
      expect(eval.continuesTurn, isFalse, reason: 'Turn passes');
    });

    test('16. Cover shot with Pending Due: Pocketing 1 coin on cover shot with 1 Due pays Due, Queen returned (insufficient cover), turn passes', () {
      final pieces = createStandardBoard();
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      whitePiece.isPocketed = true;
      queenPiece.isPocketed = true;

      // Cover shot with 1 coin
      final turnResult = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white],
        pocketedPieces: [whitePiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: true,
        queenCovered: false,
        queenPocketedBy: PlayerColor.white,
        needsCover: true,
        allPieces: pieces,
        whitePenaltyDue: 1,
      );

      expect(eval.whitePenaltyDue, equals(0), reason: 'Due paid off');
      expect(eval.piecesToRespot, contains(whitePiece));
      expect(eval.piecesToRespot, contains(queenPiece), reason: 'Cover failed because coin went to Due');
      expect(eval.queenCovered, isFalse);
      expect(eval.continuesTurn, isFalse);
    });

    test('17. Premature multi-piece pot without Queen: Pocketing both remaining pieces at once respots all premature pieces', () {
      final pieces = createStandardBoard();
      final whitePieces = pieces.where((p) => p.type == PieceType.white).toList();

      // Pocket 7 pieces earlier
      for (int i = 0; i < 7; i++) {
        whitePieces[i].isPocketed = true;
      }

      // Pocket remaining 2 pieces in one shot (Queen still on board)
      final w8 = whitePieces[7];
      final w9 = whitePieces[8];
      w8.isPocketed = true;
      w9.isPocketed = true;

      final turnResult = TurnResult(
        pocketedOwn: true,
        piecesPocketedThisTurn: [PieceType.white, PieceType.white],
        pocketedPieces: [w8, w9],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 7,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
      );

      expect(eval.piecesToRespot, contains(w8), reason: 'Both premature pieces must be respotted');
      expect(eval.piecesToRespot, contains(w9));
      expect(eval.whiteScore, equals(7), reason: 'No premature score credited');
      expect(eval.continuesTurn, isFalse);
    });

    test('18. Simultaneous Striker + Queen + Own + Opponent pot: Queen & Own respotted, striker penalty applied, opponent credited', () {
      final pieces = createStandardBoard();
      final queenPiece = pieces.firstWhere((p) => p.type == PieceType.queen);
      final whitePiece = pieces.firstWhere((p) => p.type == PieceType.white);
      final blackPiece = pieces.firstWhere((p) => p.type == PieceType.black);
      queenPiece.isPocketed = true;
      whitePiece.isPocketed = true;
      blackPiece.isPocketed = true;

      final multiFoulResult = TurnResult(
        pocketedStriker: true,
        pocketedQueen: true,
        pocketedOwn: true,
        pocketedOpponent: true,
        piecesPocketedThisTurn: [PieceType.queen, PieceType.white, PieceType.black],
        pocketedPieces: [queenPiece, whitePiece, blackPiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: multiFoulResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 0,
        blackScore: 0,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 0,
      );

      expect(eval.piecesToRespot, contains(queenPiece), reason: 'Queen returns on foul');
      expect(eval.piecesToRespot, contains(whitePiece), reason: 'Own piece potted on foul returns');
      expect(eval.piecesToRespot, isNot(contains(blackPiece)), reason: 'Opponent piece stays pocketed');
      expect(eval.blackScore, equals(1), reason: 'Black credited for black piece');
      expect(eval.whitePenaltyDue, equals(1), reason: 'White owes 1 Due for striker scratch with 0 previous coins');
      expect(eval.continuesTurn, isFalse);
    });

    test('19. Opponent piece pocketed when opponent has a pending Penalty Due: Pays opponent due, respots coin, prevents match deadlock', () {
      final pieces = createStandardBoard();
      final blackPiece = pieces.firstWhere((p) => p.type == PieceType.black);
      blackPiece.isPocketed = true;

      // White is shooting and accidentally pots Black's piece, but Black has 1 pending due!
      final turnResult = TurnResult(
        pocketedOpponent: true,
        piecesPocketedThisTurn: [PieceType.black],
        pocketedPieces: [blackPiece],
      );

      final eval = CarromTurnEvaluator.evaluate(
        result: turnResult,
        currentPlayer: PlayerColor.white,
        whiteScore: 3,
        blackScore: 2,
        queenPocketed: false,
        queenCovered: false,
        queenPocketedBy: null,
        needsCover: false,
        allPieces: pieces,
        whitePenaltyDue: 0,
        blackPenaltyDue: 1, // Black owes 1 penalty due
      );

      expect(eval.blackPenaltyDue, equals(0), reason: 'Black due is paid by the pocketed coin');
      expect(eval.piecesToRespot, contains(blackPiece), reason: 'Black coin is respotted to serve penalty');
      expect(eval.blackScore, equals(2), reason: 'Black score does not increase because coin was used for due');
      expect(eval.continuesTurn, isFalse, reason: 'White turn passes');
    });

    test('20. Pending Penalty Dues Deadlock Safety: 0 pieces remaining on board with due respots piece and deducts score', () {
      final pieces = createStandardBoard();
      // Pocket all white pieces
      for (final p in pieces.where((p) => p.type == PieceType.white)) {
        p.isPocketed = true;
      }

      int whitePenaltyDue = 1;
      int whiteScore = 8;
      const bool queenCovered = true;

      int whiteLeft = pieces.where((p) => p.type == PieceType.white && !p.isPocketed).length;
      expect(whiteLeft, equals(0));

      // Emulate the game_screen win condition deadlock safety
      if (whiteLeft == 0 && whitePenaltyDue > 0) {
        final pocketedWhite = pieces.firstWhere(
          (p) => p.type == PieceType.white && p.isPocketed,
          orElse: () => PieceModel(id: -1, type: PieceType.white, position: Vector2.zero, radius: 0, mass: 0),
        );
        if (pocketedWhite.id != -1) {
          whitePenaltyDue--;
          whiteScore = math.max(0, whiteScore - 1);
          CarromRespotter.respotPiece(pocketedWhite, pieces);
          whiteLeft = 1;
        }
      }

      // Assertions
      expect(whitePenaltyDue, equals(0), reason: 'Penalty due cleared');
      expect(whiteScore, equals(7), reason: 'Score adjusted for respotted penalty piece');
      expect(whiteLeft, equals(1), reason: 'White now has 1 piece on board, preventing game deadlock');
      final whiteOnBoard = pieces.where((p) => p.type == PieceType.white && !p.isPocketed).length;
      expect(whiteOnBoard, equals(1));
      expect(queenCovered, isTrue);
    });
  });
}

