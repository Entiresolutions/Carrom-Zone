import 'dart:math' as math;
import '../core/vector2.dart';
import '../core/game_config.dart';
import '../models/piece_model.dart';
import '../models/game_mode.dart';
import '../models/turn_result.dart';
import '../core/carrom_rule_engine.dart';
import '../physics/carrom_physics.dart';

/// The calculated shot result for the AI, including trajectory, power, and prediction metadata.
class AiShotResult {
  final double strikerX;
  final double angle;
  final double power; // 0.0 to 1.0
  final bool isPredictedPot;
  final bool isBankShot;
  final double confidenceScore;

  AiShotResult({
    required this.strikerX,
    required this.angle,
    required this.power,
    this.isPredictedPot = false,
    this.isBankShot = false,
    this.confidenceScore = 0.0,
  });
}

class _CandidateShot {
  final double strikerX;
  final double angle;
  final double power;
  final PieceModel target;
  final Vector2 pocket;
  final bool isBankShot;
  final double geometricScore;

  _CandidateShot({
    required this.strikerX,
    required this.angle,
    required this.power,
    required this.target,
    required this.pocket,
    this.isBankShot = false,
    required this.geometricScore,
  });
}

class _SimulatedEvaluation {
  final _CandidateShot candidate;
  final bool strikerFouled;
  final bool targetPocketed;
  final int ownPocketed;
  final int opponentPocketed;
  final bool queenPocketed;
  final double finalTargetDistToPocket;
  final double postShotScore;

  _SimulatedEvaluation({
    required this.candidate,
    required this.strikerFouled,
    required this.targetPocketed,
    required this.ownPocketed,
    required this.opponentPocketed,
    required this.queenPocketed,
    required this.finalTargetDistToPocket,
    required this.postShotScore,
  });
}

/// Configurable profile governing candidate generation, forward simulation budget,
/// cut-angle acceptance, cushion banks, and calibrated execution variance.
class AiDifficultyConfig {
  final int maxSimulations;
  final double minCosTheta;
  final bool allowBankShots;
  final bool allowDefense;
  final double angleJitterSpread; // Full spread in radians
  final double powerMinRatio;
  final double powerMaxRatio;
  final double secondBestShotChance;
  final double minClampedPower;

  const AiDifficultyConfig({
    required this.maxSimulations,
    required this.minCosTheta,
    required this.allowBankShots,
    required this.allowDefense,
    required this.angleJitterSpread,
    required this.powerMinRatio,
    required this.powerMaxRatio,
    this.secondBestShotChance = 0.0,
    this.minClampedPower = 0.35,
  });

  static const AiDifficultyConfig easy = AiDifficultyConfig(
    maxSimulations: 2,
    minCosTheta: 0.45, // Discard steep cuts > 63.2 deg (simple direct pots only)
    allowBankShots: false, // Disallow complex trick shots
    allowDefense: false, // Beginner-friendly non-aggressive mindset
    angleJitterSpread: 0.114, // ~6.53 deg spread (natural novice variance)
    powerMinRatio: 0.82,
    powerMaxRatio: 1.12,
    secondBestShotChance: 0.35, // 35% chance to pick 2nd best viable shot
    minClampedPower: 0.30,
  );

  static const AiDifficultyConfig medium = AiDifficultyConfig(
    maxSimulations: 4,
    minCosTheta: 0.28, // Moderate cuts <= 73.7 deg
    allowBankShots: true, // 1-wall bank if direct candidates < 3
    allowDefense: true, // Moderate tactical denial
    angleJitterSpread: 0.032, // ~1.83 deg spread
    powerMinRatio: 0.94,
    powerMaxRatio: 1.06,
    secondBestShotChance: 0.10, // 10% chance to pick 2nd best viable shot
    minClampedPower: 0.35,
  );

  static const AiDifficultyConfig hard = AiDifficultyConfig(
    maxSimulations: 6,
    minCosTheta: 0.15, // Master thin cuts up to 81.3 deg
    allowBankShots: true, // Full cushion bank search
    allowDefense: true, // Aggressive tactical pocket denial
    angleJitterSpread: 0.010, // ~0.57 deg spread (tournament sharp)
    powerMinRatio: 0.98,
    powerMaxRatio: 1.02,
    secondBestShotChance: 0.0, // Always selects top simulated candidate
    minClampedPower: 0.35,
  );

  static AiDifficultyConfig forDifficulty(AiDifficulty difficulty) {
    switch (difficulty) {
      case AiDifficulty.easy:
        return easy;
      case AiDifficulty.medium:
        return medium;
      case AiDifficulty.hard:
        return hard;
    }
  }
}

/// Intelligent AI engine featuring physics-based forward simulation,
/// cushion bank shots, tactical defensive play, and strategic Queen handling.
class CarromAI {
  AiDifficulty difficulty;
  final AiDifficultyConfig? customConfig;
  final math.Random _random;

  AiDifficultyConfig get effectiveConfig =>
      customConfig ?? AiDifficultyConfig.forDifficulty(difficulty);

  // Configurable simulation step limit per candidate (75 ticks @ 60 FPS = 1.25s bounded horizon until full shot settlement)
  final int maxSimulationSteps;

