import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/theme_service.dart';
import 'app_colors.dart';
import 'championship_theme.dart';
import 'design_system.dart';

/// Interactive scale and shadow press-feedback container.
/// Provides subtle scale-down (~0.97) + tactile feedback over ~120ms.
class ChampionshipPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final double scaleFactor;
  final Duration duration;
  final bool enableHaptic;

  const ChampionshipPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptic = true,
  });

  @override
  State<ChampionshipPressable> createState() => _ChampionshipPressableState();
}

class _ChampionshipPressableState extends State<ChampionshipPressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.enableHaptic) {
      AudioService().hapticSelection();
    }
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final double effectiveScale = (_isPressed && !reducedMotion) ? widget.scaleFactor : 1.0;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: effectiveScale,
          duration: widget.duration,
          curve: Curves.easeOutQuad,
          child: widget.borderRadius != null
              ? ClipRRect(
                  borderRadius: widget.borderRadius!,
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}

/// Two People line vector icon used for PASS & PLAY multiplayer.
class TwoPeopleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TwoPeopleIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TwoPeopleIconPainter(color: color),
      ),
    );
  }
}

class _TwoPeopleIconPainter extends CustomPainter {
  final Color color;

  const _TwoPeopleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = mathMax(1.4, w * 0.075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Person 1 (Primary / Front-Left)
    final double p1CenterX = w * 0.35;
    final double p1HeadY = h * 0.33;
    final double p1HeadR = w * 0.16;

    // Head 1
    canvas.drawCircle(Offset(p1CenterX, p1HeadY), p1HeadR, strokePaint);

    // Body 1 (curved shoulders)
    final Path body1 = Path()
      ..moveTo(w * 0.08, h * 0.82)
      ..quadraticBezierTo(w * 0.10, h * 0.58, p1CenterX, h * 0.58)
      ..quadraticBezierTo(w * 0.60, h * 0.58, w * 0.62, h * 0.82);
    canvas.drawPath(body1, strokePaint);

    // Person 2 (Secondary / Back-Right)
    final double p2CenterX = w * 0.68;
    final double p2HeadY = h * 0.28;
    final double p2HeadR = w * 0.14;

    // Head 2
    canvas.drawCircle(Offset(p2CenterX, p2HeadY), p2HeadR, strokePaint);

    // Body 2 (curved right shoulder connecting behind person 1)
    final Path body2 = Path()
      ..moveTo(w * 0.52, h * 0.66)
      ..quadraticBezierTo(w * 0.64, h * 0.52, p2CenterX + w * 0.02, h * 0.52)
      ..quadraticBezierTo(w * 0.90, h * 0.53, w * 0.92, h * 0.78);
    canvas.drawPath(body2, strokePaint);
  }

  double mathMax(double a, double b) => a > b ? a : b;

