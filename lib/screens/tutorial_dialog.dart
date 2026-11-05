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

  void _onPrev() {
    AudioService().hapticSelection();
    if (_currentPage > 0) {
      final bool reducedMotion = ClubMotion.isReducedMotion(context);
      if (reducedMotion) {
        _pageController.jumpToPage(_currentPage - 1);
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
        );
      }
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
        constraints: const BoxConstraints(maxWidth: 385, maxHeight: 485),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFFFFDF8),
          border: Border.all(
            color: const Color(0xFFE8D5B0),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2214243B),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x50FFFFFF),
              blurRadius: 2.0,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF288E62),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x240C4D34),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: ClubIcon(
                            type: ClubIconType.rules,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'HOW TO PLAY',
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFF14243B),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _finish,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF7F1E6),
                        border: Border.all(
                          color: const Color(0xFFE2D6C3),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF5A5245),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFEDE4D4), height: 1, thickness: 1),

            // Paginated Step Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];

                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 12.0,
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
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFFFF7E6),
                              border: Border.all(
                                color: const Color(0xFFE5C472),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              step['badge'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: const Color(0xFF784E07),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Engaging Emerald + Gold Icon Medallion
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                              ),
                              border: Border.all(
                                color: const Color(0xFFD6B24E),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3014492E),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClubIcon(
                                type: step['customIcon'] as ClubIconType,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Step Title
                          Text(
                            step['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF14243B),
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Step Description
                          Text(
                            step['desc'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B6050),
                              height: 1.45,
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
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                          )
                        : null,
                    color: isActive ? null : const Color(0xFFDDD2C0),
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            // Footer Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _dontShowAgain = !_dontShowAgain);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _dontShowAgain,
                              activeColor: const Color(0xFF0F5A3E),
                              checkColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFC7B9A2),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() => _dontShowAgain = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Don't show again",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7A6E5D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (_currentPage > 0) ...[
                    GestureDetector(
                      onTap: _onPrev,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2D6C3),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: Color(0xFF14243B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Next / Let's Play Button
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD6B24E),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x300C4D34),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
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
                              letterSpacing: 0.8,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _currentPage == _steps.length - 1
                                ? Icons.play_arrow_rounded
                                : Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
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
