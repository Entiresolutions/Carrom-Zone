import 'dart:math' as math;
import 'game_config.dart';
import 'vector2.dart';
import '../models/game_mode.dart';
import '../models/piece_model.dart';
import '../models/turn_result.dart';

class CarromRespotter {
  /// Deterministically finds the nearest non-overlapping position around the center circle.
  static Vector2 findDeterministicRespotPosition(List<PieceModel> allPieces) {
    const double minClearance = GameConfig.pieceRadius * 2.0; // 24.0
    const Vector2 center = GameConfig.queenInitialPos; // (0, 0)

    bool isPositionClear(Vector2 pos) {
      // Must stay inside playable board boundaries
      const double maxCoord = GameConfig.halfBoard - GameConfig.pieceRadius - 8.0;
      if (pos.x.abs() > maxCoord || pos.y.abs() > maxCoord) {
        return false;
      }
      // Must not be inside pocket capture zones
      for (final pocket in GameConfig.pockets) {
        if (pos.distanceTo(pocket) < GameConfig.pocketRadius + GameConfig.pieceRadius + 6.0) {
          return false;
        }
      }
      for (final p in allPieces) {
        if (!p.isPocketed && p.position.distanceTo(pos) < minClearance - 0.5) {
          return false;
        }
      }
      return true;
    }

    // 1. Try exact center first
    if (isPositionClear(center)) {
      return center;
    }

    // 2. Search outwards in concentric rings from 25.0 up to boundary
    // Primary cardinal & diagonal angles
    const List<double> primaryAngles = [
      -math.pi / 2,     // Top (towards black baseline)
      math.pi / 2,      // Bottom (towards white baseline)
      0.0,              // Right
      math.pi,          // Left
      -math.pi / 4,     // Top-Right
      math.pi / 4,      // Bottom-Right
      3 * math.pi / 4,  // Bottom-Left
      -3 * math.pi / 4, // Top-Left
    ];

    for (double r = 25.0; r <= GameConfig.halfBoard - 30.0; r += 5.0) {
      // Check primary angles first for deterministic backwards compatibility
      for (final a in primaryAngles) {
        final pos = Vector2(r * math.cos(a), r * math.sin(a));
        if (isPositionClear(pos)) {
          return pos;
        }
      }
      // Check intermediate 16 angles (22.5 deg intervals)
      for (double a = 0.0; a < 2.0 * math.pi; a += math.pi / 8.0) {
        final pos = Vector2(r * math.cos(a), r * math.sin(a));
        if (isPositionClear(pos)) {
          return pos;
        }
      }
    }

    // 3. Robust dynamic fallback: Find position with maximum clearance from all active pieces
    double bestDistance = -1.0;
    Vector2 bestPos = const Vector2(0.0, 26.0);
    for (double x = -80.0; x <= 80.0; x += 10.0) {
      for (double y = -80.0; y <= 80.0; y += 10.0) {
        final pos = Vector2(x, y);
        double minD = double.infinity;
        for (final p in allPieces) {
          if (!p.isPocketed) {
            minD = math.min(minD, p.position.distanceTo(pos));
          }
        }
        if (minD > bestDistance) {
          bestDistance = minD;
          bestPos = pos;
        }
      }
    }
    return bestPos;
  }

  /// Respot a piece on the board at a deterministic non-overlapping position.
  static void respotPiece(PieceModel piece, List<PieceModel> allPieces) {
    piece.isPocketed = false;
    piece.pocketProgress = 0.0;
    piece.pocketTarget = null;
    piece.velocity = Vector2.zero;
    piece.position = findDeterministicRespotPosition(allPieces);
  }
}

class TurnEvaluationResult {
  final int whiteScore;
  final int blackScore;
  final bool queenPocketed;
  final bool queenCovered;
  final PlayerColor? queenPocketedBy;
  final bool needsCover;
  final bool continuesTurn;
  final String toastMessage;
  final List<PieceModel> piecesToRespot;
  final int whitePenaltyDue;
  final int blackPenaltyDue;

  const TurnEvaluationResult({
    required this.whiteScore,
    required this.blackScore,
    required this.queenPocketed,
    required this.queenCovered,
    required this.queenPocketedBy,
    required this.needsCover,
    required this.continuesTurn,
    required this.toastMessage,
    required this.piecesToRespot,
    this.whitePenaltyDue = 0,
    this.blackPenaltyDue = 0,
  });
}

class MatchOutcomeEvaluation {
  final bool isMatchOver;
  final PlayerColor? winner;
  final bool isDraw;
  final CarromRuleset ruleset;
  final int whiteScore;
  final int blackScore;
  final int whiteRemaining;
  final int blackRemaining;
  final PlayerColor? firstClearedBy;
  final PlayerColor? queenCoveredBy;

  const MatchOutcomeEvaluation({
    required this.isMatchOver,
    required this.winner,
    this.isDraw = false,
    this.ruleset = CarromRuleset.classic,
    required this.whiteScore,
    required this.blackScore,
    required this.whiteRemaining,
    required this.blackRemaining,
    this.firstClearedBy,
    this.queenCoveredBy,
  });
}