  @override
  bool shouldRepaint(covariant _TwoPeopleIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Header square rounded white icon button with light neutral border.
/// Guaranteed >= 48px touch target for accessibility.
class ChampionshipIconButton extends StatelessWidget {
  final ClubIconType iconType;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final double size;

  const ChampionshipIconButton({
    super.key,
    required this.iconType,
    required this.onTap,
    required this.tooltip,
    this.iconColor = ChampionshipColors.primaryGreen,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: ChampionshipPressable(
          onTap: onTap,
          scaleFactor: 0.93,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: ChampionshipColors.cardSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: ChampionshipColors.cardBorder, // Light neutral border
                width: 1.2,
              ),
              boxShadow: ChampionshipColors.iconButtonShadow,
            ),
            child: Center(
              child: ClubIcon(
                type: iconType,
                color: iconColor,
                size: size * 0.52,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable Page Header with back button, serif title, gold subtitle, and action slot.
class ChampionshipAppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? action;

  const ChampionshipAppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChampionshipIconButton(
            iconType: ClubIconType.back,
            tooltip: 'Back',
            size: 40,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChampionshipTypography.brandTitle(fontSize: 18),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChampionshipTypography.brandSubtitle(
                    color: ChampionshipColors.goldLabel,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            action!
          else
            const SizedBox(width: 40), // Balance back button
        ],
      ),
    );
  }
}

/// Badge pill: "👑 POINTS-BASED CLUB PLAY"
/// Fully rounded, gold outline, cream fill, gold text.
class ChampionshipGoldPill extends StatelessWidget {
  final String text;
  final Widget? icon;

  const ChampionshipGoldPill({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: ChampionshipColors.pillFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ChampionshipColors.goldBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C5C4418),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 7),
          ],
          Text(
            text,
            style: ChampionshipTypography.overline(
              color: ChampionshipColors.goldLabel,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Table Theme card (white surface, light neutral border, soft shadow).
/// Board thumbnail on left, metadata in middle, "EXPLORE ›" pill button on right.
class ChampionshipThemeCard extends StatelessWidget {
  final BoardThemeType theme;
  final bool isPremium;
  final VoidCallback onTap;

  const ChampionshipThemeCard({
    super.key,
    required this.theme,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String themeName = AppColors.getThemeName(theme);
    final String themeSubtitle = AppColors.getThemeSubtitle(theme);

    return ChampionshipPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: ChampionshipColors.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: ChampionshipColors.goldBorder, // Golden outline
            width: 1.2,
          ),
          boxShadow: ChampionshipColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Rounded square thumbnail of current carrom board
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: ChampionshipColors.cardBorder,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ThemeBoardPreview(
                theme: theme,
                size: 54,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 13),

            // Middle: Metadata lockup
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'TABLE THEME',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChampionshipTypography.overline(
                            color: ChampionshipColors.goldLabel,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Small "PREMIUM" / "FREE" pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? ChampionshipColors.goldPillBg
                              : const Color(0xFFEAF5EE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isPremium
                                ? ChampionshipColors.goldBorder
                                : const Color(0xFF9FD4B3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isPremium ? 'PREMIUM' : 'FREE',
                          style: ChampionshipTypography.microBadge(
                            color: isPremium
                                ? ChampionshipColors.gold
                                : const Color(0xFF1B6A45),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    themeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChampionshipTypography.themeTitle(
                      color: ChampionshipColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$themeSubtitle · 11 Champion…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChampionshipTypography.subtitle(
                      color: ChampionshipColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Green pill button "EXPLORE ›"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                gradient: ChampionshipColors.greenGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: ChampionshipColors.greenButtonShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXPLORE',
                    style: ChampionshipTypography.exploreButtonText(
                      color: ChampionshipColors.textWhite,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const ClubIcon(
                    type: ClubIconType.chevronRight,
                    color: Colors.white,
                    size: 11,
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

/// Game mode toggle segmented control inside card with light neutral border.
/// Two equal segments: CLASSIC CARROM vs FREESTYLE POINTS.
class ChampionshipSegmentedToggle extends StatelessWidget {
  final bool isClassic;
  final VoidCallback onSelectClassic;
  final VoidCallback onSelectFreestyle;

  const ChampionshipSegmentedToggle({
    super.key,
    required this.isClassic,
    required this.onSelectClassic,
    required this.onSelectFreestyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: ChampionshipColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ChampionshipColors.cardBorder, // Light neutral border
          width: 1.2,
        ),
        boxShadow: ChampionshipColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegment(
              title: 'CLASSIC CARROM',
              subtitle: 'White vs Black · +3 Queen',
              isSelected: isClassic,
              onTap: onSelectClassic,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildSegment(
              title: 'FREESTYLE POINTS',
              subtitle: 'W:20 • B:10 • Q:50 • 160 Pts',
              isSelected: !isClassic,
              onTap: onSelectFreestyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: isSelected ? ChampionshipColors.greenGradient : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? ChampionshipColors.goldBorder
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x2814492E),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ChampionshipTypography.segmentTitle(
                  color: isSelected
                      ? ChampionshipColors.textWhite
                      : ChampionshipColors.textPrimary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ChampionshipTypography.segmentSubtitle(
                  color: isSelected
                      ? ChampionshipColors.textGreenSubtle
                      : ChampionshipColors.textSecondary,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mode Action Card for VS CPU, PASS & PLAY, PRACTICE ARENA.
/// Features green rounded-square icon tile, middle text block, and green circular play button.
class ChampionshipModeCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String categoryTag;
  final String? badgeText;
  final bool hasNotificationDot;
  final VoidCallback onTap;

  const ChampionshipModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    this.badgeText,
    this.hasNotificationDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChampionshipPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: ChampionshipColors.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: ChampionshipColors.goldBorder, // Golden outline
            width: 1.2,
          ),
          boxShadow: ChampionshipColors.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Green rounded-square icon tile with optional notification dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: ChampionshipColors.greenGradient,
                    border: Border.all(
                      color: const Color(0xFF288E62),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3014492E),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(child: icon),
                ),
                if (hasNotificationDot)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: ChampionshipColors.notificationRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40E53935),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Middle: Text lockup
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          categoryTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ChampionshipTypography.overline(
                            color: ChampionshipColors.goldLabel,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: ChampionshipColors.goldPillBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: ChampionshipColors.goldBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText!,
                            style: ChampionshipTypography.microBadge(
                              color: ChampionshipColors.gold,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChampionshipTypography.cardTitle(
                      color: ChampionshipColors.textPrimary,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChampionshipTypography.subtitle(
                      color: ChampionshipColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Green circular play button with golden ring and white ▶
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ChampionshipColors.playButtonGradient,
                border: Border.all(
                  color: const Color(0xFFD6B24E),
                  width: 1.4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3514492E),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: ClubIcon(
                  type: ClubIconType.play,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Identifiers for tabs in the Championship floating bottom navigation.
enum ChampionshipTab {
  rules,
  themes,
  settings,
}

/// Floating bottom navigation dock pill.
/// 3 items: Rules, Themes, Settings.
/// Dynamically animates the gold highlighted active indicator according to [activeTab].
/// When [activeTab == null] (e.g. on Home screen), no tab is highlighted.
class ChampionshipBottomNav extends StatelessWidget {
  final ChampionshipTab? activeTab;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenThemes;
  final VoidCallback onOpenSettings;

  const ChampionshipBottomNav({
    super.key,
    this.activeTab,
    required this.onOpenRules,
    required this.onOpenThemes,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ChampionshipColors.cardSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ChampionshipColors.cardBorder, // Light neutral border
          width: 1.2,
        ),
        boxShadow: ChampionshipColors.floatingDockShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double tabWidth = totalWidth / 3.0;

          // Compute alignment for the sliding indicator
          double alignX = 0.0;
          bool hasActive = activeTab != null;
          if (activeTab == ChampionshipTab.rules) {
            alignX = -1.0;
          } else if (activeTab == ChampionshipTab.themes) {
            alignX = 0.0;
          } else if (activeTab == ChampionshipTab.settings) {
            alignX = 1.0;
          }

          return Stack(
            children: [
              // Sliding gold active tab highlight container
              AnimatedAlign(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeInOut,
                alignment: Alignment(alignX, 0.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hasActive ? 1.0 : 0.0,
                  child: Container(
                    width: tabWidth - 4,
                    height: 52,
                    decoration: BoxDecoration(
                      color: ChampionshipColors.activeTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ChampionshipColors.goldBorder,
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12B88A2E),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Foreground Row of interactive items
              Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      iconType: ClubIconType.rules,
                      label: 'RULES',
                      isSelected: activeTab == ChampionshipTab.rules,
                      onTap: onOpenRules,
                    ),
                  ),
                  _buildDivider(),
                  Expanded(
                    child: _buildNavItem(
                      iconType: ClubIconType.school,
                      label: 'THEMES',
                      isSelected: activeTab == ChampionshipTab.themes,
                      onTap: onOpenThemes,
                    ),
                  ),
                  _buildDivider(),
                  Expanded(
                    child: _buildNavItem(
                      iconType: ClubIconType.settings,
                      label: 'SETTINGS',
                      isSelected: activeTab == ChampionshipTab.settings,
                      onTap: onOpenSettings,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required ClubIconType iconType,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color iconColor =
        isSelected ? ChampionshipColors.gold : ChampionshipColors.primaryGreen;
    final Color textColor =
        isSelected ? ChampionshipColors.gold : ChampionshipColors.textPrimary;

    return ChampionshipPressable(
      onTap: onTap,
      scaleFactor: 0.94,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClubIcon(
              type: iconType,
              color: iconColor,
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChampionshipTypography.bottomNavLabel(
                color: textColor,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: ChampionshipColors.cardBorderSubtle,
    );
  }
}

/// Custom Championship switch with emerald green track and white thumb.
class ChampionshipSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ChampionshipSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () {
          AudioService().hapticSelection();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: value
                ? ChampionshipColors.switchTrackActive
                : ChampionshipColors.switchTrackInactive,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 23,
              height: 23,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ChampionshipColors.switchThumb,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable Section Card container for Settings rows.
class ChampionshipSectionCard extends StatelessWidget {
  final String? sectionTitle;
  final String? trailingText;
  final List<Widget> children;

  const ChampionshipSectionCard({
    super.key,
    this.sectionTitle,
    this.trailingText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sectionTitle != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sectionTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChampionshipTypography.overline(
                      color: ChampionshipColors.goldLabel,
                      fontSize: 11,
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
                      textAlign: TextAlign.end,
                      style: ChampionshipTypography.subtitle(
                        fontSize: 11.5,
                        color: ChampionshipColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: ChampionshipColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ChampionshipColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: ChampionshipColors.cardShadow,
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Setting list row inside a ChampionshipSectionCard.
class ChampionshipSettingRow extends StatelessWidget {
  final ClubIconType icon;
  final String title;
  final String? subtitle;
  final Widget control;
  final VoidCallback? onTap;

  const ChampionshipSettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.control,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Green squircle icon tile
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: ChampionshipColors.greenGradient,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2414492E),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: ClubIcon(
                type: icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 13),

          // Middle: Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ChampionshipTypography.cardTitle(
                    fontSize: 14.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: ChampionshipTypography.subtitle(
                      fontSize: 11.5,
                      color: ChampionshipColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right: Control widget
          control,
        ],
      ),
    );

    if (onTap != null) {
      return ChampionshipPressable(
        onTap: onTap!,
        scaleFactor: 0.98,
        borderRadius: BorderRadius.circular(18),
        child: content,
      );
    }
    return content;
  }
}

/// 2-Column Grid Card for Theme Collection screen.
class ChampionshipThemeGridCard extends StatelessWidget {
  final ThemeCatalogItem item;
  final VoidCallback onTap;

  const ChampionshipThemeGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = item.isSelected;
    final bool isUnlocked = item.isUnlocked;

    return ChampionshipPressable(
      onTap: onTap,
      scaleFactor: 0.96,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ChampionshipColors.activeTint
              : ChampionshipColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ChampionshipColors.selectedGreenBorder
                : ChampionshipColors.cardBorder,
            width: isSelected ? 2.0 : 1.1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x281B5E3C),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : ChampionshipColors.cardShadow,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail preview with top badges
            Stack(
              children: [
                Center(
                  child: ThemeBoardPreview(
                    theme: item.theme,
                    size: 96,
                    isLocked: !isUnlocked,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                // Top-Left Badge (FREE / PREMIUM)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.isPremium
                          ? ChampionshipColors.goldPillBg
                          : const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.isPremium
                            ? ChampionshipColors.goldBorder
                            : const Color(0xFF9FD4B3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      item.isPremium ? 'PREMIUM' : 'FREE',
                      style: ChampionshipTypography.microBadge(
                        fontSize: 8.5,
                        color: item.isPremium
                            ? ChampionshipColors.gold
                            : const Color(0xFF1B6A45),
                      ),
                    ),
                  ),
                ),

                // Top-Right Badge: Green check when selected, lock when locked
                if (isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ChampionshipColors.primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3514492E),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (!isUnlocked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xD9000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, size: 9, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            item.priceDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Theme Name
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChampionshipTypography.cardTitle(
                fontSize: 13.5,
                color: isSelected
                    ? ChampionshipColors.primaryGreen
                    : ChampionshipColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1),

            // Short Color Description
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChampionshipTypography.subtitle(
                fontSize: 11,
                color: ChampionshipColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Championship background with warm cream tone and subtle blurred backdrop image.
class ChampionshipBackground extends StatelessWidget {
  final Widget child;

  const ChampionshipBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid warm cream/ivory base
        const DecoratedBox(
          decoration: BoxDecoration(
            color: ChampionshipColors.background,
          ),
        ),

        // Very subtle faded/blurred home_bg behind it
        Opacity(
          opacity: 0.05,
          child: Image.asset(
            'assets/images/backgrounds/home_bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.expand(),
          ),
        ),

        // Gentle warm radial glow for championship club depth
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.4),
                radius: 1.25,
                colors: [
                  Colors.white.withOpacity(0.40),
                  ChampionshipColors.background.withOpacity(0.15),
                  const Color(0x1573521E),
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // Forefront content
        child,
      ],
    );
  }
}
