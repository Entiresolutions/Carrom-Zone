import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/carrom_rule_engine.dart';
import '../core/design_system.dart';
import '../core/game_config.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

/// Clean, focused Game Over dialog displaying authoritative match scores,
/// piece completion breakdowns, Queen bonus attribution, and decisive winner or draw.
class GameOverDialog extends StatefulWidget {
  final MatchOutcomeEvaluation? matchOutcome;
  final PlayerColor? winner;
  final int whiteScore;
  final int blackScore;
  final int whiteRemaining;
  final int blackRemaining;
  final PlayerColor? queenCoveredBy;
  final GameMode gameMode;
  final CarromRuleset ruleset;
  final int targetScore;
  final bool isHumanWinner;
  final String? matchId;
  final VoidCallback onRematch;
  final VoidCallback onMainMenu;

  const GameOverDialog({
    super.key,
    this.matchOutcome,
    required this.winner,
    required this.whiteScore,
    required this.blackScore,
    this.whiteRemaining = 0,
    this.blackRemaining = 0,
    this.queenCoveredBy,
    required this.gameMode,
    this.ruleset = CarromRuleset.classic,
    this.targetScore = GameConfig.freestyleTargetScore,
    required this.isHumanWinner,
    this.matchId,
    required this.onRematch,
    required this.onMainMenu,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  CarromRuleset get _effectiveRuleset =>
      widget.matchOutcome?.ruleset ?? widget.ruleset;

  bool get _isDraw => widget.matchOutcome?.isDraw ?? false;

  PlayerColor? get _authoritativeWinner {
    if (widget.gameMode == GameMode.practice) {
      return PlayerColor.white;
    }
    if (_isDraw) {
      return null;
    }
    if (widget.matchOutcome != null && widget.matchOutcome!.winner != null) {
      return widget.matchOutcome!.winner!;
    }
    return widget.winner;
  }

  int get _effectiveWhiteScore =>
      widget.matchOutcome?.whiteScore ?? widget.whiteScore;

  int get _effectiveBlackScore =>
      widget.matchOutcome?.blackScore ?? widget.blackScore;

  int get _effectiveWhiteRemaining =>
      widget.matchOutcome?.whiteRemaining ?? widget.whiteRemaining;

  int get _effectiveBlackRemaining =>
      widget.matchOutcome?.blackRemaining ?? widget.blackRemaining;

  PlayerColor? get _effectiveQueenCoveredBy =>
      widget.matchOutcome != null
          ? widget.matchOutcome!.queenCoveredBy
          : widget.queenCoveredBy;

  bool get _authoritativeIsHumanWinner {
    if (_isDraw) {
      return false;
    }
    if (widget.gameMode == GameMode.practice ||
        widget.gameMode == GameMode.passAndPlay) {
      return true;
    }
    if (widget.matchOutcome != null && widget.matchOutcome!.winner != null) {
      return widget.matchOutcome!.winner == PlayerColor.white;
    }
    return widget.isHumanWinner;
  }

  @override
  void initState() {
    super.initState();
    if (_authoritativeIsHumanWinner) {
      AudioService().playWin();
      AudioService().hapticCelebration();
    } else {
      AudioService().playDefeat();
      AudioService().hapticMedium();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlayerColor? effectiveWinner = _authoritativeWinner;
    final bool effectiveIsHumanWinner = _authoritativeIsHumanWinner;
    final bool isFreestyle = _effectiveRuleset == CarromRuleset.freestyle;
    String winnerTitle;
    String subtitle;
    ClubIconType customIcon;
    Color accentColor;

    if (widget.gameMode == GameMode.practice) {
      winnerTitle = 'PRACTICE FINISHED!';
      subtitle = 'Board Cleared! Great club precision!';
      customIcon = ClubIconType.practice;
      accentColor = AppColors.goldBright;
    } else if (_isDraw) {
      winnerTitle = 'MATCH DRAW!';
      subtitle = 'Dead heat at $_effectiveWhiteScore points each!';
      customIcon = ClubIconType.trophy;
      accentColor = AppColors.goldBright;
    } else if (widget.gameMode == GameMode.passAndPlay) {
      final String winnerName = isFreestyle
          ? (effectiveWinner == PlayerColor.white ? 'Player 1' : 'Player 2')
          : (effectiveWinner == PlayerColor.white
              ? 'Player 1 (White)'
              : 'Player 2 (Black)');
      winnerTitle = '$winnerName WINS!';
      subtitle = isFreestyle
          ? 'Freestyle Points championship victory!'
          : 'Championship tabletop victory!';
      customIcon = ClubIconType.trophy;
      accentColor = AppColors.goldBright;
    } else {
      if (effectiveIsHumanWinner) {
        winnerTitle = 'YOU WIN!';
        subtitle = isFreestyle
            ? 'Freestyle mastery against CPU!'
            : 'Magnificent club victory against CPU!';
        customIcon = ClubIconType.trophy;
        accentColor = AppColors.goldBright;
      } else {
        winnerTitle = 'CPU WINS!';
        subtitle = 'Well played! Ready for a rematch?';
        customIcon = ClubIconType.vsCpu;
        accentColor = AppColors.accentRed;
      }
    }

    final String p1Label = isFreestyle
        ? (widget.gameMode == GameMode.passAndPlay ? 'Player 1' : 'You (P1)')
        : 'White (P1)';
    final String p2Label = isFreestyle
        ? (widget.gameMode == GameMode.vsCpu ? 'CPU (P2)' : 'Player 2')
        : 'Black (P2/CPU)';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.90, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 368),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold,
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1814243B),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medallion Header
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.14),
                    border: Border.all(color: accentColor, width: 1.8),
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: customIcon,
                      color: accentColor,
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  winnerTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Side-by-Side Score Cards
                Row(
                  children: [
                    Expanded(
                      child: _scoreCard(
                        label: p1Label,
                        score: _effectiveWhiteScore,
                        remaining: _effectiveWhiteRemaining,
                        coveredQueen: _effectiveQueenCoveredBy == PlayerColor.white,
                        isWinner: effectiveWinner == PlayerColor.white,
                        isDraw: _isDraw,
                        isFreestyle: isFreestyle,
                        isWhiteCoin: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _scoreCard(
                        label: p2Label,
                        score: _effectiveBlackScore,
                        remaining: _effectiveBlackRemaining,
                        coveredQueen: _effectiveQueenCoveredBy == PlayerColor.black,
                        isWinner: effectiveWinner == PlayerColor.black,
                        isDraw: _isDraw,
                        isFreestyle: isFreestyle,
                        isWhiteCoin: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Action Buttons (Rematch & Main Menu)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          AudioService().hapticSelection();
                          widget.onMainMenu();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'MAIN MENU',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          AudioService().hapticSelection();
                          widget.onRematch();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.bgDark,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'REMATCH',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreCard({
    required String label,
    required int score,
    required int remaining,
    required bool coveredQueen,
    required bool isWinner,
    required bool isDraw,
    required bool isFreestyle,
    required bool isWhiteCoin,
  }) {
    final bool isHighlighted = isWinner || isDraw;
    final String breakdownText = isFreestyle
        ? (score >= widget.targetScore
            ? 'Target ${widget.targetScore} Reached!'
            : 'Target: ${widget.targetScore} pts')
        : (remaining == 0
            ? '9/9 Cleared'
            : '${9 - remaining}/9 potted • $remaining left');
    final int queenBonus =
        isFreestyle ? GameConfig.freestyleQueenPoints : 3;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isHighlighted ? const Color(0xFFFFFBF2) : AppColors.cardBgElevated,
        border: Border.all(
          color: isHighlighted ? AppColors.gold : AppColors.cardBorder,
          width: isHighlighted ? 1.6 : 1.0,
        ),
        boxShadow: isHighlighted
            ? const [
                BoxShadow(
                  color: Color(0x22C5993B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          ClubCoinBadge(
            theme: StorageService().getBoardTheme(),
            isWhite: isWhiteCoin,
            size: 22,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isHighlighted ? AppColors.goldLight : AppColors.textSecondary,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: ClubTypography.scoreNumber(
              fontSize: 24,
              color: isHighlighted ? AppColors.goldLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            breakdownText,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? const Color(0xFFB8861E) : AppColors.textMuted,
            ),
          ),
          if (coveredQueen) ...[
            const SizedBox(height: 2),
            Text(
              '👑 Queen (+$queenBonus)',
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.goldBright,
              ),
            ),
          ],
          if (isWinner || isDraw) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isDraw ? 'DRAW' : 'WINNER',
                style: GoogleFonts.outfit(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF14243B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
