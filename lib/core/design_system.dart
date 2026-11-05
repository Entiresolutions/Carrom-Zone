import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/piece_model.dart';
import '../painters/board_painter.dart';
import '../services/piece_asset_service.dart';
import '../services/striker_asset_service.dart';
import 'app_colors.dart';
import 'theme_piece_style.dart';

/// Motion and accessibility helper for reduced-motion support.
class ClubMotion {
  static bool isReducedMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ?? false;
  }

  static Duration duration(BuildContext context, Duration normal) {
    return isReducedMotion(context) ? Duration.zero : normal;
  }
}

/// Smooth, purposeful page transition for Carrom Zone screens.
class ClubPageRoute<T> extends PageRouteBuilder<T> {
  ClubPageRoute({
    required Widget page,
    bool reducedMotion = false,
    Duration duration = const Duration(milliseconds: 320),
  }) : super(
          transitionDuration: reducedMotion ? Duration.zero : duration,
          reverseTransitionDuration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (reducedMotion) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Centralized typography styles for Carrom Zone.
class ClubTypography {
  static TextStyle displayLarge({Color color = AppColors.ivory}) {
    return GoogleFonts.cinzel(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 3.2,
      color: color,
      height: 1.15,
    );
  }

  static TextStyle displayMedium({Color color = AppColors.ivory}) {
    return GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle sectionLabel({Color color = AppColors.goldLight}) {
    return GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color,
    );
  }

  static TextStyle cardTitle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.outfit(
      fontSize: 15.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle body({
    Color color = AppColors.textSecondary,
    double fontSize = 13,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle scoreNumber({
    Color color = AppColors.ivory,
    double fontSize = 19,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Screen-specific background presets for Carrom Zone.
enum ClubBackgroundPreset {
  /// Cinematic close-up of an authentic Carrom board in lower frame with
  /// deep dark negative space above for branding.
  splash,

  /// Perspective wooden Carrom board on the middle-right with generous dark
  /// negative space for header and game-mode cards.
  home,

  /// Distraction-free dark charcoal/navy studio surface so the playable
  /// Carrom board remains 100% visually dominant.
  gameplay,

  /// Unified minimal dark background for Settings, Leaderboard, and utility screens.
  secondary,
}

/// Centralized asset paths for Carrom Zone's optimized 1080×1920 WebP backgrounds.
class ClubBackgroundAssets {
  static const String splash = 'assets/images/backgrounds/splash_bg.webp';
  static const String home = 'assets/images/backgrounds/home_bg.webp';
  static const String gameplay = 'assets/images/backgrounds/gameplay_bg.webp';
  static const String secondary = 'assets/images/backgrounds/secondary_bg.webp';

  static const List<String> all = [
    splash,
    home,
    gameplay,
    secondary,
  ];

  static String assetFor(ClubBackgroundPreset preset) {
    switch (preset) {
      case ClubBackgroundPreset.splash:
        return splash;
      case ClubBackgroundPreset.home:
        return home;
      case ClubBackgroundPreset.gameplay:
        return gameplay;
      case ClubBackgroundPreset.secondary:
        return secondary;
    }
  }

  static Alignment alignmentFor(ClubBackgroundPreset preset) {
    switch (preset) {
      case ClubBackgroundPreset.splash:
        return Alignment.center;
      case ClubBackgroundPreset.home:
        return const Alignment(0.25, 0.0);
      case ClubBackgroundPreset.gameplay:
      case ClubBackgroundPreset.secondary:
        return Alignment.center;
    }
  }
}

/// Responsive, memory-optimized background widget for all Carrom Zone screens.
class ClubBackground extends StatelessWidget {
  final Widget child;
  final ClubBackgroundPreset preset;
  final bool showWatermark;
  final Color? accentTint;

  const ClubBackground({
    super.key,
    required this.child,
    this.preset = ClubBackgroundPreset.secondary,
    this.showWatermark = true,
    this.accentTint,
  });

  /// Pre-decodes all 4 WebP backgrounds into Flutter's image cache for
  /// instant, zero-jank screen transitions.
  static Future<void> precacheAll(BuildContext context) async {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final Size screenSize =
        MediaQuery.maybeSizeOf(context) ?? const Size(390, 844);
    final int targetCacheWidth =
        (screenSize.width * dpr).round().clamp(360, 1080);

    for (final String assetPath in ClubBackgroundAssets.all) {
      try {
        await precacheImage(
          ResizeImage(
            AssetImage(assetPath),
            width: targetCacheWidth,
          ),
          context,
        );
      } catch (_) {
        // Ignore asset precache errors in headless widget test environments
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final String assetPath = ClubBackgroundAssets.assetFor(preset);
    final Alignment imageAlignment = ClubBackgroundAssets.alignmentFor(preset);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double logicalWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 420.0;
        final int decodeWidth = (logicalWidth * dpr).round().clamp(360, 1080);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgGradientTop,
                AppColors.bgGradientMid,
                AppColors.bgGradientBottom,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Optimized Responsive WebP Background Image
              Positioned.fill(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                  cacheWidth: decodeWidth,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.expand();
                  },
                ),
              ),

              // 1b. Atmospheric Depth Blur (Home & Secondary) to eliminate background noise
              if (preset == ClubBackgroundPreset.home ||
                  preset == ClubBackgroundPreset.secondary)
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

              // 2. Preset-specific Readability Gradient Scrim Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _buildReadabilityScrim(preset),
                    ),
                  ),
                ),
              ),

              // 3. Subtle Ambient Lighting (without outer box clutter)
              if (showWatermark)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ClubBackdropPainter(
                      accentTint: accentTint ?? AppColors.tealPrimary,
                      subtleMode: preset == ClubBackgroundPreset.splash ||
                          preset == ClubBackgroundPreset.home,
                    ),
                  ),
                ),

              // 4. Foreground Screen Content
              child,
            ],
          ),
        );
      },
    );
  }

  LinearGradient _buildReadabilityScrim(ClubBackgroundPreset preset) {
    switch (preset) {
      case ClubBackgroundPreset.splash:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0.0, 1.0],
        );

      case ClubBackgroundPreset.home:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFAF6EE).withOpacity(0.85),
            const Color(0xFFF5EFE6).withOpacity(0.72),
            const Color(0xFFF0E7D6).withOpacity(0.80),
            const Color(0xFFE6DBC9).withOpacity(0.92),
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        );

      case ClubBackgroundPreset.gameplay:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5EFE6).withOpacity(0.25),
            Colors.transparent,
            const Color(0xFFEADFCF).withOpacity(0.25),
          ],
          stops: const [0.0, 0.50, 1.0],
        );

      case ClubBackgroundPreset.secondary:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5EFE6).withOpacity(0.35),
            const Color(0xFFEFE7DA).withOpacity(0.20),
            const Color(0xFFE6DBC9).withOpacity(0.45),
          ],
          stops: const [0.0, 0.50, 1.0],
        );
    }
  }
}