class CarromTurnEvaluator {
  /// Evaluates a turn timeout (20s shot clock expiration).
  /// Passes the turn without firing a shot; if the player timed out while
  /// owing an immediate Queen cover shot, the Queen cover fails and the
  /// Queen is returned to the center of the board.
  static TurnEvaluationResult evaluateTimeout({
    required PlayerColor currentPlayer,
    required int whiteScore,
    required int blackScore,
    required bool queenPocketed,
    required bool queenCovered,
    required PlayerColor? queenPocketedBy,
    required bool needsCover,
    required List<PieceModel> allPieces,
    int whitePenaltyDue = 0,
    int blackPenaltyDue = 0,
  }) {
    final List<PieceModel> piecesToRespot = [];
    bool newQueenPocketed = queenPocketed;
    bool newQueenCovered = queenCovered;
    PlayerColor? newQueenPocketedBy = queenPocketedBy;
    bool newNeedsCover = needsCover;
    String toastMsg = '⏱️ Time\'s Up! Turn passes.';

    if (needsCover && !queenCovered && queenPocketedBy == currentPlayer) {
      final PieceModel? queenPiece = allPieces.cast<PieceModel?>().firstWhere(
            (p) => p?.type == PieceType.queen,
            orElse: () => null,
          );
      if (queenPiece != null) {
        piecesToRespot.add(queenPiece);
      }
      newQueenPocketed = false;
      newQueenCovered = false;
      newQueenPocketedBy = null;
      newNeedsCover = false;
      toastMsg = '⏱️ Time\'s Up! Queen cover failed & turn passes.';
    }

    return TurnEvaluationResult(
      whiteScore: whiteScore,
      blackScore: blackScore,
      queenPocketed: newQueenPocketed,
      queenCovered: newQueenCovered,
      queenPocketedBy: newQueenPocketedBy,
      needsCover: newNeedsCover,
      continuesTurn: false,
      toastMessage: toastMsg,
      piecesToRespot: piecesToRespot,
      whitePenaltyDue: whitePenaltyDue,
      blackPenaltyDue: blackPenaltyDue,
    );
  }

  /// Authoritative Freestyle Points Mode match completion and winner/draw evaluator.
  ///
  /// Rules:
  /// 1. Pending Queen cover or pending respot must resolve before match completion.
  /// 2. First player to legally reach [targetScore] (default 160) wins.
  /// 3. If all coins are legally cleared before reaching [targetScore],
  ///    highest valid score wins; equal scores result in a draw ([isDraw] = true).
  static MatchOutcomeEvaluation evaluateFreestyleMatchOutcome({
    required int whiteScore,
    required int blackScore,
    required bool queenCovered,
    bool needsCover = false,
    PlayerColor? queenCoveredBy,
    List<PieceModel>? allPieces,
    int? whiteRemaining,
    int? blackRemaining,
    bool hasPendingRespot = false,
    PlayerColor? clearingPlayer,
    int targetScore = GameConfig.freestyleTargetScore,
  }) {
    final int whiteLeft = whiteRemaining ??
        (allPieces != null
            ? allPieces
                .where((p) => p.type == PieceType.white && !p.isPocketed)
                .length
            : 0);
    final int blackLeft = blackRemaining ??
        (allPieces != null
            ? allPieces
                .where((p) => p.type == PieceType.black && !p.isPocketed)
                .length
            : 0);

    // Do not conclude match while a Queen cover or piece respot is still pending
    if (needsCover || hasPendingRespot) {
      return MatchOutcomeEvaluation(
        isMatchOver: false,
        winner: null,
        isDraw: false,
        ruleset: CarromRuleset.freestyle,
        whiteScore: whiteScore,
        blackScore: blackScore,
        whiteRemaining: whiteLeft,
        blackRemaining: blackLeft,
        queenCoveredBy: queenCovered ? queenCoveredBy : null,
      );
    }

    // 1. Check if either player legally reached or exceeded the target score
    if (whiteScore >= targetScore || blackScore >= targetScore) {
      if (whiteScore > blackScore) {
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: PlayerColor.white,
          isDraw: false,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: whiteLeft,
          blackRemaining: blackLeft,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      } else if (blackScore > whiteScore) {
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: PlayerColor.black,
          isDraw: false,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: whiteLeft,
          blackRemaining: blackLeft,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      } else {
        // Equal scores at/above target: active shooter who reached target wins, or draw
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: clearingPlayer,
          isDraw: clearingPlayer == null,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: whiteLeft,
          blackRemaining: blackLeft,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      }
    }

    // 2. Check if all board coins (White, Black, and Queen) have been cleared
    final PieceModel? queenPiece = allPieces?.cast<PieceModel?>().firstWhere(
          (p) => p?.type == PieceType.queen,
          orElse: () => null,
        );
    final bool queenStillOnBoard =
        queenPiece != null && !queenPiece.isPocketed;
    final bool queenResolved =
        (queenCovered && !needsCover && !queenStillOnBoard) ||
            (queenPiece == null && !needsCover);

    if (whiteLeft == 0 && blackLeft == 0 && queenResolved) {
      if (whiteScore > blackScore) {
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: PlayerColor.white,
          isDraw: false,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: 0,
          blackRemaining: 0,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      } else if (blackScore > whiteScore) {
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: PlayerColor.black,
          isDraw: false,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: 0,
          blackRemaining: 0,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      } else {
        // Equal scores when all coins are cleared -> Draw!
        return MatchOutcomeEvaluation(
          isMatchOver: true,
          winner: null,
          isDraw: true,
          ruleset: CarromRuleset.freestyle,
          whiteScore: whiteScore,
          blackScore: blackScore,
          whiteRemaining: 0,
          blackRemaining: 0,
          queenCoveredBy: queenCovered ? queenCoveredBy : null,
        );
      }
    }

    return MatchOutcomeEvaluation(
      isMatchOver: false,
      winner: null,
      isDraw: false,
      ruleset: CarromRuleset.freestyle,
      whiteScore: whiteScore,
      blackScore: blackScore,
      whiteRemaining: whiteLeft,
      blackRemaining: blackLeft,
      queenCoveredBy: queenCovered ? queenCoveredBy : null,
    );
  }