  CarromAI({
    this.difficulty = AiDifficulty.medium,
    this.customConfig,
    math.Random? random,
    this.maxSimulationSteps = 75,
  }) : _random = random ?? math.Random();

  /// Calculates an intelligent, physically predicted shot without mutating the live game state.
  AiShotResult calculateShot({
    required List<PieceModel> pieces,
    required PieceModel striker,
    required PlayerColor aiColor,
    required bool needsQueenCover,
    required bool queenCovered,
    int whiteScore = 0,
    int blackScore = 0,
    bool queenPocketed = false,
    PlayerColor? queenPocketedBy,
    int whitePenaltyDue = 0,
    int blackPenaltyDue = 0,
    CarromRuleset ruleset = CarromRuleset.classic,
    int targetScore = GameConfig.freestyleTargetScore,
  }) {
    final PieceType myType =
        aiColor == PlayerColor.white ? PieceType.white : PieceType.black;
    final PieceType opponentType =
        aiColor == PlayerColor.white ? PieceType.black : PieceType.white;

    final myPieces = pieces.where((p) => p.type == myType && !p.isPocketed).toList();
    final opponentPieces =
        pieces.where((p) => p.type == opponentType && !p.isPocketed).toList();
    final normalPieces = pieces
        .where((p) =>
            (p.type == PieceType.white || p.type == PieceType.black) &&
            !p.isPocketed)
        .toList()
      ..sort((a, b) {
        // Prioritize 20-pt Black coins ahead of 10-pt White coins in Freestyle
        final int aVal = a.type == PieceType.black ? 20 : 10;
        final int bVal = b.type == PieceType.black ? 20 : 10;
        return bVal.compareTo(aVal);
      });
    final queen = pieces.firstWhere(
      (p) => p.type == PieceType.queen && !p.isPocketed,
      orElse: () => PieceModel(
        id: -1,
        type: PieceType.queen,
        position: Vector2.zero,
        radius: 0,
        mass: 0,
        isPocketed: true,
      ),
    );

    final bool queenIsCurrentlyPocketed = queenPocketed ||
        pieces.firstWhere(
          (p) => p.type == PieceType.queen,
          orElse: () => PieceModel(
            id: -1,
            type: PieceType.queen,
            position: Vector2.zero,
            radius: 0,
            mass: 0,
            isPocketed: true,
          ),
        ).isPocketed;

    final PlayerColor? activeQueenPocketedBy = queenPocketedBy ??
        (needsQueenCover ? aiColor : null);

    // 1. Queen Strategy & Eligibility Priorities
    final List<PieceModel> candidateTargets = [];

    if (ruleset == CarromRuleset.freestyle) {
      if (needsQueenCover) {
        // In Freestyle, Queen can be covered with ANY normal coin (White or Black)
        candidateTargets.addAll(normalPieces);
      } else {
        final bool queenAvailable = !queen.isPocketed && !queenCovered;
        if (queenAvailable) {
          if (normalPieces.length <= 2) {
            // Endgame safeguard: Pocket Queen before the last normal coin
            candidateTargets.insert(0, queen);
            candidateTargets.addAll(normalPieces);
          } else {
            candidateTargets.add(queen);
            candidateTargets.addAll(normalPieces);
          }
        } else {
          candidateTargets.addAll(normalPieces);
        }
      }
    } else if (needsQueenCover) {
      // Classic Cover shot: Must pocket any own coin to complete Queen reward
      candidateTargets.addAll(myPieces);
    } else {
      final bool queenAvailable = !queen.isPocketed && !queenCovered;
      if (queenAvailable) {
        if (myPieces.length <= 1) {
          // Endgame safeguard: When 1 piece remains, Queen MUST be potted first
          // to prevent premature win foul/respot
          candidateTargets.insert(0, queen);
          candidateTargets.addAll(myPieces);
        } else if (myPieces.length <= 4) {
          // Mid-game: Actively contest Queen (+3 pts)
          candidateTargets.add(queen);
          candidateTargets.addAll(myPieces);
        } else {
          // Early game: Open own pieces first, then Queen
          candidateTargets.addAll(myPieces);
          candidateTargets.add(queen);
        }
      } else {
        candidateTargets.addAll(myPieces);
      }
    }

    final double strikerY = aiColor == PlayerColor.white
        ? GameConfig.baselineYWhite
        : GameConfig.baselineYBlack;

    // Generate valid, non-overlapping baseline positions
    final List<double> candidateStrikerX = _generateBaselinePositions(strikerY, pieces);

    final config = effectiveConfig;

    // 2. Generate Direct Geometric Candidates
    final List<_CandidateShot> geometricCandidates = [];

    for (final sx in candidateStrikerX) {
      final Vector2 strikerPos = Vector2(sx, strikerY);

      for (final target in candidateTargets) {
        for (final pocket in GameConfig.pockets) {
          final directShot = _evaluateShotToPocket(
            strikerPos: strikerPos,
            target: target,
            pocket: pocket,
            allPieces: pieces,
            ruleset: ruleset,
            minCosTheta: config.minCosTheta,
          );
          if (directShot != null) {
            geometricCandidates.add(directShot);
          }
        }
      }
    }

    // 3. Generate Advanced Cushion Bank Shots (Hard & Medium difficulties)
    final bool allowBankShots = config.allowBankShots &&
        (difficulty == AiDifficulty.hard ||
            (difficulty == AiDifficulty.medium && geometricCandidates.length < 3));

    if (allowBankShots) {
      for (final sx in candidateStrikerX) {
        final Vector2 strikerPos = Vector2(sx, strikerY);

        for (final target in candidateTargets) {
          for (final pocket in GameConfig.pockets) {
            // Left cushion bank
            final leftBank = _evaluateStrikerBankShot(
              strikerPos: strikerPos,
              target: target,
              pocket: pocket,
              allPieces: pieces,
              isLeftCushion: true,
              ruleset: ruleset,
            );
            if (leftBank != null) {
              geometricCandidates.add(leftBank);
            }

            // Right cushion bank
            final rightBank = _evaluateStrikerBankShot(
              strikerPos: strikerPos,
              target: target,
              pocket: pocket,
              allPieces: pieces,
              isLeftCushion: false,
              ruleset: ruleset,
            );
            if (rightBank != null) {
              geometricCandidates.add(rightBank);
            }
          }
        }
      }
    }

    // Sort geometric candidates by heuristic score descending
    geometricCandidates.sort((a, b) => b.geometricScore.compareTo(a.geometricScore));

    // Determine simulation budget by difficulty profile
    final int budget = config.maxSimulations;

    final candidatesToSimulate = geometricCandidates.take(budget).toList();
    final List<_SimulatedEvaluation> evaluatedShots = [];

    // 4. Run Isolated Physics Simulations on Top Candidates
    for (final candidate in candidatesToSimulate) {
      final eval = _simulateCandidate(
        candidate: candidate,
        livePieces: pieces,
        liveStriker: striker,
        baselineY: strikerY,
        aiColor: aiColor,
        whiteScore: whiteScore,
        blackScore: blackScore,
        queenPocketedState: queenIsCurrentlyPocketed,
        queenCovered: queenCovered,
        queenPocketedBy: activeQueenPocketedBy,
        needsQueenCover: needsQueenCover,
        whitePenaltyDue: whitePenaltyDue,
        blackPenaltyDue: blackPenaltyDue,
        ruleset: ruleset,
        targetScore: targetScore,
      );
      evaluatedShots.add(eval);
    }

    // Sort evaluated shots by post-shot physical score descending
    evaluatedShots.sort((a, b) => b.postShotScore.compareTo(a.postShotScore));

    // 5. If a high-scoring simulated shot exists, select based on difficulty
    if (evaluatedShots.isNotEmpty && evaluatedShots.first.postShotScore > -100.0) {
      return _selectShotByDifficulty(evaluatedShots, config);
    }

    // 6. Tactical Defensive Play when offensive scoring is unpromising (Medium and Hard only)
    if (config.allowDefense) {
      final defensiveShot = _findBestDefensiveShot(
        candidateStrikerX: candidateStrikerX,
        strikerY: strikerY,
        opponentPieces: ruleset == CarromRuleset.freestyle ? normalPieces : opponentPieces,
        myPieces: ruleset == CarromRuleset.freestyle ? normalPieces : myPieces,
        allPieces: pieces,
        striker: striker,
        aiColor: aiColor,
        whiteScore: whiteScore,
        blackScore: blackScore,
        queenPocketedState: queenIsCurrentlyPocketed,
        queenCovered: queenCovered,
        queenPocketedBy: activeQueenPocketedBy,
        needsQueenCover: needsQueenCover,
        whitePenaltyDue: whitePenaltyDue,
        blackPenaltyDue: blackPenaltyDue,
        ruleset: ruleset,
        targetScore: targetScore,
      );
      if (defensiveShot != null) {
        return defensiveShot;
      }
    }

    // 7. Safe Fallback Shot: Gentle center nudge from a clear position
    final double safeX = candidateStrikerX.isNotEmpty ? candidateStrikerX.first : 0.0;
    final double centerAngle = aiColor == PlayerColor.white ? -math.pi / 2 : math.pi / 2;
    return AiShotResult(
      strikerX: safeX,
      angle: centerAngle + (_random.nextDouble() - 0.5) * 0.15,
      power: 0.40,
      isPredictedPot: false,
      isBankShot: false,
      confidenceScore: 10.0,
    );
  }