class _ClubBackdropPainter extends CustomPainter {
  final Color accentTint;
  final bool subtleMode;

  _ClubBackdropPainter({
    required this.accentTint,
    this.subtleMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect topGlowRect = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.14),
      radius: size.width * 0.75,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentTint.withOpacity(subtleMode ? 0.06 : 0.10),
            AppColors.gold.withOpacity(subtleMode ? 0.02 : 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(topGlowRect),
    );
  }

  @override
  bool shouldRepaint(covariant _ClubBackdropPainter oldDelegate) {
    return oldDelegate.accentTint != accentTint ||
        oldDelegate.subtleMode != subtleMode;
  }
}

/// Clean, translucent dark-slate surface container without heavy borders.
class ClubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const ClubCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.borderWidth = 1.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.cardBorder,
          width: borderWidth,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: const Color(0x1414243B),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Clean, minimal section header with optional trailing metadata.
class ClubSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;

  const ClubSectionHeader({
    super.key,
    required this.title,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClubTypography.sectionLabel(
                color: AppColors.goldLight.withOpacity(0.88),
              ),
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable 38×38 translucent glass icon button with micro-scale press feedback.
class ClubIconButton extends StatefulWidget {
  final IconData? icon;
  final ClubIconType? customIcon;
  final String? tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double size;

  const ClubIconButton({
    super.key,
    this.icon,
    this.customIcon,
    this.tooltip,
    this.onTap,
    this.iconColor,
    this.size = 38,
  }) : assert(icon != null || customIcon != null);

  @override
  State<ClubIconButton> createState() => _ClubIconButtonState();
}

class _ClubIconButtonState extends State<ClubIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final Widget iconWidget = widget.customIcon != null
        ? ClubIcon(
            type: widget.customIcon!,
            size: widget.size * 0.48,
            color: widget.iconColor ?? AppColors.ivoryWarm,
          )
        : Icon(
            widget.icon!,
            color: widget.iconColor ?? AppColors.ivoryWarm,
            size: widget.size * 0.48,
          );

    final Widget button = GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: (_pressed && !reducedMotion) ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(widget.size * 0.32),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1214243B),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Custom champagne-gold pill toggle switch for Carrom Zone settings & pause modal.
class ClubToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ClubToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFFE8B648), Color(0xFFC5993B)],
                )
              : null,
          color: value ? null : const Color(0xFFE0D7C7),
          border: Border.all(
            color: value
                ? const Color(0xFFC5993B)
                : const Color(0xFFC8BCA9),
            width: 1.0,
          ),
        ),
        child: AnimatedAlign(
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFAF6EF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x3514243B),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Official 3D emblem logo for Carrom Zone.
/// Features the golden crown with emerald jewel, perspective carrom board,
/// and embossed 3D "CARROM ZONE" badge.
class CarromZoneLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const CarromZoneLogo({
    super.key,
    this.size = 190,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget logoImage = Image.asset(
      'assets/images/logo/carrom_zone_logo.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/logo/carrom_zone_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              ClubCrestLogo(size: size),
        );
      },
    );

    if (!showShadow) {
      return SizedBox(width: size, height: size, child: logoImage);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.24),
            blurRadius: size * 0.22,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: size * 0.16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: logoImage,
    );
  }
}

/// Refined architectural Carrom Zone Crest Medallion.
/// Loads the official Carrom Zone logo asset with procedural canvas fallback.
class ClubCrestLogo extends StatelessWidget {
  final double size;