  /// Authoritative Points-Based Casual Match completion and winner evaluator.
  ///
  /// Rules:
  /// 1. A player clearing all 9 pieces triggers match-completion evaluation,
  ///    but does NOT automatically win.
  /// 2. Before concluding, Queen status, fouls, pending penalty dues, and
  ///    respotting must be fully resolved.
  /// 3. Once match completion is valid:
  ///    - Higher authoritative final score wins.
  ///    - If scores tie, the player who first legally cleared all 9 pieces wins.
  ///    - The Queen +3 bonus belongs only to its legal coverer.
  ///    - Never duplicate or inflate scores.
  static MatchOutcomeEvaluation evaluateMatchOutcome({
    required int whiteScore,
    required int blackScore,
    required bool queenCovered,
    bool needsCover = false,
    PlayerColor? queenCoveredBy,
    List<PieceModel>? allPieces,
    int? whiteRemaining,
    int? blackRemaining,
    int whitePenaltyDue = 0,
    int blackPenaltyDue = 0,
    bool hasPendingRespot = false,
    PlayerColor? firstClearedBy,
    PlayerColor? clearingPlayer,
    TurnResult? turnResult,
    List<PieceModel>? respotPieces,
    CarromRuleset ruleset = CarromRuleset.classic,
    int targetScore = GameConfig.freestyleTargetScore,
  }) {
    if (ruleset == CarromRuleset.freestyle) {
      return evaluateFreestyleMatchOutcome(
        whiteScore: whiteScore,
        blackScore: blackScore,
        queenCovered: queenCovered,
        needsCover: needsCover,
        queenCoveredBy: queenCoveredBy,
        allPieces: allPieces,
        whiteRemaining: whiteRemaining,
        blackRemaining: blackRemaining,
        hasPendingRespot: hasPendingRespot,
        clearingPlayer: clearingPlayer,
        targetScore: targetScore,
      );
    }
    final int whiteLeft = whiteRemaining ??
        (allPieces != null
            ? allPieces
                .where((p) => p.type == PieceType.white && !p.isPocketed)
                .length
            : 0);
    final int blackLeft = blackRemaining ??
        (allPieces != null
            ? allPieces
                .where((p) => p.type == PieceType.black && !p.isPocketed)
                .length
            : 0);

    final PieceModel? queenPiece = allPieces?.cast<PieceModel?>().firstWhere(
          (p) => p?.type == PieceType.queen,
          orElse: () => null,
        );
    final bool queenStillOnBoard =
        queenPiece != null && !queenPiece.isPocketed;

    // Queen is resolved only when legally pocketed and covered, with no pending cover shot.
    final bool queenResolved =
        queenCovered && !needsCover && !queenStillOnBoard;

    final bool whiteClearedLegally = whiteLeft == 0 &&
        whitePenaltyDue == 0 &&
        queenResolved &&
        !hasPendingRespot;
    final bool blackClearedLegally = blackLeft == 0 &&
        blackPenaltyDue == 0 &&
        queenResolved &&
        !hasPendingRespot;

    if (!whiteClearedLegally && !blackClearedLegally) {
      return MatchOutcomeEvaluation(
        isMatchOver: false,
        winner: null,
        whiteScore: whiteScore,
        blackScore: blackScore,
        whiteRemaining: whiteLeft,
        blackRemaining: blackLeft,
        firstClearedBy: null,
        queenCoveredBy: queenCovered ? queenCoveredBy : null,
      );
    }

    // Validate any prior firstClearedBy: it remains valid only if that player's clearance is currently legal.
    final PlayerColor? validatedPriorFirstCleared =
        (firstClearedBy == PlayerColor.white && whiteClearedLegally) ||
                (firstClearedBy == PlayerColor.black && blackClearedLegally)
            ? firstClearedBy
            : null;

    final PlayerColor? resolvedFirstCleared;
    if (whiteClearedLegally && !blackClearedLegally) {
      // Legal piece ownership: White's 9 pieces are cleared (even if last piece was pocketed by Black)
      resolvedFirstCleared = PlayerColor.white;
    } else if (blackClearedLegally && !whiteClearedLegally) {
      // Legal piece ownership: Black's 9 pieces are cleared (even if last piece was pocketed by White)
      resolvedFirstCleared = PlayerColor.black;
    } else if (validatedPriorFirstCleared != null) {
      resolvedFirstCleared = validatedPriorFirstCleared;
    } else {
      // Simultaneous White & Black clearance on the same turn:
      // Fair, deterministic tie policy without arbitrary color bias:
      // 1. Chronological pocket order of each color's final (9th) non-respotted piece
      // 2. Royal cover merit (queenCoveredBy)
      // 3. Active clearing shooter (clearingPlayer)
      PlayerColor? chronologicalFirst;
      if (turnResult != null) {
        if (turnResult.pocketedPieces.isNotEmpty) {
          int lastWhiteIdx = -1;
          int lastBlackIdx = -1;
          for (int i = 0; i < turnResult.pocketedPieces.length; i++) {
            final p = turnResult.pocketedPieces[i];
            if (respotPieces != null && respotPieces.contains(p)) continue;
            if (p.type == PieceType.white) {
              lastWhiteIdx = i;
            } else if (p.type == PieceType.black) {
              lastBlackIdx = i;
            }
          }
          if (lastWhiteIdx != -1 && lastBlackIdx != -1) {
            chronologicalFirst = lastWhiteIdx < lastBlackIdx
                ? PlayerColor.white
                : PlayerColor.black;
          } else if (lastWhiteIdx != -1 && lastBlackIdx == -1) {
            // Black was already at 0 before this shot; White cleared on this shot
            chronologicalFirst = PlayerColor.black;
          } else if (lastBlackIdx != -1 && lastWhiteIdx == -1) {
            // White was already at 0 before this shot; Black cleared on this shot
            chronologicalFirst = PlayerColor.white;
          }
        } else if (turnResult.piecesPocketedThisTurn.isNotEmpty) {
          int lastWhiteIdx = -1;
          int lastBlackIdx = -1;
          for (int i = 0; i < turnResult.piecesPocketedThisTurn.length; i++) {
            final t = turnResult.piecesPocketedThisTurn[i];
            if (t == PieceType.white) {
              lastWhiteIdx = i;
            } else if (t == PieceType.black) {
              lastBlackIdx = i;
            }
          }
          if (lastWhiteIdx != -1 && lastBlackIdx != -1) {
            chronologicalFirst = lastWhiteIdx < lastBlackIdx
                ? PlayerColor.white
                : PlayerColor.black;
          }
        }
      }
      resolvedFirstCleared = chronologicalFirst ??
          (queenCovered ? queenCoveredBy : null) ??
          clearingPlayer;
    }

    final PlayerColor? winner;
    if (whiteScore > blackScore) {
      winner = PlayerColor.white;
    } else if (blackScore > whiteScore) {
      winner = PlayerColor.black;
    } else {
      // Tie-breaker: the player who first legally cleared all 9 pieces (or fair tie policy) wins
      winner = resolvedFirstCleared;
    }

    if (winner == null) {
      return MatchOutcomeEvaluation(
        isMatchOver: false,
        winner: null,
        whiteScore: whiteScore,
        blackScore: blackScore,
        whiteRemaining: whiteLeft,
        blackRemaining: blackLeft,
        firstClearedBy: null,
        queenCoveredBy: queenCovered ? queenCoveredBy : null,
      );
    }

    return MatchOutcomeEvaluation(
      isMatchOver: true,
      winner: winner,
      whiteScore: whiteScore,
      blackScore: blackScore,
      whiteRemaining: whiteLeft,
      blackRemaining: blackLeft,
      firstClearedBy: resolvedFirstCleared,
      queenCoveredBy: queenCovered ? queenCoveredBy : null,
    );
  }