  /// Evaluates an isolated forward physics simulation of the candidate shot.
  /// Zero mutation of live pieces, zero audio/particle/scoring side-effects.
  _SimulatedEvaluation _simulateCandidate({
    required _CandidateShot candidate,
    required List<PieceModel> livePieces,
    required PieceModel liveStriker,
    required double baselineY,
    required PlayerColor aiColor,
    required int whiteScore,
    required int blackScore,
    required bool queenPocketedState,
    required bool queenCovered,
    required PlayerColor? queenPocketedBy,
    required bool needsQueenCover,
    required int whitePenaltyDue,
    required int blackPenaltyDue,
    CarromRuleset ruleset = CarromRuleset.classic,
    int targetScore = GameConfig.freestyleTargetScore,
  }) {
    final PieceType myType =
        aiColor == PlayerColor.white ? PieceType.white : PieceType.black;
    final PieceType oppType =
        aiColor == PlayerColor.white ? PieceType.black : PieceType.white;

    // Deep clone pieces to isolate simulation
    final simPieces = livePieces.map((p) => PieceModel(
      id: p.id,
      type: p.type,
      position: p.position,
      velocity: p.velocity,
      radius: p.radius,
      mass: p.mass,
      isPocketed: p.isPocketed,
      pocketProgress: p.pocketProgress,
      pocketTarget: p.pocketTarget,
    )).toList();

    // Isolated striker copy
    final double powerMag = candidate.power * GameConfig.strikerMaxPower;
    final Vector2 impulse = Vector2(
      math.cos(candidate.angle) * powerMag,
      math.sin(candidate.angle) * powerMag,
    );

    final simStriker = PieceModel(
      id: liveStriker.id,
      type: liveStriker.type,
      position: Vector2(candidate.strikerX, baselineY),
      velocity: impulse,
      radius: liveStriker.radius,
      mass: liveStriker.mass,
      isPocketed: false,
    );

    // Track simulated pocket events
    bool strikerFouled = false;
    bool targetPocketed = false;
    int ownPocketed = 0;
    int opponentPocketed = 0;
    bool queenPocketed = false;
    final List<PieceType> pocketedTypes = [];
    final List<PieceModel> pocketedPiecesList = [];

    final simPhysics = CarromPhysics(
      pieces: simPieces,
      striker: simStriker,
      onPocket: (piece, pocket) {
        pocketedPiecesList.add(piece);
        pocketedTypes.add(piece.type);

        if (piece.type == PieceType.striker) {
          strikerFouled = true;
        } else if (piece.id == candidate.target.id) {
          targetPocketed = true;
        }

        if (piece.type == myType) {
          ownPocketed++;
        } else if (piece.type == oppType) {
          opponentPocketed++;
        } else if (piece.type == PieceType.queen) {
          queenPocketed = true;
        }
      },
    );
    simPhysics.resetAccumulator();

    final targetCopy = simPieces.firstWhere(
      (p) => p.id == candidate.target.id,
      orElse: () => candidate.target,
    );

    // Step simulation forward until all pieces settle or bounded safety limit reached
    int steps = 0;
    while ((simPhysics.isAnyPieceMoving || simPhysics.isAnyPiecePocketing) &&
        steps < maxSimulationSteps) {
      simPhysics.update(1.0 / 60.0);
      steps++;

      // Early exit on foul: once striker is pocketed, shot is disqualified
      if (strikerFouled) {
        break;
      }
    }

    // Final distance of target to intended pocket
    final double finalTargetDist = targetPocketed
        ? 0.0
        : targetCopy.position.distanceTo(candidate.pocket);
    final double initialTargetDist =
        candidate.target.position.distanceTo(candidate.pocket);

    // Evaluate simulated shot using actual CarromTurnEvaluator
    final turnResult = TurnResult(
      pocketedOwn: ownPocketed > 0,
      pocketedOpponent: opponentPocketed > 0,
      pocketedQueen: queenPocketed,
      pocketedStriker: strikerFouled,
      piecesPocketedThisTurn: pocketedTypes,
      pocketedPieces: pocketedPiecesList,
    );

    final evalResult = CarromTurnEvaluator.evaluate(
      result: turnResult,
      currentPlayer: aiColor,
      whiteScore: whiteScore,
      blackScore: blackScore,
      queenPocketed: queenPocketedState,
      queenCovered: queenCovered,
      queenPocketedBy: queenPocketedBy,
      needsCover: needsQueenCover,
      allPieces: simPieces,
      whitePenaltyDue: whitePenaltyDue,
      blackPenaltyDue: blackPenaltyDue,
      ruleset: ruleset,
    );

    for (final p in evalResult.piecesToRespot) {
      CarromRespotter.respotPiece(p, simPieces);
    }

    final matchOutcome = CarromTurnEvaluator.evaluateMatchOutcome(
      whiteScore: evalResult.whiteScore,
      blackScore: evalResult.blackScore,
      queenCovered: evalResult.queenCovered,
      needsCover: evalResult.needsCover,
      queenCoveredBy: evalResult.queenPocketedBy,
      allPieces: simPieces,
      whitePenaltyDue: evalResult.whitePenaltyDue,
      blackPenaltyDue: evalResult.blackPenaltyDue,
      clearingPlayer: aiColor,
      turnResult: turnResult,
      respotPieces: evalResult.piecesToRespot,
      ruleset: ruleset,
      targetScore: targetScore,
    );

    // Score the physical and rule outcome
    double score = 0.0;

    if (matchOutcome.isMatchOver) {
      if (matchOutcome.winner == aiColor) {
        score += 500.0;
      } else if (matchOutcome.winner != null) {
        score -= 900.0;
      }
    }

    if (strikerFouled) {
      // Fatal scratch penalty
      score -= 750.0;
    }

    // Net point differential according to official rules
    final int myScoreDelta = aiColor == PlayerColor.white
        ? (evalResult.whiteScore - whiteScore)
        : (evalResult.blackScore - blackScore);
    final int oppScoreDelta = aiColor == PlayerColor.white
        ? (evalResult.blackScore - blackScore)
        : (evalResult.whiteScore - whiteScore);

    if (ruleset == CarromRuleset.freestyle) {
      // Net points directly scale with 10/20/50 pt values (20.0 factor)
      score += myScoreDelta * 20.0;
      score -= oppScoreDelta * 18.0;

      // Turn retention reward
      if (evalResult.continuesTurn) {
        score += 160.0;
      } else if (targetPocketed) {
        score -= 40.0;
      }

      // Queen rewards in Freestyle (score already captures 50 * 20 = 1000 on cover)
      if (evalResult.queenCovered && !queenCovered) {
        score += 120.0; // Modest completion incentive
      } else if (evalResult.needsCover && !needsQueenCover) {
        score += 200.0; // High incentive to secure Queen first
      }

      // Queen respot penalty on failed cover
      final bool queenRespotted =
          evalResult.piecesToRespot.any((p) => p.type == PieceType.queen);
      if (needsQueenCover && queenRespotted) {
        score -= 200.0;
      }

      // Penalty piece/due deductions
      final int myRespotted = evalResult.piecesToRespot
          .where((p) => p.type == PieceType.white || p.type == PieceType.black)
          .length;
      score -= myRespotted * 150.0;

      final int newDue = aiColor == PlayerColor.white
          ? evalResult.whitePenaltyDue
          : evalResult.blackPenaltyDue;
      final int oldDue =
          aiColor == PlayerColor.white ? whitePenaltyDue : blackPenaltyDue;
      if (newDue > oldDue) {
        score -= (newDue - oldDue) * 180.0;
      } else if (newDue < oldDue) {
        score += (oldDue - newDue) * 150.0;
      }

      // Target pot & bank shot bonus (proportional to Freestyle point baseline)
      if (targetPocketed) {
        score += 150.0;
        if (candidate.isBankShot) {
          score += 50.0;
        }
        score += (maxSimulationSteps - steps) * 0.3;
      } else {
        final double progress = initialTargetDist - finalTargetDist;
        if (progress > 0) {
          score += progress * 0.35;
        } else {
          score -= 25.0;
        }
      }
    } else {
      score += myScoreDelta * 250.0;
      score -= oppScoreDelta * 180.0;

      // Turn retention reward
      if (evalResult.continuesTurn) {
        score += 160.0;
      } else if (targetPocketed) {
        score -= 50.0;
      }

      // Queen rewards in Classic
      if (evalResult.queenCovered && !queenCovered) {
        score += 450.0;
      } else if (evalResult.needsCover && !needsQueenCover) {
        score += 300.0;
      }

      // Queen respot penalty on failed cover
      final bool queenRespotted =
          evalResult.piecesToRespot.any((p) => p.type == PieceType.queen);
      if (needsQueenCover && queenRespotted) {
        score -= 220.0;
      }

      // Penalty piece/due deductions
      final int myRespotted =
          evalResult.piecesToRespot.where((p) => p.type == myType).length;
      score -= myRespotted * 150.0;

      final int newDue = aiColor == PlayerColor.white
          ? evalResult.whitePenaltyDue
          : evalResult.blackPenaltyDue;
      final int oldDue =
          aiColor == PlayerColor.white ? whitePenaltyDue : blackPenaltyDue;
      if (newDue > oldDue) {
        score -= (newDue - oldDue) * 200.0;
      } else if (newDue < oldDue) {
        score += (oldDue - newDue) * 150.0;
      }

      // Target pot & bank shot bonus in Classic
      if (targetPocketed) {
        score += 350.0;
        if (candidate.isBankShot) {
          score += 60.0;
        }
        score += (maxSimulationSteps - steps) * 0.4;
      } else {
        final double progress = initialTargetDist - finalTargetDist;
        if (progress > 0) {
          score += progress * 0.35;
        } else {
          score -= 25.0;
        }
      }
    }

    // Efficiency penalty: prefer minimal sufficient power
    score -= candidate.power * 6.0;

    return _SimulatedEvaluation(
      candidate: candidate,
      strikerFouled: strikerFouled,
      targetPocketed: targetPocketed,
      ownPocketed: ownPocketed,
      opponentPocketed: opponentPocketed,
      queenPocketed: queenPocketed,
      finalTargetDistToPocket: finalTargetDist,
      postShotScore: score,
    );
  }