  const ClubCrestLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo/carrom_zone_logo.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/logo/carrom_zone_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => CustomPaint(
              size: Size(size, size),
              painter: _ClubCrestPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _ClubCrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;

    // 1. Soft drop shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      r * 0.92,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Dark obsidian-navy shield base
    canvas.drawCircle(
      center,
      r * 0.94,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF16263B),
            Color(0xFF0A121E),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.94)),
    );

    // 3. Outer champagne-gold rim
    canvas.drawCircle(
      center,
      r * 0.94,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            AppColors.goldDark,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, r * 0.075),
    );

    // 4. Inner fine hairline ring
    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..color = AppColors.goldLight.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 5. 8-Point Precision Carrom Compass Star
    final Paint starFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldLight,
          AppColors.gold,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.64));

    final Path starPath = Path();
    const int points = 8;
    for (int i = 0; i < points * 2; i++) {
      final double isMajor = (i % 4 == 0)
          ? r * 0.64
          : (i.isEven ? r * 0.46 : r * 0.19);
      final double angle = (i * math.pi / points) - math.pi / 2;
      final Offset pt = Offset(
        center.dx + math.cos(angle) * isMajor,
        center.dy + math.sin(angle) * isMajor,
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starFill);

    // 6. Center Crimson Queen Jewel
    canvas.drawCircle(
      center,
      r * 0.21,
      Paint()..color = AppColors.queenPiece,
    );
    canvas.drawCircle(
      center,
      r * 0.21,
      Paint()
        ..color = AppColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(center.dx - r * 0.05, center.dy - r * 0.05),
      r * 0.045,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Identifiers for Carrom Zone's unified bespoke game icon system.
enum ClubIconType {
  vsCpu,
  passAndPlay,
  practice,
  leaderboard,
  rules,
  settings,
  themes,
  sfx,
  music,
  haptic,
  pause,
  back,
  close,
  play,
  restart,
  home,
  check,
  trophy,
  queen,
  coin,
  gem,
  trash,
  school,
  nudgeLeft,
  nudgeRight,
  chevronRight,
  aimFlick,
  strikerPosition,
  turnContinuation,
  queenCover,
  foulPenalty,
  lock,
  unlock,
}

/// Handcrafted, consistent vector game icon for Carrom Zone.
/// Guarantees a single unified visual language: consistent 1.5px stroke weight,
/// rounded stroke caps and joins, and sophisticated game-appropriate geometry.
class ClubIcon extends StatelessWidget {
  final ClubIconType type;
  final double size;
  final Color? color;
  final Color? accentColor;

  const ClubIcon({
    super.key,
    required this.type,
    this.size = 20,
    this.color,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Professional rounded Material Icons for universal clarity and optical balance
    final IconData? materialIcon = switch (type) {
      ClubIconType.rules => Icons.menu_book_rounded,
      ClubIconType.themes => Icons.palette_rounded,
      ClubIconType.settings => Icons.tune_rounded,
      _ => null,
    };

    if (materialIcon != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            materialIcon,
            size: size,
            color: color ?? AppColors.ivoryWarm,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClubIconPainter(
          type: type,
          color: color ?? AppColors.ivoryWarm,
          accentColor: accentColor ?? const Color(0xFFD4AF37),
        ),
      ),
    );
  }
}

class _ClubIconPainter extends CustomPainter {
  final ClubIconType type;
  final Color color;
  final Color accentColor;

  _ClubIconPainter({
    required this.type,
    required this.color,
    this.accentColor = const Color(0xFFD4AF37),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.083)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case ClubIconType.vsCpu:
        // Minimalist tactical AI chip with precision crosshair core
        final RRect chip = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: w * 0.68, height: h * 0.68),
          Radius.circular(w * 0.16),
        );
        canvas.drawRRect(chip, strokePaint);
        // Center precision core dot
        canvas.drawCircle(center, w * 0.12, fillPaint);
        // 4 orthogonal bus pins
        final double pOff = w * 0.44;
        canvas.drawLine(
          Offset(center.dx, center.dy - w * 0.34),
          Offset(center.dx, center.dy - pOff),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy + w * 0.34),
          Offset(center.dx, center.dy + pOff),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - w * 0.34, center.dy),
          Offset(center.dx - pOff, center.dy),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + w * 0.34, center.dy),
          Offset(center.dx + pOff, center.dy),
          strokePaint,
        );
        break;

      case ClubIconType.passAndPlay:
        // Two opposing tournament carrom striker discs in duel formation
        final Offset disc1 = Offset(center.dx - w * 0.20, center.dy + h * 0.14);
        final Offset disc2 = Offset(center.dx + w * 0.20, center.dy - h * 0.14);
        final double r = w * 0.24;
        canvas.drawCircle(disc1, r, strokePaint);
        canvas.drawCircle(disc1, r * 0.38, fillPaint);
        canvas.drawCircle(disc2, r, strokePaint);
        canvas.drawCircle(disc2, r * 0.38, fillPaint);
        break;

      case ClubIconType.practice:
        // Precision concentric target rings with release trajectory vector
        canvas.drawCircle(center, w * 0.42, strokePaint);
        canvas.drawCircle(center, w * 0.24, strokePaint);
        canvas.drawCircle(center, w * 0.08, fillPaint);
        // Directional trajectory aim ticks
        canvas.drawLine(
          Offset(center.dx + w * 0.24, center.dy - h * 0.24),
          Offset(center.dx + w * 0.42, center.dy - h * 0.42),
          strokePaint,
        );
        break;

      case ClubIconType.leaderboard:
        // Modern faceted championship trophy cup
        final Path cup = Path()
          ..moveTo(center.dx - w * 0.30, center.dy - h * 0.35)
          ..lineTo(center.dx + w * 0.30, center.dy - h * 0.35)
          ..lineTo(center.dx + w * 0.22, center.dy + h * 0.08)
          ..quadraticBezierTo(
            center.dx,
            center.dy + h * 0.22,
            center.dx - w * 0.22,
            center.dy + h * 0.08,
          )
          ..close();
        canvas.drawPath(cup, strokePaint);
        // Cup stem and base
        canvas.drawLine(
          Offset(center.dx, center.dy + h * 0.19),
          Offset(center.dx, center.dy + h * 0.36),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - w * 0.26, center.dy + h * 0.36),
          Offset(center.dx + w * 0.26, center.dy + h * 0.36),
          strokePaint,
        );
        // Handles
        final Path leftHandle = Path()
          ..moveTo(center.dx - w * 0.30, center.dy - h * 0.24)
          ..cubicTo(
            center.dx - w * 0.46,
            center.dy - h * 0.24,
            center.dx - w * 0.46,
            center.dy,
            center.dx - w * 0.22,
            center.dy + h * 0.04,
          );
        canvas.drawPath(leftHandle, strokePaint);
        final Path rightHandle = Path()
          ..moveTo(center.dx + w * 0.30, center.dy - h * 0.24)
          ..cubicTo(
            center.dx + w * 0.46,
            center.dy - h * 0.24,
            center.dx + w * 0.46,
            center.dy,
            center.dx + w * 0.22,
            center.dy + h * 0.04,
          );
        canvas.drawPath(rightHandle, strokePaint);
        break;

      case ClubIconType.rules:
        // Modern open-book rulebook icon with harmonious curvature
        final double spineX = center.dx;
        final double outerLeft = center.dx - w * 0.36;
        final double outerRight = center.dx + w * 0.36;
        final double topDipY = center.dy - h * 0.24;
        final double topCrestY = center.dy - h * 0.32;
        final double botDipY = center.dy + h * 0.22;
        final double botCrestY = center.dy + h * 0.16;
        final double edgeTopY = center.dy - h * 0.26;
        final double edgeBotY = center.dy + h * 0.24;

        // Left page
        final Path leftPage = Path()
          ..moveTo(spineX, topDipY)
          ..quadraticBezierTo(center.dx - w * 0.18, topCrestY, outerLeft, edgeTopY)
          ..lineTo(outerLeft, edgeBotY)
          ..quadraticBezierTo(center.dx - w * 0.18, botCrestY, spineX, botDipY)
          ..close();
        canvas.drawPath(leftPage, strokePaint);

        // Right page
        final Path rightPage = Path()
          ..moveTo(spineX, topDipY)
          ..quadraticBezierTo(center.dx + w * 0.18, topCrestY, outerRight, edgeTopY)
          ..lineTo(outerRight, edgeBotY)
          ..quadraticBezierTo(center.dx + w * 0.18, botCrestY, spineX, botDipY)
          ..close();
        canvas.drawPath(rightPage, strokePaint);

        // Center spine binding
        canvas.drawLine(
          Offset(spineX, topDipY),
          Offset(spineX, botDipY + h * 0.04),
          strokePaint,
        );
        break;

      case ClubIconType.settings:
        // Minimal adjustment-sliders icon with balanced tracks and rounded knobs
        final double leftX = center.dx - w * 0.34;
        final double rightX = center.dx + w * 0.34;
        final double track1Y = center.dy - h * 0.24;
        final double track2Y = center.dy;
        final double track3Y = center.dy + h * 0.24;

        // 3 Horizontal slider tracks
        canvas.drawLine(Offset(leftX, track1Y), Offset(rightX, track1Y), strokePaint);
        canvas.drawLine(Offset(leftX, track2Y), Offset(rightX, track2Y), strokePaint);
        canvas.drawLine(Offset(leftX, track3Y), Offset(rightX, track3Y), strokePaint);

        // Slider control knob positions (left, right, center-left for dynamic balance)
        final double knob1X = center.dx - w * 0.12;
        final double knob2X = center.dx + w * 0.14;
        final double knob3X = center.dx - w * 0.16;
        final double knobR = w * 0.105;

        canvas.drawCircle(Offset(knob1X, track1Y), knobR, fillPaint);
        canvas.drawCircle(Offset(knob2X, track2Y), knobR, fillPaint);
        canvas.drawCircle(Offset(knob3X, track3Y), knobR, fillPaint);
        break;

      case ClubIconType.themes:
        // Premium color-palette icon (artist palette with thumb hole and color wells)
        final Path palette = Path()
          ..moveTo(center.dx, center.dy - h * 0.36)
          ..cubicTo(
            center.dx + w * 0.22, center.dy - h * 0.36,
            center.dx + w * 0.38, center.dy - h * 0.18,
            center.dx + w * 0.38, center.dy,
          )
          ..cubicTo(
            center.dx + w * 0.38, center.dy + h * 0.18,
            center.dx + w * 0.26, center.dy + h * 0.36,
            center.dx + w * 0.08, center.dy + h * 0.36,
          )
          ..cubicTo(
            center.dx + w * 0.02, center.dy + h * 0.24,
            center.dx - w * 0.04, center.dy + h * 0.24,
            center.dx - w * 0.10, center.dy + h * 0.36,
          )
          ..cubicTo(
            center.dx - w * 0.26, center.dy + h * 0.36,
            center.dx - w * 0.38, center.dy + h * 0.18,
            center.dx - w * 0.38, center.dy,
          )
          ..cubicTo(
            center.dx - w * 0.38, center.dy - h * 0.18,
            center.dx - w * 0.22, center.dy - h * 0.36,
            center.dx, center.dy - h * 0.36,
          )
          ..close();
        canvas.drawPath(palette, strokePaint);

        // Thumb hole cutout
        canvas.drawCircle(
          Offset(center.dx - w * 0.14, center.dy + h * 0.12),
          w * 0.075,
          strokePaint,
        );

        // 4 Pigment color wells
        final double dotR = w * 0.06;
        canvas.drawCircle(Offset(center.dx - w * 0.14, center.dy - h * 0.15), dotR, fillPaint);
        canvas.drawCircle(Offset(center.dx + w * 0.03, center.dy - h * 0.22), dotR, fillPaint);
        canvas.drawCircle(Offset(center.dx + w * 0.19, center.dy - h * 0.14), dotR, fillPaint);
        canvas.drawCircle(Offset(center.dx + w * 0.20, center.dy + h * 0.08), dotR, fillPaint);
        break;

      case ClubIconType.sfx:
        // 3-Bar geometric acoustic soundwave
        canvas.drawLine(
          Offset(center.dx - w * 0.28, center.dy - h * 0.14),
          Offset(center.dx - w * 0.28, center.dy + h * 0.14),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - h * 0.36),
          Offset(center.dx, center.dy + h * 0.36),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + w * 0.28, center.dy - h * 0.22),
          Offset(center.dx + w * 0.28, center.dy + h * 0.22),
          strokePaint,
        );
        break;

      case ClubIconType.music:
        // Acoustic note glyph
        final Offset noteHead =
            Offset(center.dx - w * 0.16, center.dy + h * 0.20);
        canvas.drawCircle(noteHead, w * 0.18, fillPaint);
        canvas.drawLine(
          Offset(noteHead.dx + w * 0.14, noteHead.dy),
          Offset(noteHead.dx + w * 0.14, center.dy - h * 0.34),
          strokePaint,
        );
        canvas.drawLine(
          Offset(noteHead.dx + w * 0.14, center.dy - h * 0.34),
          Offset(center.dx + w * 0.30, center.dy - h * 0.22),
          strokePaint,
        );
        break;

      case ClubIconType.haptic:
        // Tactile vibration wave brackets around a solid tactile center
        canvas.drawCircle(center, w * 0.10, fillPaint);
        // Left pulse arc
        final Path leftArc = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: w * 0.30),
            math.pi * 0.72,
            math.pi * 0.56,
          );
        canvas.drawPath(leftArc, strokePaint);
        // Right pulse arc
        final Path rightArc = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: w * 0.30),
            -math.pi * 0.28,
            math.pi * 0.56,
          );
        canvas.drawPath(rightArc, strokePaint);
        break;

      case ClubIconType.pause:
        // Symmetrical twin champagne bars
        canvas.drawLine(
          Offset(center.dx - w * 0.16, center.dy - h * 0.32),
          Offset(center.dx - w * 0.16, center.dy + h * 0.32),
          strokePaint..strokeWidth = w * 0.16,
        );
        canvas.drawLine(
          Offset(center.dx + w * 0.16, center.dy - h * 0.32),
          Offset(center.dx + w * 0.16, center.dy + h * 0.32),
          strokePaint..strokeWidth = w * 0.16,
        );
        break;

      case ClubIconType.back:
        // Minimalist precision chevron
        final Path back = Path()
          ..moveTo(center.dx + w * 0.14, center.dy - h * 0.30)
          ..lineTo(center.dx - w * 0.16, center.dy)
          ..lineTo(center.dx + w * 0.14, center.dy + h * 0.30);
        canvas.drawPath(back, strokePaint);
        break;

      case ClubIconType.close:
        // Diagonal precision cross with rounded caps
        final double off = w * 0.22;
        canvas.drawLine(
          Offset(center.dx - off, center.dy - off),
          Offset(center.dx + off, center.dy + off),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + off, center.dy - off),
          Offset(center.dx - off, center.dy + off),
          strokePaint,
        );
        break;

      case ClubIconType.play:
        // Symmetrical play triangle with rounded vertices
        final Path triangle = Path()
          ..moveTo(center.dx - w * 0.18, center.dy - h * 0.28)
          ..lineTo(center.dx + w * 0.26, center.dy)
          ..lineTo(center.dx - w * 0.18, center.dy + h * 0.28)
          ..close();
        canvas.drawPath(triangle, fillPaint);
        break;

      case ClubIconType.restart:
        // Circular sweep replay arrow
        final double r = w * 0.30;
        final Path arc = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: r),
            -math.pi * 0.75,
            math.pi * 1.55,
          );
        canvas.drawPath(arc, strokePaint);
        final Offset arrowTip = Offset(
          center.dx + r * math.cos(-math.pi * 0.75),
          center.dy + r * math.sin(-math.pi * 0.75),
        );
        final Path tip = Path()
          ..moveTo(arrowTip.dx - w * 0.14, arrowTip.dy)
          ..lineTo(arrowTip.dx, arrowTip.dy)
          ..lineTo(arrowTip.dx, arrowTip.dy + h * 0.14);
        canvas.drawPath(tip, strokePaint);
        break;

      case ClubIconType.home:
        // Stylized clubhouse pavilion
        final Path house = Path()
          ..moveTo(center.dx, center.dy - h * 0.34)
          ..lineTo(center.dx + w * 0.34, center.dy - h * 0.06)
          ..lineTo(center.dx + w * 0.24, center.dy - h * 0.06)
          ..lineTo(center.dx + w * 0.24, center.dy + h * 0.32)
          ..lineTo(center.dx + w * 0.08, center.dy + h * 0.32)
          ..lineTo(center.dx + w * 0.08, center.dy + h * 0.12)
          ..lineTo(center.dx - w * 0.08, center.dy + h * 0.12)
          ..lineTo(center.dx - w * 0.08, center.dy + h * 0.32)
          ..lineTo(center.dx - w * 0.24, center.dy + h * 0.32)
          ..lineTo(center.dx - w * 0.24, center.dy - h * 0.06)
          ..lineTo(center.dx - w * 0.34, center.dy - h * 0.06)
          ..close();
        canvas.drawPath(house, strokePaint);
        break;

      case ClubIconType.check:
        // Tapered precision checkmark
        final Path check = Path()
          ..moveTo(center.dx - w * 0.30, center.dy + h * 0.02)
          ..lineTo(center.dx - w * 0.08, center.dy + h * 0.24)
          ..lineTo(center.dx + w * 0.30, center.dy - h * 0.22);
        canvas.drawPath(check, strokePaint..strokeWidth = math.max(1.6, w * 0.10));
        break;

      case ClubIconType.trophy:
        // Faceted championship trophy cup
        final Path cup = Path()
          ..moveTo(center.dx - w * 0.28, center.dy - h * 0.32)
          ..lineTo(center.dx + w * 0.28, center.dy - h * 0.32)
          ..lineTo(center.dx + w * 0.20, center.dy + h * 0.08)
          ..quadraticBezierTo(
            center.dx,
            center.dy + h * 0.22,
            center.dx - w * 0.20,
            center.dy + h * 0.08,
          )
          ..close();
        canvas.drawPath(cup, strokePaint);
        canvas.drawLine(
          Offset(center.dx, center.dy + h * 0.19),
          Offset(center.dx, center.dy + h * 0.34),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - w * 0.24, center.dy + h * 0.34),
          Offset(center.dx + w * 0.24, center.dy + h * 0.34),
          strokePaint,
        );
        final Path leftH = Path()
          ..moveTo(center.dx - w * 0.28, center.dy - h * 0.22)
          ..cubicTo(
            center.dx - w * 0.44,
            center.dy - h * 0.22,
            center.dx - w * 0.44,
            center.dy,
            center.dx - w * 0.20,
            center.dy + h * 0.04,
          );
        canvas.drawPath(leftH, strokePaint);
        final Path rightH = Path()
          ..moveTo(center.dx + w * 0.28, center.dy - h * 0.22)
          ..cubicTo(
            center.dx + w * 0.44,
            center.dy - h * 0.22,
            center.dx + w * 0.44,
            center.dy,
            center.dx + w * 0.20,
            center.dy + h * 0.04,
          );
        canvas.drawPath(rightH, strokePaint);
        break;

      case ClubIconType.queen:
        // 3-point royal crown
        final Path crown = Path()
          ..moveTo(center.dx - w * 0.34, center.dy + h * 0.24)
          ..lineTo(center.dx - w * 0.34, center.dy - h * 0.14)
          ..lineTo(center.dx - w * 0.15, center.dy + h * 0.02)
          ..lineTo(center.dx, center.dy - h * 0.28)
          ..lineTo(center.dx + w * 0.15, center.dy + h * 0.02)
          ..lineTo(center.dx + w * 0.34, center.dy - h * 0.14)
          ..lineTo(center.dx + w * 0.34, center.dy + h * 0.24)
          ..close();
        canvas.drawPath(crown, strokePaint);
        canvas.drawCircle(Offset(center.dx - w * 0.34, center.dy - h * 0.14), w * 0.05, fillPaint);
        canvas.drawCircle(Offset(center.dx, center.dy - h * 0.28), w * 0.06, fillPaint);
        canvas.drawCircle(Offset(center.dx + w * 0.34, center.dy - h * 0.14), w * 0.05, fillPaint);
        canvas.drawLine(
          Offset(center.dx - w * 0.30, center.dy + h * 0.16),
          Offset(center.dx + w * 0.30, center.dy + h * 0.16),
          strokePaint,
        );
        break;

      case ClubIconType.coin:
        // Golden tournament coin
        canvas.drawCircle(center, w * 0.38, strokePaint);
        canvas.drawCircle(center, w * 0.24, strokePaint..strokeWidth = math.max(1.0, w * 0.05));
        canvas.drawCircle(center, w * 0.08, fillPaint);
        break;

      case ClubIconType.gem:
        // Precision faceted diamond
        final Path gem = Path()
          ..moveTo(center.dx, center.dy - h * 0.35)
          ..lineTo(center.dx + w * 0.32, center.dy - h * 0.08)
          ..lineTo(center.dx, center.dy + h * 0.36)
          ..lineTo(center.dx - w * 0.32, center.dy - h * 0.08)
          ..close();
        canvas.drawPath(gem, strokePaint);
        canvas.drawLine(
          Offset(center.dx - w * 0.32, center.dy - h * 0.08),
          Offset(center.dx + w * 0.32, center.dy - h * 0.08),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - h * 0.35),
          Offset(center.dx, center.dy + h * 0.36),
          strokePaint,
        );
        break;

      case ClubIconType.trash:
        // Minimalist trash container
        canvas.drawLine(
          Offset(center.dx - w * 0.30, center.dy - h * 0.18),
          Offset(center.dx + w * 0.30, center.dy - h * 0.18),
          strokePaint,
        );
        final Path tLid = Path()
          ..moveTo(center.dx - w * 0.12, center.dy - h * 0.18)
          ..lineTo(center.dx - w * 0.12, center.dy - h * 0.28)
          ..lineTo(center.dx + w * 0.12, center.dy - h * 0.28)
          ..lineTo(center.dx + w * 0.12, center.dy - h * 0.18);
        canvas.drawPath(tLid, strokePaint);
        final Path tBody = Path()
          ..moveTo(center.dx - w * 0.24, center.dy - h * 0.14)
          ..lineTo(center.dx - w * 0.18, center.dy + h * 0.32)
          ..lineTo(center.dx + w * 0.18, center.dy + h * 0.32)
          ..lineTo(center.dx + w * 0.24, center.dy - h * 0.14);
        canvas.drawPath(tBody, strokePaint);
        canvas.drawLine(
          Offset(center.dx - w * 0.06, center.dy - h * 0.06),
          Offset(center.dx - w * 0.05, center.dy + h * 0.24),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx + w * 0.06, center.dy - h * 0.06),
          Offset(center.dx + w * 0.05, center.dy + h * 0.24),
          strokePaint,
        );
        break;

      case ClubIconType.school:
        // Academic cap
        final Path cap = Path()
          ..moveTo(center.dx, center.dy - h * 0.28)
          ..lineTo(center.dx + w * 0.38, center.dy - h * 0.06)
          ..lineTo(center.dx, center.dy + h * 0.14)
          ..lineTo(center.dx - w * 0.38, center.dy - h * 0.06)
          ..close();
        canvas.drawPath(cap, strokePaint);
        final Path arch = Path()
          ..moveTo(center.dx - w * 0.22, center.dy + h * 0.04)
          ..lineTo(center.dx - w * 0.22, center.dy + h * 0.22)
          ..quadraticBezierTo(
            center.dx,
            center.dy + h * 0.34,
            center.dx + w * 0.22,
            center.dy + h * 0.22,
          )
          ..lineTo(center.dx + w * 0.22, center.dy + h * 0.04);
        canvas.drawPath(arch, strokePaint);
        canvas.drawLine(
          Offset(center.dx + w * 0.38, center.dy - h * 0.06),
          Offset(center.dx + w * 0.38, center.dy + h * 0.18),
          strokePaint,
        );
        canvas.drawCircle(Offset(center.dx + w * 0.38, center.dy + h * 0.22), w * 0.05, fillPaint);
        break;

      case ClubIconType.nudgeLeft:
        final Path nLeft = Path()
          ..moveTo(center.dx + w * 0.14, center.dy - h * 0.26)
          ..lineTo(center.dx - w * 0.18, center.dy)
          ..lineTo(center.dx + w * 0.14, center.dy + h * 0.26);
        canvas.drawPath(nLeft, strokePaint);
        break;

      case ClubIconType.nudgeRight:
        final Path nRight = Path()
          ..moveTo(center.dx - w * 0.14, center.dy - h * 0.26)
          ..lineTo(center.dx + w * 0.18, center.dy)
          ..lineTo(center.dx - w * 0.14, center.dy + h * 0.26);
        canvas.drawPath(nRight, strokePaint);
        break;

      case ClubIconType.chevronRight:
        final Path cRight = Path()
          ..moveTo(center.dx - w * 0.14, center.dy - h * 0.26)
          ..lineTo(center.dx + w * 0.16, center.dy)
          ..lineTo(center.dx - w * 0.14, center.dy + h * 0.26);
        canvas.drawPath(cRight, strokePaint);
        break;

      case ClubIconType.aimFlick:
        // Touch point + aim trajectory arrow
        final Offset touch = Offset(center.dx - w * 0.14, center.dy + h * 0.14);
        canvas.drawCircle(touch, w * 0.16, strokePaint);
        canvas.drawCircle(touch, w * 0.06, fillPaint);
        final Offset aimTip = Offset(center.dx + w * 0.30, center.dy - h * 0.30);
        canvas.drawLine(touch, aimTip, strokePaint);
        final Path aimArr = Path()
          ..moveTo(aimTip.dx - w * 0.18, aimTip.dy)
          ..lineTo(aimTip.dx, aimTip.dy)
          ..lineTo(aimTip.dx, aimTip.dy + h * 0.18);
        canvas.drawPath(aimArr, strokePaint);
        break;

      case ClubIconType.strikerPosition:
        // Baseline track with striker disc
        canvas.drawLine(
          Offset(center.dx - w * 0.40, center.dy),
          Offset(center.dx + w * 0.40, center.dy),
          strokePaint,
        );
        canvas.drawCircle(Offset(center.dx - w * 0.38, center.dy), w * 0.06, strokePaint);
        canvas.drawCircle(Offset(center.dx + w * 0.38, center.dy), w * 0.06, strokePaint);
        canvas.drawCircle(center, w * 0.22, strokePaint..strokeWidth = math.max(1.5, w * 0.09));
        canvas.drawCircle(center, w * 0.07, fillPaint);
        break;

      case ClubIconType.turnContinuation:
        // Loop combo arrow with +1
        final Path cLoop = Path()
          ..addArc(
            Rect.fromCircle(center: center, radius: w * 0.30),
            -math.pi * 0.8,
            math.pi * 1.5,
          );
        canvas.drawPath(cLoop, strokePaint);
        final Offset cTip = Offset(
          center.dx + w * 0.30 * math.cos(math.pi * 0.7),
          center.dy + w * 0.30 * math.sin(math.pi * 0.7),
        );
        final Path cArr = Path()
          ..moveTo(cTip.dx - w * 0.12, cTip.dy)
          ..lineTo(cTip.dx, cTip.dy)
          ..lineTo(cTip.dx + w * 0.04, cTip.dy - h * 0.12);
        canvas.drawPath(cArr, strokePaint);
        canvas.drawLine(
          Offset(center.dx - w * 0.08, center.dy),
          Offset(center.dx + w * 0.04, center.dy),
          strokePaint,
        );
        canvas.drawLine(
          Offset(center.dx - w * 0.02, center.dy - h * 0.06),
          Offset(center.dx - w * 0.02, center.dy + h * 0.06),
          strokePaint,
        );
        break;

      case ClubIconType.queenCover:
        // Shield with royal crown inside
        final Path qShield = Path()
          ..moveTo(center.dx - w * 0.30, center.dy - h * 0.30)
          ..lineTo(center.dx + w * 0.30, center.dy - h * 0.30)
          ..lineTo(center.dx + w * 0.30, center.dy + h * 0.04)
          ..quadraticBezierTo(
            center.dx,
            center.dy + h * 0.36,
            center.dx - w * 0.30,
            center.dy + h * 0.04,
          )
          ..close();
        canvas.drawPath(qShield, strokePaint);
        final Path qCrown = Path()
          ..moveTo(center.dx - w * 0.16, center.dy + h * 0.08)
          ..lineTo(center.dx - w * 0.16, center.dy - h * 0.08)
          ..lineTo(center.dx - w * 0.07, center.dy)
          ..lineTo(center.dx, center.dy - h * 0.14)
          ..lineTo(center.dx + w * 0.07, center.dy)
          ..lineTo(center.dx + w * 0.16, center.dy - h * 0.08)
          ..lineTo(center.dx + w * 0.16, center.dy + h * 0.08)
          ..close();
        canvas.drawPath(qCrown, strokePaint);
        break;

      case ClubIconType.foulPenalty:
        // Warning triangle with exclamation
        final Path pTri = Path()
          ..moveTo(center.dx, center.dy - h * 0.34)
          ..lineTo(center.dx + w * 0.36, center.dy + h * 0.30)
          ..lineTo(center.dx - w * 0.36, center.dy + h * 0.30)
          ..close();
        canvas.drawPath(pTri, strokePaint);
        canvas.drawLine(
          Offset(center.dx, center.dy - h * 0.10),
          Offset(center.dx, center.dy + h * 0.10),
          strokePaint..strokeWidth = math.max(1.6, w * 0.09),
        );
        canvas.drawCircle(Offset(center.dx, center.dy + h * 0.20), w * 0.05, fillPaint);
        break;

      case ClubIconType.lock:
        // Lock body (rounded rectangle)
        final RRect lBody = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + h * 0.10),
            width: w * 0.56,
            height: h * 0.44,
          ),
          Radius.circular(w * 0.10),
        );
        canvas.drawRRect(lBody, strokePaint);
        // Lock shackle (loop)
        final Path lShackle = Path()
          ..moveTo(center.dx - w * 0.18, center.dy - h * 0.10)
          ..lineTo(center.dx - w * 0.18, center.dy - h * 0.22)
          ..arcToPoint(
            Offset(center.dx + w * 0.18, center.dy - h * 0.22),
            radius: Radius.circular(w * 0.18),
          )
          ..lineTo(center.dx + w * 0.18, center.dy - h * 0.10);
        canvas.drawPath(lShackle, strokePaint);
        // Keyhole
        canvas.drawCircle(Offset(center.dx, center.dy + h * 0.08), w * 0.06, fillPaint);
        canvas.drawLine(
          Offset(center.dx, center.dy + h * 0.08),
          Offset(center.dx, center.dy + h * 0.18),
          strokePaint..strokeWidth = math.max(1.4, w * 0.08),
        );
        break;

      case ClubIconType.unlock:
        final RRect uBody = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + h * 0.10),
            width: w * 0.56,
            height: h * 0.44,
          ),
          Radius.circular(w * 0.10),
        );
        canvas.drawRRect(uBody, strokePaint);
        final Path uShackle = Path()
          ..moveTo(center.dx - w * 0.18, center.dy - h * 0.10)
          ..lineTo(center.dx - w * 0.18, center.dy - h * 0.28)
          ..arcToPoint(
            Offset(center.dx + w * 0.18, center.dy - h * 0.28),
            radius: Radius.circular(w * 0.18),
          )
          ..lineTo(center.dx + w * 0.18, center.dy - h * 0.22);
        canvas.drawPath(uShackle, strokePaint);
        canvas.drawCircle(Offset(center.dx, center.dy + h * 0.08), w * 0.06, fillPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ClubIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

/// Authentic, tactile preview of the Carrom board surface.
/// Replaces blurry scaled-down board diagrams with a believable, handcrafted
/// workshop sample of the wood or felt material.
class BoardSurfaceThumbnail extends StatelessWidget {
  final BoardThemeType theme;
  final double size;

  const BoardSurfaceThumbnail({
    super.key,
    required this.theme,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return ThemeBoardPreview(
      theme: theme,
      size: size,
    );
  }
}

/// Exact miniature in-game preview of the Carrom table theme.
/// Renders the identical board framing, surface, baselines, mandala, pieces,
/// and striker as seen in active gameplay.
class ThemeBoardPreview extends StatelessWidget {
  final BoardThemeType theme;
  final double size;
  final BorderRadius? borderRadius;
  final bool isLocked;
  final bool showStrikerBadge;

  const ThemeBoardPreview({
    super.key,
    required this.theme,
    this.size = 56,
    this.borderRadius,
    this.isLocked = false,
    this.showStrikerBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: br,
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppColors.getThemeAsset(theme),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                size: Size(size, size),
                painter: BoardPainter(theme: theme),
              ),
            ),
            if (showStrikerBadge && !isLocked)
              Positioned(
                right: size * 0.05,
                bottom: size * 0.05,
                child: StrikerAssetService.buildPreview(
                  theme: theme,
                  size: size * 0.36,
                  showShadow: true,
                ),
              ),
            if (isLocked)
              Container(
                color: const Color(0x9E0B131E),
                child: const Center(
                  child: ClubIcon(
                    type: ClubIconType.lock,
                    size: 24,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClubCoinBadge extends StatelessWidget {
  final bool isWhite;
  final bool isQueen;
  final double size;
  final BoardThemeType? theme;

  const ClubCoinBadge({
    super.key,
    this.isWhite = true,
    this.isQueen = false,
    this.size = 28,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? BoardThemeType.mahogany;
    final PieceType pieceType = isQueen
        ? PieceType.queen
        : (isWhite ? PieceType.white : PieceType.black);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: Image.asset(
        PieceAssetService.getPieceAsset(effectiveTheme, pieceType),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            _buildProceduralFallback(effectiveTheme),
      ),
    );
  }

  Widget _buildProceduralFallback(BoardThemeType effectiveTheme) {
    final ThemePieceStyle style = ThemePieceStyle.of(effectiveTheme);

    final List<Color> gradientColors = isQueen
        ? style.queenGradient
        : (isWhite ? style.whiteGradient : style.blackGradient);

    final Color ringColor = isQueen
        ? style.queenOuterRing
        : (isWhite ? style.whiteRim : style.blackRim);

    final Color grooveColor = isQueen
        ? style.queenStarColor
        : (isWhite ? style.whiteGroove : style.blackGroove);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: gradientColors,
        ),
        border: Border.all(
          color: ringColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.52,
          height: size * 0.52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: grooveColor.withOpacity(0.85),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isQueen ? style.queenCenterPip : grooveColor.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact currency pill badge displaying gold coins or gems with custom vector icon.
class ClubCurrencyBadge extends StatelessWidget {
  final ClubIconType type;
  final String amount;
  final Color? color;

  const ClubCurrencyBadge({
    super.key,
    required this.type,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGem = type == ClubIconType.gem;
    final Color accent = color ?? (isGem ? const Color(0xFF67E8F9) : AppColors.goldLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClubIcon(
            type: type,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ivory,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bespoke player avatar badge with gold tournament border and level tag.
class ClubPlayerAvatar extends StatelessWidget {
  final String name;
  final int level;
  final double size;
  final VoidCallback? onTap;

  const ClubPlayerAvatar({
    super.key,
    this.name = 'PlayerOne',
    this.level = 12,
    this.size = 38,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE5C478), Color(0xFFB88E3E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.24),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF132033),
              ),
              child: Center(
                child: ClubIcon(
                  type: ClubIconType.trophy,
                  size: size * 0.48,
                  color: AppColors.goldLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ivory,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lv. $level',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Handcrafted tournament empty state with engraved vector medallion.
class ClubEmptyState extends StatelessWidget {
  final ClubIconType icon;
  final String title;
  final String message;

  const ClubEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg,
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.40),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: ClubIcon(
                  type: icon,
                  size: 32,
                  color: AppColors.goldLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ivory,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