  /// Evaluates a shot under Freestyle Points Mode (10/20/50 points, any coin for either player).
  static TurnEvaluationResult evaluateFreestyle({
    required TurnResult result,
    required PlayerColor currentPlayer,
    required int whiteScore,
    required int blackScore,
    required bool queenPocketed,
    required bool queenCovered,
    required PlayerColor? queenPocketedBy,
    required bool needsCover,
    required List<PieceModel> allPieces,
    int whiteCoinPoints = GameConfig.freestyleWhitePoints,
    int blackCoinPoints = GameConfig.freestyleBlackPoints,
    int queenPoints = GameConfig.freestyleQueenPoints,
    int foulPenalty = GameConfig.freestyleFoulPenalty,
  }) {
    final PieceModel? queenPiece = allPieces.cast<PieceModel?>().firstWhere(
          (p) => p?.type == PieceType.queen,
          orElse: () => null,
        );

    int newWhiteScore = whiteScore;
    int newBlackScore = blackScore;
    bool newQueenPocketed = queenPocketed;
    bool newQueenCovered = queenCovered;
    PlayerColor? newQueenPocketedBy = queenPocketedBy;
    bool newNeedsCover = needsCover;
    bool continuesTurn = false;
    String toastMsg = '';
    final List<PieceModel> piecesToRespot = [];

    void queueRespot(PieceModel piece) {
      if (!piecesToRespot.contains(piece)) {
        piecesToRespot.add(piece);
      }
    }

    void addScore(PlayerColor player, int points) {
      if (player == PlayerColor.white) {
        newWhiteScore += points;
      } else {
        newBlackScore += points;
      }
    }

    void deductScore(PlayerColor player, int points) {
      if (player == PlayerColor.white) {
        newWhiteScore = math.max(0, newWhiteScore - points);
      } else {
        newBlackScore = math.max(0, newBlackScore - points);
      }
    }

    final int whitePocketedCount = result.piecesPocketedThisTurn
        .where((t) => t == PieceType.white)
        .length;
    final int blackPocketedCount = result.piecesPocketedThisTurn
        .where((t) => t == PieceType.black)
        .length;
    final int normalPocketedCount = whitePocketedCount + blackPocketedCount;
    final int normalPointsThisShot = (whitePocketedCount * whiteCoinPoints) +
        (blackPocketedCount * blackCoinPoints);

    final List<PieceModel> normalPottedThisShot = result.pocketedPieces
        .where((p) => p.type == PieceType.white || p.type == PieceType.black)
        .toList();

    int countNormalRemainingOnBoard() => allPieces
        .where((p) =>
            (p.type == PieceType.white || p.type == PieceType.black) &&
            (!p.isPocketed || piecesToRespot.contains(p)))
        .length;

    // --- 1. STRIKER FOUL (Rollback shot & apply foul penalty) ---
    if (result.pocketedStriker) {
      continuesTurn = false;

      if (result.pocketedQueen ||
          (needsCover && queenPocketedBy == currentPlayer)) {
        if (queenPiece != null) {
          queueRespot(queenPiece);
        }
        newQueenPocketed = false;
        newQueenCovered = false;
        newQueenPocketedBy = null;
        newNeedsCover = false;
      }

      // Rollback all normal coins potted on this foul shot (0 pts awarded, returned to board)
      if (normalPottedThisShot.isNotEmpty) {
        for (final p in normalPottedThisShot) {
          queueRespot(p);
        }
      } else if (normalPocketedCount > 0) {
        int remainingToRollback = normalPocketedCount;
        for (final p in allPieces) {
          if (remainingToRollback <= 0) break;
          if ((p.type == PieceType.white || p.type == PieceType.black) &&
              p.isPocketed &&
              !piecesToRespot.contains(p)) {
            queueRespot(p);
            remainingToRollback--;
          }
        }
      }

      // Apply configurable point penalty (default -10, floored at 0)
      deductScore(currentPlayer, foulPenalty);

      // Return 1 previously pocketed normal coin (preferring 10-pt White coin) to board if available
      final PieceModel previouslyPocketed = allPieces.firstWhere(
        (p) =>
            p.type == PieceType.white &&
            p.isPocketed &&
            !result.pocketedPieces.contains(p) &&
            !piecesToRespot.contains(p),
        orElse: () => allPieces.firstWhere(
          (p) =>
              p.type == PieceType.black &&
              p.isPocketed &&
              !result.pocketedPieces.contains(p) &&
              !piecesToRespot.contains(p),
          orElse: () => PieceModel(
            id: -1,
            type: PieceType.white,
            position: Vector2.zero,
            radius: 0,
            mass: 0,
          ),
        ),
      );
      if (previouslyPocketed.id != -1) {
        queueRespot(previouslyPocketed);
      }

      toastMsg = '⚠️ Striker Foul! -$foulPenalty pts • Turn passes.';

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: false,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
      );
    }