  /// Selects the final shot applying calibrated difficulty jitter and candidate selection.
  AiShotResult _selectShotByDifficulty(
    List<_SimulatedEvaluation> evaluatedShots,
    AiDifficultyConfig config,
  ) {
    _SimulatedEvaluation chosen = evaluatedShots.first;
    // On Easy / Medium, occasionally consider 2nd best viable candidate to avoid robotic perfection
    if (evaluatedShots.length > 1 && config.secondBestShotChance > 0.0) {
      if (_random.nextDouble() < config.secondBestShotChance) {
        chosen = evaluatedShots[1];
      }
    }

    final double jitter = (_random.nextDouble() - 0.5) * config.angleJitterSpread;
    final double powerRange = config.powerMaxRatio - config.powerMinRatio;
    final double powerMod = config.powerMinRatio + _random.nextDouble() * powerRange;

    return AiShotResult(
      strikerX: chosen.candidate.strikerX,
      angle: chosen.candidate.angle + jitter,
      power: (chosen.candidate.power * powerMod).clamp(config.minClampedPower, 1.0),
      isPredictedPot: chosen.targetPocketed,
      isBankShot: chosen.candidate.isBankShot,
      confidenceScore: chosen.postShotScore,
    );
  }

  /// Direct geometric evaluation using physical momentum-transfer collision math.
  _CandidateShot? _evaluateShotToPocket({
    required Vector2 strikerPos,
    required PieceModel target,
    required Vector2 pocket,
    required List<PieceModel> allPieces,
    CarromRuleset ruleset = CarromRuleset.classic,
    double minCosTheta = 0.28,
  }) {
    final Vector2 targetToPocket = pocket - target.position;
    final double distToPocket = targetToPocket.length;
    if (distToPocket < 0.1) return null;

    final Vector2 targetToPocketDir = targetToPocket / distToPocket;

    // Ghost ball contact position
    final double totalRadii = GameConfig.pieceRadius + GameConfig.strikerRadius;
    final Vector2 hitPoint = target.position - (targetToPocketDir * totalRadii);

    final Vector2 strikerToHit = hitPoint - strikerPos;
    final double distToHit = strikerToHit.length;
    if (distToHit < 0.1) return null;

    // Cut angle alignment: cosTheta = striker flight direction dot line of centers
    final double cosTheta = (strikerToHit / distToHit).dot(targetToPocketDir);
    if (cosTheta < minCosTheta) {
      // Cut angle is too thin for current difficulty tier
      return null;
    }

    // Line-of-sight obstacle checks
    if (_isPathBlocked(strikerPos, hitPoint, target, allPieces)) return null;
    if (_isTargetToPocketBlocked(target.position, pocket, target, allPieces)) return null;

    final double power = _calculatePhysicalPower(distToHit, distToPocket, cosTheta);

    double score = 100.0;
    score -= distToHit * 0.12;
    score -= distToPocket * 0.20;
    score += cosTheta * 50.0;

    if (ruleset == CarromRuleset.freestyle) {
      if (target.type == PieceType.queen) {
        score += 32.0;
      } else if (target.type == PieceType.black) {
        score += 18.0;
      } else if (target.type == PieceType.white) {
        score += 8.0;
      }
    } else if (target.type == PieceType.queen) {
      score += 25.0;
    }

    return _CandidateShot(
      strikerX: strikerPos.x,
      angle: strikerToHit.angle(),
      power: power,
      target: target,
      pocket: pocket,
      isBankShot: false,
      geometricScore: score,
    );
  }

