import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';
import '../services/audio_service.dart';
import '../services/piece_asset_service.dart';
import '../services/storage_service.dart';
import '../services/striker_asset_service.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
    if (widget.autoNavigate) {
      _initAppAndNavigate();
    }
  }

  Future<void> _initAppAndNavigate() async {
    await StorageService().init();
    await AudioService().init();
    await StrikerAssetService.instance.preloadAll();
    await PieceAssetService.instance.preloadAll();

    if (mounted) {
      await ClubBackground.precacheAll(context);
    }

    AudioService().sfxEnabled = StorageService().getSfxEnabled();
    AudioService().musicEnabled = StorageService().getMusicEnabled();
    AudioService().hapticsEnabled = StorageService().getHapticsEnabled();

    // Start background music automatically on the splash screen
    if (AudioService().musicEnabled) {
      AudioService().playBgm();
    }

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context).pushReplacement(
      ClubPageRoute(
        page: const MenuScreen(),
        reducedMotion: reducedMotion,
        duration: const Duration(milliseconds: 480),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final Size size = MediaQuery.of(context).size;
    final double logoSize = (size.width * 0.72).clamp(240.0, 320.0);
    final double loadingBarWidth = (size.width * 0.74).clamp(260.0, 360.0);

    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.splash,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double opacity =
                  reducedMotion ? 1.0 : _opacityAnimation.value;
              final double scale =
                  reducedMotion ? 1.0 : _scaleAnimation.value;
              final double progress =
                  reducedMotion ? 1.0 : _progressAnimation.value;

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    children: [
                      // Top Half: Grand Logo Area & Slogan Bar
                      Positioned(
                        top: size.height * 0.05,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Grand Carrom Zone Logo with Ambient Radiant Glow
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Golden / Emerald ambient radial aura
                                Container(
                                  width: logoSize * 1.15,
                                  height: logoSize * 1.15,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0x60FFD700),
                                        Color(0x2800E676),
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                                CarromZoneLogo(
                                  size: logoSize,
                                  showShadow: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Luxury Slogan Pill: "PLAY • COMPETE • MASTER"
                            _buildSloganPill(),
                          ],
                        ),
                      ),

                      // Bottom Half: Glowing Premium Loading Section (sitting on wooden board scene)
                      Positioned(
                        bottom: size.height * 0.038,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGlowingLoadingBar(loadingBarWidth, progress),
                            const SizedBox(height: 12),
                            _buildLoadingText(),
                            const SizedBox(height: 8),
                            Text(
                              'Developed by Entire Solutions',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                                color: const Color(0xFFE5D5AA),
                                shadows: const [
                                  Shadow(
                                    color: Color(0x80000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSloganPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7.5),
      decoration: BoxDecoration(
        color: const Color(0xE6052014), // Deep emerald glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5C058), // Polished gold
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40C5993B),
            blurRadius: 14,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left Starburst Flare Glint
            _buildStarburstFlare(),
            const SizedBox(width: 8),
            Text(
              'PLAY  •  COMPETE  •  MASTER',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
                color: const Color(0xFFFFF2D1),
                shadows: const [
                  Shadow(
                    color: Color(0x80D4AF37),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right Starburst Flare Glint
            _buildStarburstFlare(),
          ],
        ),
      ),
    );
  }

  Widget _buildStarburstFlare() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFF9E6),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFDF7A),
            blurRadius: 5,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingLoadingBar(double width, double progress) {
    final int percentage = (progress * 100).clamp(0, 100).toInt();
    final double shinePhase = (_controller.value * 4.0) % 1.0;

    return SizedBox(
      width: width,
      height: 44.0,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Custom painted luxury frame, ornamental tips, track, lime fill, shine & starburst
          Positioned.fill(
            child: CustomPaint(
              painter: _LuxuryLoadingBarPainter(
                progress: progress,
                shinePhase: shinePhase,
              ),
            ),
          ),
          // Percentage Badge Text placed crisply in the top-center badge
          Positioned(
            top: 0,
            height: 22.0,
            child: Center(
              child: Text(
                '$percentage%',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      color: Color(0x90000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle left gold horizontal taper line
        Container(
          width: 36,
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xCCD4AF37),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'LOADING...',
          style: GoogleFonts.outfit(
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: const Color(0xFFE8E8E7),
            shadows: const [
              Shadow(
                color: Color(0x90000000),
                blurRadius: 4,
                offset: Offset(0, 1.5),
              ),
              Shadow(
                color: Color(0x40D4AF37),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Subtle right gold horizontal taper line
        Container(
          width: 36,
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xCCD4AF37),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the luxury Carrom Zone splash progress bar matching reference design:
/// - Beveled metallic gold frame with left, right, and bottom ornamental spear tips
/// - Sunken dark emerald-green track with deep inner shadow
/// - Smooth lime-green gradient fill with diagonal animated sheen stripes
/// - Top specular gloss reflection highlight
/// - Radiant 4-point diamond starburst glint at the fill endpoint
/// - Integrated dark emerald percentage badge with gold border
class _LuxuryLoadingBarPainter extends CustomPainter {
  final double progress;
  final double shinePhase;

  const _LuxuryLoadingBarPainter({
    required this.progress,
    required this.shinePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double tipWidth = 6.5;
    const double barTop = 15.0;
    const double barHeight = 23.0;
    const double badgeWidth = 60.0;
    const double badgeHeight = 22.0;
    const double bottomTipHeight = 6.0;
    const double borderWidth = 2.2;

    final double width = size.width;
    final double centerX = width / 2.0;
    final double barWidth = width - 2 * tipWidth;
    final double barMidY = barTop + barHeight / 2.0;
    final double barBottomY = barTop + barHeight;

    final Rect barRect = Rect.fromLTWH(tipWidth, barTop, barWidth, barHeight);
    final RRect barRRect = RRect.fromRectAndRadius(
      barRect,
      const Radius.circular(barHeight / 2),
    );

    final Rect badgeRect = Rect.fromLTWH(
      centerX - badgeWidth / 2.0,
      0,
      badgeWidth,
      badgeHeight,
    );
    final RRect badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(badgeHeight / 2),
    );

    // 1. Drop Shadows onto Carrom Board
    final Path shadowPath = Path()
      ..addRRect(barRRect)
      ..addRRect(badgeRRect);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.65), 8.0, true);
    canvas.drawShadow(shadowPath, const Color(0xFFD4AF37).withOpacity(0.25), 10.0, false);

    // 2. Gold Shader (Metallic Gradient)
    final Rect fullGoldRect = Rect.fromLTWH(0, 0, width, barBottomY + bottomTipHeight);
    final Paint goldFillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF4B2), // Bright highlight
          Color(0xFFE5C058), // Rich gold
          Color(0xFFB8861E), // Deep gold
          Color(0xFF7A540E), // Bronze shadow
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(fullGoldRect);

    // 3. Draw Left, Right & Bottom Ornamental Tips (Filled Gold)
    final Path tipsPath = Path();
    // Left diamond tip
    tipsPath.moveTo(tipWidth + 1.0, barMidY - 5.5);
    tipsPath.lineTo(0.0, barMidY);
    tipsPath.lineTo(tipWidth + 1.0, barMidY + 5.5);
    tipsPath.close();

    // Right diamond tip
    tipsPath.moveTo(width - tipWidth - 1.0, barMidY - 5.5);
    tipsPath.lineTo(width, barMidY);
    tipsPath.lineTo(width - tipWidth - 1.0, barMidY + 5.5);
    tipsPath.close();

    // Bottom center downward triangle tip
    tipsPath.moveTo(centerX - 6.0, barBottomY - 1.0);
    tipsPath.lineTo(centerX, barBottomY + bottomTipHeight);
    tipsPath.lineTo(centerX + 6.0, barBottomY - 1.0);
    tipsPath.close();

    canvas.drawPath(tipsPath, goldFillPaint);

    // 4. Main Bar Gold Outer Border
    final Paint goldStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = goldFillPaint.shader;
    canvas.drawRRect(barRRect, goldStrokePaint);

    // 5. Dark Emerald Inner Track
    final Rect innerRect = Rect.fromLTWH(
      barRect.left + borderWidth,
      barRect.top + borderWidth,
      barRect.width - 2 * borderWidth,
      barRect.height - 2 * borderWidth,
    );
    final RRect innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(innerRect.height / 2),
    );

    final Paint trackPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF04160B), // Deep shadow top
          Color(0xFF0A2B18), // Emerald center
          Color(0xFF04140A), // Dark shadow bottom
        ],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect, trackPaint);

    // 6. Smooth Lime-Green Progress Fill
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double fillWidth = innerRect.width * clampedProgress;

    if (fillWidth > 1.0) {
      canvas.save();
      canvas.clipRRect(innerRRect);

      final Rect fillRect = Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        fillWidth,
        innerRect.height,
      );
      final RRect fillRRect = RRect.fromRectAndRadius(
        fillRect,
        Radius.circular(innerRect.height / 2),
      );

      // Vivid Lime-Green Gradient matching reference
      final Paint fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF28B435), // Emerald green start
            Color(0xFF5DD81B), // Vibrant lime
            Color(0xFFBCE81B), // Sunny lime
            Color(0xFFEDFC3B), // Radiant neon gold-lime end
          ],
          stops: [0.0, 0.40, 0.80, 1.0],
        ).createShader(fillRect);
      canvas.drawRRect(fillRRect, fillPaint);

      // Moving Diagonal Shine / Sheen Stripes
      canvas.save();
      canvas.clipRRect(fillRRect);
      final Paint sheenPaint = Paint()
        ..color = const Color(0x32FFFFFF)
        ..strokeWidth = 3.8
        ..style = PaintingStyle.stroke;
      const double stripeSpacing = 14.0;
      final double offset = (shinePhase * stripeSpacing);
      for (double x = -innerRect.height; x < fillWidth + innerRect.height; x += stripeSpacing) {
        canvas.drawLine(
          Offset(innerRect.left + x + offset, innerRect.bottom),
          Offset(innerRect.left + x + offset + innerRect.height, innerRect.top),
          sheenPaint,
        );
      }
      canvas.restore();

      // Top Specular Gloss Reflection
      final Rect glossRect = Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        fillWidth,
        innerRect.height * 0.42,
      );
      final Paint glossPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(glossRect);
      canvas.drawRect(glossRect, glossPaint);

      canvas.restore();

      // 7. Sparkle / Starburst Flare at Progress Endpoint
      if (clampedProgress > 0.04) {
        final double sparkleX = (innerRect.left + fillWidth - 2.5).clamp(
          innerRect.left + 4.0,
          innerRect.right - 4.0,
        );
        final double sparkleY = innerRect.top + 3.2;

        // Radial golden aura bloom
        final Paint bloomPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xE6FFF69B),
              const Color(0x60FFF69B),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(sparkleX, sparkleY), radius: 8.5));
        canvas.drawCircle(Offset(sparkleX, sparkleY), 8.5, bloomPaint);

        // 4-point Diamond Star Flare
        final Path starPath = Path()
          ..moveTo(sparkleX, sparkleY - 6.5)
          ..quadraticBezierTo(sparkleX, sparkleY, sparkleX + 6.5, sparkleY)
          ..quadraticBezierTo(sparkleX, sparkleY, sparkleX, sparkleY + 6.5)
          ..quadraticBezierTo(sparkleX, sparkleY, sparkleX - 6.5, sparkleY)
          ..quadraticBezierTo(sparkleX, sparkleY, sparkleX, sparkleY - 6.5)
          ..close();
        final Paint starPaint = Paint()..color = Colors.white;
        canvas.drawPath(starPath, starPaint);
      }
    }

    // 8. Percentage Badge Base & Gold Border
    // Badge Background (Deep emerald)
    final Paint badgeBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF092E17),
          Color(0xFF04160B),
        ],
      ).createShader(badgeRect);
    canvas.drawRRect(badgeRRect, badgeBgPaint);

    // Badge Gold Border
    final Paint badgeBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = goldFillPaint.shader;
    canvas.drawRRect(badgeRRect, badgeBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _LuxuryLoadingBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shinePhase != shinePhase;
  }
}