    // --- 2. QUEEN POCKETED THIS SHOT (No striker foul) ---
    if (result.pocketedQueen && !queenCovered && !needsCover) {
      if (normalPocketedCount > 0) {
        // Same-shot cover with any normal coin (White or Black)!
        newQueenPocketed = true;
        newQueenCovered = true;
        newQueenPocketedBy = currentPlayer;
        newNeedsCover = false;

        final int totalEarned = queenPoints + normalPointsThisShot;
        addScore(currentPlayer, totalEarned);
        continuesTurn = true;
        toastMsg = '👑 Queen Covered! +$totalEarned Points 🎉';
      } else {
        // Queen pocketed alone: verify at least 1 normal coin remains on board to cover with
        final int normalRemaining = countNormalRemainingOnBoard();
        final bool boardHasNormalCoins = allPieces
            .any((p) => p.type == PieceType.white || p.type == PieceType.black);
        if (boardHasNormalCoins && normalRemaining == 0) {
          // Deadlock prevention: no normal coin left on board to cover Queen
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenCovered = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;
          continuesTurn = false;
          toastMsg = '⚠️ No coin left to cover Queen! Queen returns to center.';
        } else {
          newQueenPocketed = true;
          newQueenPocketedBy = currentPlayer;
          newNeedsCover = true;
          continuesTurn = true;
          toastMsg = '👑 Queen Pocketed! Cover with any coin next shot.';
        }
      }

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: continuesTurn,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
      );
    }

    // --- 3. QUEEN COVER SHOT (Needs cover from previous shot, no striker foul) ---
    if (needsCover && !queenCovered && queenPocketedBy == currentPlayer) {
      if (normalPocketedCount > 0) {
        // Cover succeeded with any normal coin!
        newQueenCovered = true;
        newQueenPocketed = true;
        newNeedsCover = false;

        final int totalEarned = queenPoints + normalPointsThisShot;
        addScore(currentPlayer, totalEarned);
        continuesTurn = true;
        toastMsg = '👑 Queen Covered! +$totalEarned Points 🎉';
      } else {
        // Cover failed: return Queen to board without awarding 50 points
        if (queenPiece != null) {
          queueRespot(queenPiece);
        }
        newQueenPocketed = false;
        newQueenCovered = false;
        newQueenPocketedBy = null;
        newNeedsCover = false;
        continuesTurn = false;
        toastMsg = '❌ Failed to cover! Queen returns to center.';
      }

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: continuesTurn,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
      );
    }

    // --- 4. NORMAL COINS SHOT (White = 10 pts, Black = 20 pts) ---
    if (normalPocketedCount > 0) {
      final int normalRemaining = countNormalRemainingOnBoard();
      final bool hasUncoveredQueen = !newQueenCovered &&
          ((queenPiece != null && !queenPiece.isPocketed) ||
              newQueenPocketed ||
              newNeedsCover);

      if (normalRemaining == 0 && hasUncoveredQueen) {
        // Deadlock prevention: cannot clear the final normal coin(s) while Queen is still uncovered
        if (normalPottedThisShot.isNotEmpty) {
          for (final p in normalPottedThisShot) {
            queueRespot(p);
          }
        } else {
          final PieceModel fallbackNormal = allPieces.firstWhere(
            (p) =>
                (p.type == PieceType.white || p.type == PieceType.black) &&
                p.isPocketed,
            orElse: () => PieceModel(
              id: -1,
              type: PieceType.white,
              position: Vector2.zero,
              radius: 0,
              mass: 0,
            ),
          );
          if (fallbackNormal.id != -1) {
            queueRespot(fallbackNormal);
          }
        }
        continuesTurn = false;
        toastMsg = '⚠️ Queen must be pocketed before the last coin!';
      } else {
        addScore(currentPlayer, normalPointsThisShot);
        continuesTurn = true;
        toastMsg = '🎯 +$normalPointsThisShot Points! Continue Turn.';
      }
    } else {
      continuesTurn = false;
      toastMsg = '';
    }

    return TurnEvaluationResult(
      whiteScore: newWhiteScore,
      blackScore: newBlackScore,
      queenPocketed: newQueenPocketed,
      queenCovered: newQueenCovered,
      queenPocketedBy: newQueenPocketedBy,
      needsCover: newNeedsCover,
      continuesTurn: continuesTurn,
      toastMessage: toastMsg,
      piecesToRespot: piecesToRespot,
    );
  }

  static TurnEvaluationResult evaluate({
    required TurnResult result,
    required PlayerColor currentPlayer,
    required int whiteScore,
    required int blackScore,
    required bool queenPocketed,
    required bool queenCovered,
    required PlayerColor? queenPocketedBy,
    required bool needsCover,
    required List<PieceModel> allPieces,
    int whitePenaltyDue = 0,
    int blackPenaltyDue = 0,
    CarromRuleset ruleset = CarromRuleset.classic,
  }) {
    if (ruleset == CarromRuleset.freestyle) {
      return evaluateFreestyle(
        result: result,
        currentPlayer: currentPlayer,
        whiteScore: whiteScore,
        blackScore: blackScore,
        queenPocketed: queenPocketed,
        queenCovered: queenCovered,
        queenPocketedBy: queenPocketedBy,
        needsCover: needsCover,
        allPieces: allPieces,
      );
    }
    final PieceType myType =
        currentPlayer == PlayerColor.white ? PieceType.white : PieceType.black;
    final PieceType oppType =
        currentPlayer == PlayerColor.white ? PieceType.black : PieceType.white;

    final PieceModel? queenPiece = allPieces.cast<PieceModel?>().firstWhere(
      (p) => p?.type == PieceType.queen,
      orElse: () => null,
    );

    int newWhiteScore = whiteScore;
    int newBlackScore = blackScore;
    int newWhitePenaltyDue = whitePenaltyDue;
    int newBlackPenaltyDue = blackPenaltyDue;
    bool newQueenPocketed = queenPocketed;
    bool newQueenCovered = queenCovered;
    PlayerColor? newQueenPocketedBy = queenPocketedBy;
    bool newNeedsCover = needsCover;
    bool continuesTurn = false;
    String toastMsg = '';
    final List<PieceModel> piecesToRespot = [];

    void queueRespot(PieceModel piece) {
      if (!piecesToRespot.contains(piece)) {
        piecesToRespot.add(piece);
      }
    }

    final ownPocketedCount =
        result.piecesPocketedThisTurn.where((t) => t == myType).length;
    final oppPocketedCount =
        result.piecesPocketedThisTurn.where((t) => t == oppType).length;
    final ownPottedThisShot =
        result.pocketedPieces.where((p) => p.type == myType).toList();

    void addScore(PlayerColor player, int points) {
      if (player == PlayerColor.white) {
        newWhiteScore += points;
      } else {
        newBlackScore += points;
      }
    }

    void deductScore(PlayerColor player, int points) {
      if (player == PlayerColor.white) {
        newWhiteScore = math.max(0, newWhiteScore - points);
      } else {
        newBlackScore = math.max(0, newBlackScore - points);
      }
    }

    int getPlayerDue(PlayerColor player) =>
        player == PlayerColor.white ? newWhitePenaltyDue : newBlackPenaltyDue;

    void incrementPlayerDue(PlayerColor player) {
      if (player == PlayerColor.white) {
        newWhitePenaltyDue++;
      } else {
        newBlackPenaltyDue++;
      }
    }

    void decrementPlayerDue(PlayerColor player, int amount) {
      if (player == PlayerColor.white) {
        newWhitePenaltyDue = math.max(0, newWhitePenaltyDue - amount);
      } else {
        newBlackPenaltyDue = math.max(0, newBlackPenaltyDue - amount);
      }
    }

    final PlayerColor opponent =
        currentPlayer == PlayerColor.white ? PlayerColor.black : PlayerColor.white;

    bool hasUnresolvedQueenOnBoard() =>
        !newQueenCovered &&
        (queenPiece != null || newQueenPocketed || newNeedsCover);

    void creditOpponent(int count) {
      if (count <= 0) return;
      final oppPotted =
          result.pocketedPieces.where((p) => p.type == oppType).toList();
      final int oppDue = getPlayerDue(opponent);
      int dueToPay = 0;
      if (oppDue > 0) {
        dueToPay = math.min(oppDue, count);
        for (int i = 0; i < dueToPay && i < oppPotted.length; i++) {
          queueRespot(oppPotted[i]);
        }
        decrementPlayerDue(opponent, dueToPay);
      }

      final int netScored = count - dueToPay;
      if (netScored > 0) {
        final int oppRemainingOnBoard = allPieces
            .where((p) =>
                p.type == oppType &&
                (!p.isPocketed || piecesToRespot.contains(p)))
            .length;
        if (oppRemainingOnBoard == 0 &&
            hasUnresolvedQueenOnBoard() &&
            allPieces.any((p) => p.type == oppType)) {
          // Prevent premature clearing of opponent's last piece before Queen is covered
          for (int i = dueToPay; i < oppPotted.length; i++) {
            queueRespot(oppPotted[i]);
          }
        } else {
          addScore(opponent, netScored);
        }
      }
    }

    // --- 1. FOUL HANDLING (Striker in pocket) ---
    if (result.pocketedStriker) {
      continuesTurn = false;

      // If Queen was pocketed on this foul shot, it cannot count and returns to center
      if (result.pocketedQueen) {
        if (queenPiece != null) {
          queueRespot(queenPiece);
        }
        newQueenPocketed = false;
        newQueenCovered = false;
        newQueenPocketedBy = null;
        newNeedsCover = false;
      } else if (needsCover && queenPocketedBy == currentPlayer) {
        // If player was trying to cover queen and fouled, cover fails
        if (queenPiece != null) {
          queueRespot(queenPiece);
        }
        newQueenPocketed = false;
        newQueenCovered = false;
        newQueenPocketedBy = null;
        newNeedsCover = false;
      }

      // Any own piece pocketed on this foul shot was potted illegally: respot it
      for (final p in ownPottedThisShot) {
        queueRespot(p);
      }

      // Opponent pieces pocketed on this foul shot stay pocketed (or pay opponent due)
      if (oppPocketedCount > 0) {
        creditOpponent(oppPocketedCount);
      }

      // Foul penalty piece: return 1 previously pocketed piece if available
      final previouslyPocketed = allPieces.firstWhere(
        (p) =>
            p.type == myType &&
            p.isPocketed &&
            !result.pocketedPieces.contains(p) &&
            !piecesToRespot.contains(p),
        orElse: () => PieceModel(id: -1, type: myType, position: Vector2.zero, radius: 0, mass: 0),
      );

      if (previouslyPocketed.id != -1) {
        queueRespot(previouslyPocketed);
        deductScore(currentPlayer, 1);
        toastMsg = '⚠️ Foul! Striker Pocketed (-1 Penalty Piece)';
      } else {
        // Player has no previously pocketed pieces to return: register a Penalty Due
        incrementPlayerDue(currentPlayer);
        deductScore(currentPlayer, 1);
        toastMsg = '⚠️ Foul! Striker Pocketed (1 Penalty Due)';
      }

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: false,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
        whitePenaltyDue: newWhitePenaltyDue,
        blackPenaltyDue: newBlackPenaltyDue,
      );
    }

    // --- 2. QUEEN POCKETED THIS TURN (No striker foul) ---
    if (result.pocketedQueen && !queenCovered && !needsCover) {
      final int currentDue = getPlayerDue(currentPlayer);

      if (currentDue > 0) {
        // If player owes a Due, they cannot cover Queen on this strike.
        // Potted own coin pays the Due, Queen returns to center.
        if (ownPocketedCount > 0) {
          final int dueToPay = math.min(currentDue, ownPocketedCount);
          for (int i = 0; i < dueToPay && i < ownPottedThisShot.length; i++) {
            queueRespot(ownPottedThisShot[i]);
          }
          decrementPlayerDue(currentPlayer, dueToPay);
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;
          final int netOwn = ownPocketedCount - dueToPay;
          if (netOwn > 0) {
            addScore(currentPlayer, netOwn);
          }
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '⚠️ Penalty Due Paid! Queen returns to center.';
        } else {
          // Queen pocketed alone with outstanding Due: Queen returned
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '❌ Outstanding Penalty Due! Queen returns to center.';
        }
      } else if (ownPocketedCount > 0) {
        // Same-shot cover!
        newQueenCovered = true;
        newQueenPocketed = true;
        newQueenPocketedBy = currentPlayer;
        newNeedsCover = false;

        // +3 for Queen + own pocketed pieces
        addScore(currentPlayer, 3 + ownPocketedCount);
        if (oppPocketedCount > 0) {
          creditOpponent(oppPocketedCount);
          continuesTurn = false;
          toastMsg = '👑 Queen Covered! Opponent piece pocketed, turn passes.';
        } else {
          continuesTurn = true;
          toastMsg = '👑 Queen Covered! +${3 + ownPocketedCount} Points 🎉';
        }
      } else {
        // Queen pocketed with 0 own pieces
        if (oppPocketedCount > 0) {
          // Pocketed Queen + Opponent piece: Queen returns to center, opponent gets point, turn passes
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;
          creditOpponent(oppPocketedCount);
          continuesTurn = false;
          toastMsg = '❌ Queen returned! Opponent piece pocketed, turn passes.';
        } else {
          // Queen pocketed cleanly alone: needs cover next shot
          newQueenPocketed = true;
          newQueenPocketedBy = currentPlayer;
          newNeedsCover = true;
          continuesTurn = true;
          toastMsg = '👑 Queen Pocketed! Cover with next shot.';
        }
      }

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: continuesTurn,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
        whitePenaltyDue: newWhitePenaltyDue,
        blackPenaltyDue: newBlackPenaltyDue,
      );
    }

    // --- 3. COVER SHOT (Needs cover from previous shot, No striker foul) ---
    if (needsCover && !queenCovered && queenPocketedBy == currentPlayer) {
      final int currentDue = getPlayerDue(currentPlayer);

      if (currentDue > 0) {
        // Player has an outstanding Due on the cover shot
        if (ownPocketedCount > currentDue) {
          // First coin(s) pay the Due, remaining coin(s) cover the Queen!
          for (int i = 0; i < currentDue && i < ownPottedThisShot.length; i++) {
            queueRespot(ownPottedThisShot[i]);
          }
          decrementPlayerDue(currentPlayer, currentDue);
          newQueenCovered = true;
          newNeedsCover = false;

          final netOwn = ownPocketedCount - currentDue;
          addScore(currentPlayer, 3 + netOwn);
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
            continuesTurn = false;
            toastMsg = '👑 Queen Covered! ($currentDue Due Paid) Turn passes.';
          } else {
            continuesTurn = true;
            toastMsg = '👑 Queen Covered! +${3 + netOwn} Points ($currentDue Due Paid) 🎉';
          }
        } else if (ownPocketedCount > 0) {
          // All pocketed own coins go to pay the Due, so Queen cover fails
          final int dueToPay = math.min(currentDue, ownPocketedCount);
          for (int i = 0; i < dueToPay && i < ownPottedThisShot.length; i++) {
            queueRespot(ownPottedThisShot[i]);
          }
          decrementPlayerDue(currentPlayer, dueToPay);
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;

          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '⚠️ Due Paid! Insufficient cover, Queen returns to center.';
        } else {
          // 0 own pieces: cover failed
          if (queenPiece != null) {
            queueRespot(queenPiece);
          }
          newQueenPocketed = false;
          newQueenPocketedBy = null;
          newNeedsCover = false;

          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '❌ Failed to cover! Queen returns to center.';
        }
      } else if (ownPocketedCount > 0) {
        // Cover successful without Due!
        newQueenCovered = true;
        newNeedsCover = false;

        addScore(currentPlayer, 3 + ownPocketedCount);
        if (oppPocketedCount > 0) {
          creditOpponent(oppPocketedCount);
          continuesTurn = false;
          toastMsg = '👑 Queen Covered! Opponent piece pocketed, turn passes.';
        } else {
          continuesTurn = true;
          toastMsg = '👑 Queen Covered! +${3 + ownPocketedCount} Points 🎉';
        }
      } else {
        // Cover failed!
        if (queenPiece != null) {
          queueRespot(queenPiece);
        }
        newQueenPocketed = false;
        newQueenPocketedBy = null;
        newNeedsCover = false;

        if (oppPocketedCount > 0) {
          creditOpponent(oppPocketedCount);
        }
        continuesTurn = false;
        toastMsg = '❌ Failed to cover! Queen returns to center.';
      }

      return TurnEvaluationResult(
        whiteScore: newWhiteScore,
        blackScore: newBlackScore,
        queenPocketed: newQueenPocketed,
        queenCovered: newQueenCovered,
        queenPocketedBy: newQueenPocketedBy,
        needsCover: newNeedsCover,
        continuesTurn: continuesTurn,
        toastMessage: toastMsg,
        piecesToRespot: piecesToRespot,
        whitePenaltyDue: newWhitePenaltyDue,
        blackPenaltyDue: newBlackPenaltyDue,
      );
    }

    // --- 4. NORMAL COINS SHOT ---
    if (ownPocketedCount > 0) {
      final int currentDue = getPlayerDue(currentPlayer);

      if (currentDue > 0) {
        // Player owes a penalty due: pay off using newly pocketed coins
        final int dueToPay = math.min(currentDue, ownPocketedCount);
        for (int i = 0; i < dueToPay; i++) {
          queueRespot(ownPottedThisShot[i]);
        }
        decrementPlayerDue(currentPlayer, dueToPay);

        final int netOwnScored = ownPocketedCount - dueToPay;
        if (netOwnScored > 0) {
          addScore(currentPlayer, netOwnScored);
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
            continuesTurn = false;
            toastMsg = '🎯 +$netOwnScored Points ($dueToPay Due Paid)! Turn passes.';
          } else {
            continuesTurn = true;
            toastMsg = '🎯 +$netOwnScored Points ($dueToPay Due Paid)! Continue Turn.';
          }
        } else {
          // All pocketed coins went to pay the Due
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '⚠️ Penalty Due Paid! Coin returned to center.';
        }
      } else {
        // Check Premature Last Piece: if own pieces on board reached 0, but Queen is not covered
        final int ownRemaining = allPieces
            .where((p) => p.type == myType && !p.isPocketed)
            .length;

        if (ownRemaining == 0 && hasUnresolvedQueenOnBoard()) {
          // Premature last piece! Respot all own pieces potted on this premature shot
          for (final p in ownPottedThisShot) {
            queueRespot(p);
          }
          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
          }
          continuesTurn = false;
          toastMsg = '⚠️ Queen must be pocketed before last piece!';
        } else {
          addScore(currentPlayer, ownPocketedCount);

          if (oppPocketedCount > 0) {
            creditOpponent(oppPocketedCount);
            continuesTurn = false;
            toastMsg = '🎯 +$ownPocketedCount Points! Opponent piece pocketed, turn passes.';
          } else {
            continuesTurn = true;
            toastMsg = '🎯 +$ownPocketedCount Points! Continue Turn.';
          }
        }
      }
    } else if (oppPocketedCount > 0) {
      creditOpponent(oppPocketedCount);
      continuesTurn = false;
      toastMsg = 'Opponent piece pocketed! Turn passes.';
    } else {
      // Missed everything
      continuesTurn = false;
      toastMsg = '';
    }

    return TurnEvaluationResult(
      whiteScore: newWhiteScore,
      blackScore: newBlackScore,
      queenPocketed: newQueenPocketed,
      queenCovered: newQueenCovered,
      queenPocketedBy: newQueenPocketedBy,
      needsCover: newNeedsCover,
      continuesTurn: continuesTurn,
      toastMessage: toastMsg,
      piecesToRespot: piecesToRespot,
      whitePenaltyDue: newWhitePenaltyDue,
      blackPenaltyDue: newBlackPenaltyDue,
    );
  }
}