  /// Advanced Cushion Bank Shot calculation: Uses 2D mirror reflection across left/right cushions.
  _CandidateShot? _evaluateStrikerBankShot({
    required Vector2 strikerPos,
    required PieceModel target,
    required Vector2 pocket,
    required List<PieceModel> allPieces,
    required bool isLeftCushion,
    CarromRuleset ruleset = CarromRuleset.classic,
  }) {
    // Authoritative cushion boundary for striker (halfBoard - strikerRadius)
    final double cushionX = isLeftCushion
        ? (-GameConfig.halfBoard + GameConfig.strikerRadius)
        : (GameConfig.halfBoard - GameConfig.strikerRadius);

    final Vector2 targetToPocket = pocket - target.position;
    final double distToPocket = targetToPocket.length;
    if (distToPocket < 0.1) return null;
    final Vector2 targetToPocketDir = targetToPocket / distToPocket;

    // Ghost ball hit point
    final double totalRadii = GameConfig.pieceRadius + GameConfig.strikerRadius;
    final Vector2 hitPoint = target.position - (targetToPocketDir * totalRadii);

    // Virtual mirror of hitPoint across cushion X = cushionX
    final Vector2 hitMirror = Vector2(2 * cushionX - hitPoint.x, hitPoint.y);

    final Vector2 strikerToMirror = hitMirror - strikerPos;
    if (strikerToMirror.length < 0.1 || strikerToMirror.x.abs() < 1e-4) return null;

    final Vector2 shotDir = strikerToMirror.normalized();

    // Rebound point on cushion
    final double t = (cushionX - strikerPos.x) / shotDir.x;
    if (t <= 5.0) return null; // Must travel forward to cushion

    final Vector2 bouncePoint = strikerPos + (shotDir * t);

    // Safe cushion reflection zone: avoid corner pockets
    final double maxBounceY = GameConfig.halfBoard - GameConfig.pocketRadius - 25.0;
    if (bouncePoint.y.abs() > maxBounceY) return null;

    // Verify incident angle is not too shallow (> 12 degrees)
    if (shotDir.x.abs() < 0.20) return null;

    // Reflected direction: dx inverts, dy remains
    final Vector2 postBounceDir = Vector2(-shotDir.x, shotDir.y).normalized();

    // Alignment between post-bounce direction and target-to-pocket
    final double cosTheta = postBounceDir.dot(targetToPocketDir);
    if (cosTheta < 0.20) return null;

    // Check line-of-sight for both path segments
    if (_isPathBlocked(strikerPos, bouncePoint, target, allPieces)) return null;
    if (_isPathBlocked(bouncePoint, hitPoint, target, allPieces)) return null;
    if (_isTargetToPocketBlocked(target.position, pocket, target, allPieces)) return null;

    // Total distance traveled by striker
    final double distToHitTotal =
        strikerPos.distanceTo(bouncePoint) + bouncePoint.distanceTo(hitPoint);

    // Cushion restitution loss compensation (1.0 / GameConfig.restitution)
    final double restitutionCompensation = 1.0 / GameConfig.restitution;
    final double basePower = _calculatePhysicalPower(distToHitTotal, distToPocket, cosTheta);
    final double bankPower = (basePower * restitutionCompensation).clamp(0.42, 1.0);

    double score = 85.0;
    score -= distToHitTotal * 0.10;
    score -= distToPocket * 0.18;
    score += cosTheta * 40.0;

    if (ruleset == CarromRuleset.freestyle) {
      if (target.type == PieceType.queen) {
        score += 24.0;
      } else if (target.type == PieceType.black) {
        score += 14.0;
      } else if (target.type == PieceType.white) {
        score += 6.0;
      }
    }

    return _CandidateShot(
      strikerX: strikerPos.x,
      angle: shotDir.angle(),
      power: bankPower,
      target: target,
      pocket: pocket,
      isBankShot: true,
      geometricScore: score,
    );
  }

