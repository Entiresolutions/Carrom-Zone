import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class TutorialDialog extends StatefulWidget {
  final VoidCallback? onDismiss;

  const TutorialDialog({super.key, this.onDismiss});

  static Future<void> show(BuildContext context, {VoidCallback? onDismiss}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TutorialDialog(onDismiss: onDismiss),
    );
  }

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'customIcon': ClubIconType.aimFlick,
      'title': 'Aim & Flick',
      'desc':
          'Touch anywhere on the board and drag backward to aim and build power. Release to flick the striker forward toward your target!',
      'badge': 'STEP 1 • BASIC CONTROL',
      'accent': AppColors.goldBright,
    },
    {
      'customIcon': ClubIconType.strikerPosition,
      'title': 'Striker Positioning',
      'desc':
          'Slide the baseline track or tap the ◀ / ▶ micro-nudge buttons to position your striker cleanly before aiming.',
      'badge': 'STEP 2 • PLACEMENT',
      'accent': AppColors.tealLight,
    },
    {
      'customIcon': ClubIconType.turnContinuation,
      'title': 'Turn Continuation',
      'desc':
          'Pocketing any of your own pieces earns +1 point and grants an extra consecutive shot! Missing passes the turn.',
      'badge': 'STEP 3 • GAMEPLAY',
      'accent': AppColors.accentGreen,
    },
    {
      'customIcon': ClubIconType.queenCover,
      'title': 'The Red Queen',
      'desc':
          'The Queen awards +3 bonus points to its legal coverer! Pocket the Queen and cover it with one of your own pieces on the same or next shot before clearing your final piece.',
      'badge': 'STEP 4 • ROYAL RULE',
      'accent': AppColors.queenPiece,
    },
    {
      'customIcon': ClubIconType.foulPenalty,
      'title': 'Fouls & Penalties',
      'desc':
          'If your striker falls into a pocket, it is a foul (-1 point)! One of your pocketed pieces is returned to the center (or recorded as a penalty due) and your turn ends.',
      'badge': 'STEP 5 • PENALTY',
      'accent': AppColors.accentRed,
    },
    {
      'customIcon': ClubIconType.trophy,
      'title': 'Points-Based Victory',
      'desc':
          'Clearing all 9 of your pieces (once the Queen is covered and any penalty dues are resolved) ends the match. The player with the highest total points wins! If scores tie, the player who legally cleared all 9 pieces first wins.',
      'badge': 'STEP 6 • MATCH VICTORY',
      'accent': AppColors.goldBright,
    },
    {
      'customIcon': ClubIconType.rules,
      'title': 'Freestyle Points Mode',
      'desc':
          'In Freestyle Mode, both players can pocket either color! White coins award +20 pts, Black coins award +10 pts, and the Red Queen awards +50 pts (after cover). First to reach 160 points wins!',
      'badge': 'STEP 7 • FREESTYLE POINTS',
      'accent': AppColors.tealLight,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    AudioService().hapticSelection();
    if (_currentPage < _steps.length - 1) {
      final bool reducedMotion = ClubMotion.isReducedMotion(context);
      if (reducedMotion) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _finish();
    }
  }

  void _finish() {
    if (_dontShowAgain) {
      StorageService().setTutorialSeen(true);
    }
    AudioService().hapticLight();
    Navigator.of(context).pop();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 470),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.cardBg,
          border: Border.all(
            color: AppColors.gold.withOpacity(0.75),
            width: 1.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1814243B),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x35FFFFFF),
              blurRadius: 1.5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 20, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.tealLight.withOpacity(0.14),
                        ),
                        child: const ClubIcon(
                          type: ClubIconType.school,
                          color: AppColors.tealLight,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'HOW TO PLAY',
                        style: GoogleFonts.cinzel(
                          color: AppColors.ivory,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Opacity(
                          opacity: 0.01,
                          child: Icon(Icons.close_rounded, size: 20),
                        ),
                        ClubIcon(
                          type: ClubIconType.close,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                    onPressed: _finish,
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.cardBorderSubtle, height: 12),

            // Paginated Step Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final Color accent = step['accent'] as Color;

                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 6.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Step Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: accent.withOpacity(0.14),
                              border: Border.all(
                                color: accent.withOpacity(0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              step['badge'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: accent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Icon Medallion
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cardBgElevated,
                              border: Border.all(color: accent, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClubIcon(
                                type: step['customIcon'] as ClubIconType,
                                size: 30,
                                color: accent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Title
                          Text(
                            step['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ivory,
                              letterSpacing: 1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Description
                          Text(
                            step['desc'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (idx) {
                final bool isActive = idx == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive ? AppColors.gold : AppColors.cardBorder,
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Footer Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _dontShowAgain = !_dontShowAgain);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _dontShowAgain,
                            activeColor: AppColors.gold,
                            checkColor: AppColors.bgDark,
                            side: const BorderSide(color: AppColors.textMuted),
                            onChanged: (val) {
                              setState(() => _dontShowAgain = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Don't show again",
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.bgDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _steps.length - 1
                              ? 'LET\'S PLAY'
                              : 'NEXT',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ClubIcon(
                          type: _currentPage == _steps.length - 1
                              ? ClubIconType.play
                              : ClubIconType.chevronRight,
                          size: 16,
                          color: AppColors.bgDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