  /// Calculates required launch power using 2D momentum transfer collision math.
  double _calculatePhysicalPower(double distToHit, double distToPocket, double cosTheta) {
    // Required piece velocity upon impact to traverse distToPocket and trigger suction
    final double vPieceReq = 0.85 * math.sqrt(distToPocket) + 2.2;

    // Striker impact velocity required along normal:
    // With strikerMass, pieceMass, and GameConfig.restitution:
    // J / m_piece = (m_striker * (1 + e) / (m_striker + m_piece)) * v_s * cosTheta
    final double massFactor = (GameConfig.strikerMass * (1.0 + GameConfig.restitution)) /
        (GameConfig.strikerMass + GameConfig.pieceMass);
    final double vStrikerImpact = vPieceReq / (massFactor * cosTheta);

    // Striker deceleration compensation over flight distance distToHit
    final double vStrikerLaunch = vStrikerImpact + (distToHit * 0.022);

    final double normalizedPower = vStrikerLaunch / GameConfig.strikerMaxPower;
    return normalizedPower.clamp(0.35, 1.0);
  }

  /// Tactical Defensive Play: Protects against opponent pots and advances safe piece positioning.
  AiShotResult? _findBestDefensiveShot({
    required List<double> candidateStrikerX,
    required double strikerY,
    required List<PieceModel> opponentPieces,
    required List<PieceModel> myPieces,
    required List<PieceModel> allPieces,
    required PieceModel striker,
    required PlayerColor aiColor,
    required int whiteScore,
    required int blackScore,
    required bool queenPocketedState,
    required bool queenCovered,
    required PlayerColor? queenPocketedBy,
    required bool needsQueenCover,
    required int whitePenaltyDue,
    required int blackPenaltyDue,
    CarromRuleset ruleset = CarromRuleset.classic,
    int targetScore = GameConfig.freestyleTargetScore,
  }) {
    final List<_CandidateShot> defensiveCandidates = [];

    final List<PieceModel> targetThreatPool = ruleset == CarromRuleset.freestyle
        ? allPieces.where((p) => !p.isPocketed && p.type != PieceType.striker).toList()
        : opponentPieces;

    // 1. Identify threatening opponent pieces near pockets (dist < 130.0)
    final threateningOpponents = targetThreatPool.where((p) {
      final minDistToPocket = GameConfig.pockets
          .map((pocket) => p.position.distanceTo(pocket))
          .reduce(math.min);
      return minDistToPocket < 130.0;
    }).toList();

    for (final sx in candidateStrikerX) {
      final Vector2 strikerPos = Vector2(sx, strikerY);

      // Deny threatening opponent pieces by nudging them away from pockets toward cushions
      for (final opp in threateningOpponents.isNotEmpty ? threateningOpponents : targetThreatPool) {
        final nearestPocket = GameConfig.pockets
            .reduce((a, b) => opp.position.distanceTo(a) < opp.position.distanceTo(b) ? a : b);
        final awayFromPocketDir = (opp.position - nearestPocket).normalized();

        final double totalRadii = GameConfig.pieceRadius + GameConfig.strikerRadius;
        final Vector2 hitPoint = opp.position - (awayFromPocketDir * totalRadii);
        final Vector2 toHit = hitPoint - strikerPos;

        if (!_isPathBlocked(strikerPos, hitPoint, opp, allPieces)) {
          defensiveCandidates.add(_CandidateShot(
            strikerX: sx,
            angle: toHit.angle(),
            power: 0.45,
            target: opp,
            pocket: Vector2.zero,
            isBankShot: false,
            geometricScore: 40.0,
          ));
        }
      }

      // Safe cluster nudge of own trapped coins
      for (final mine in myPieces) {
        for (final pocket in GameConfig.pockets) {
          final toPocket = (pocket - mine.position).normalized();
          final hitPoint =
              mine.position - (toPocket * (GameConfig.pieceRadius + GameConfig.strikerRadius));
          final toHit = hitPoint - strikerPos;

          if (!_isPathBlocked(strikerPos, hitPoint, mine, allPieces)) {
            defensiveCandidates.add(_CandidateShot(
              strikerX: sx,
              angle: toHit.angle(),
              power: 0.40,
              target: mine,
              pocket: pocket,
              isBankShot: false,
              geometricScore: 35.0,
            ));
          }
        }
      }
    }

    if (defensiveCandidates.isEmpty) return null;

    // Simulate top 2 defensive candidates in isolation
    _CandidateShot? bestDefensive;
    double bestScore = -9999.0;

    for (final candidate in defensiveCandidates.take(2)) {
      final eval = _simulateCandidate(
        candidate: candidate,
        livePieces: allPieces,
        liveStriker: striker,
        baselineY: strikerY,
        aiColor: aiColor,
        whiteScore: whiteScore,
        blackScore: blackScore,
        queenPocketedState: queenPocketedState,
        queenCovered: queenCovered,
        queenPocketedBy: queenPocketedBy,
        needsQueenCover: needsQueenCover,
        whitePenaltyDue: whitePenaltyDue,
        blackPenaltyDue: blackPenaltyDue,
        ruleset: ruleset,
        targetScore: targetScore,
      );

      // Must strictly prevent fouls and opponent accidental pots
      final bool safeNoOpponentPot =
          ruleset == CarromRuleset.freestyle || eval.opponentPocketed == 0;
      if (!eval.strikerFouled && safeNoOpponentPot) {
        if (eval.postShotScore > bestScore) {
          bestScore = eval.postShotScore;
          bestDefensive = candidate;
        }
      }
    }

    if (bestDefensive != null) {
      return AiShotResult(
        strikerX: bestDefensive.strikerX,
        angle: bestDefensive.angle,
        power: bestDefensive.power,
        isPredictedPot: false,
        isBankShot: false,
        confidenceScore: bestScore,
      );
    }

    return null;
  }

  /// Generates legal baseline positions, rejecting any that overlap active board pieces.
  List<double> _generateBaselinePositions(double baselineY, List<PieceModel> pieces) {
    final double minX = GameConfig.strikerMinX;
    final double maxX = GameConfig.strikerMaxX;

    // Dynamically sample baseline positions across the authoritative legal slider span
    const int sampleCount = 11;
    final double step = (maxX - minX) / (sampleCount - 1);
    final List<double> candidates = [
      for (int i = 0; i < sampleCount; i++) minX + (i * step),
    ];

    final double minSeparation = GameConfig.strikerRadius + GameConfig.pieceRadius - 0.5;

    return candidates.where((x) {
      if (x < minX || x > maxX) return false;
      final pos = Vector2(x, baselineY);
      for (final p in pieces) {
        if (!p.isPocketed && pos.distanceTo(p.position) < minSeparation) {
          return false; // Overlaps active piece
        }
      }
      return true;
    }).toList();
  }

  bool _isPathBlocked(
    Vector2 start,
    Vector2 end,
    PieceModel target,
    List<PieceModel> pieces,
  ) {
    const double totalR = GameConfig.pieceRadius + GameConfig.strikerRadius - 2.0;
    const double totalRSq = totalR * totalR;
    for (final p in pieces) {
      if (p.isPocketed || p.id == target.id) continue;
      final double distSq = _pointToSegmentDistanceSquared(p.position, start, end);
      if (distSq < totalRSq) return true;
    }
    return false;
  }

  bool _isTargetToPocketBlocked(
    Vector2 start,
    Vector2 end,
    PieceModel target,
    List<PieceModel> pieces,
  ) {
    const double totalR = GameConfig.pieceRadius * 1.8;
    const double totalRSq = totalR * totalR;
    for (final p in pieces) {
      if (p.isPocketed || p.id == target.id) continue;
      final double distSq = _pointToSegmentDistanceSquared(p.position, start, end);
      if (distSq < totalRSq) return true;
    }
    return false;
  }

  double _pointToSegmentDistanceSquared(Vector2 p, Vector2 a, Vector2 b) {
    final Vector2 ab = b - a;
    final double abLenSq = ab.lengthSquared;
    if (abLenSq < 1e-6) return p.distanceSquaredTo(a);

    final double t = math.max(0.0, math.min(1.0, (p - a).dot(ab) / abLenSq));
    final Vector2 projection = a + (ab * t);
    return p.distanceSquaredTo(projection);
  }
}
