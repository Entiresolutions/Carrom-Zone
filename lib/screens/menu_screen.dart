import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'theme_collection_screen.dart';
import 'tutorial_dialog.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  BoardThemeType _currentTheme = BoardThemeType.mahogany;
  AiDifficulty _currentDifficulty = AiDifficulty.medium;
  CarromRuleset _selectedRuleset = CarromRuleset.classic;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    _currentTheme = StorageService().getBoardTheme();
    _currentDifficulty = StorageService().getAiDifficulty();
  }

  void _startGame(GameMode mode) {
    AudioService().hapticSelection();
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final CarromRuleset effectiveRuleset =
        mode == GameMode.practice ? CarromRuleset.classic : _selectedRuleset;
    Navigator.of(context)
        .push(
      ClubPageRoute(
        page: GameScreen(
          gameMode: mode,
          ruleset: effectiveRuleset,
        ),
        reducedMotion: reducedMotion,
      ),
    )
        .then((_) {
      if (mounted) {
        setState(_loadPreferences);
      }
    });
  }

  void _openTutorial() {
    AudioService().hapticSelection();
    TutorialDialog.show(context);
  }

  void _openSettings() {
    AudioService().hapticSelection();
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context)
        .push(
      ClubPageRoute(
        page: const SettingsScreen(),
        reducedMotion: reducedMotion,
      ),
    )
        .then((_) {
      if (mounted) {
        setState(_loadPreferences);
      }
    });
  }

  void _openThemeCollection() {
    AudioService().hapticSelection();
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context)
        .push(
      ClubPageRoute(
        page: const ThemeCollectionScreen(),
        reducedMotion: reducedMotion,
      ),
    )
        .then((_) {
      if (mounted) {
        setState(_loadPreferences);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.home,
        accentTint: AppColors.gold,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 1. Top Bar, Hero Section & Theme Preview
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTopBar(),
                                const SizedBox(height: 16),
                                _buildHeroBrandHeadline(),
                                const SizedBox(height: 14),
                                _buildThemePreviewCard(),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 2. Ruleset Selector & Three Premium Game Mode Cards
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildRulesetSelector(),
                                const SizedBox(height: 11),
                                _ModeActionCard(
                                  customIcon: ClubIconType.vsCpu,
                                  title: 'VS CPU',
                                  subtitle: _selectedRuleset ==
                                          CarromRuleset.freestyle
                                      ? 'Race CPU to 160 pts • Any coin counts'
                                      : 'Test your tactical skills against AI',
                                  categoryTag: _selectedRuleset ==
                                          CarromRuleset.freestyle
                                      ? 'FREESTYLE POINTS • 160 TARGET'
                                      : 'SOLO PLAY • TACTICAL AI',
                                  difficultyTag: _currentDifficulty.name.toUpperCase(),
                                  variant: _ModeCardVariant.goldPrimary,
                                  onTap: () => _startGame(GameMode.vsCpu),
                                ),
                                const SizedBox(height: 11),
                                _ModeActionCard(
                                  customIcon: ClubIconType.passAndPlay,
                                  title: 'PASS & PLAY',
                                  subtitle: _selectedRuleset ==
                                          CarromRuleset.freestyle
                                      ? '2-Player Freestyle race to 160 pts'
                                      : 'Turn-based tabletop match on 1 device',
                                  categoryTag: _selectedRuleset ==
                                          CarromRuleset.freestyle
                                      ? 'LOCAL 2P • FREESTYLE 10/20/50'
                                      : 'LOCAL MULTIPLAYER • 2 PLAYERS',
                                  variant: _ModeCardVariant.navyPrimary,
                                  onTap: () => _startGame(GameMode.passAndPlay),
                                ),
                                const SizedBox(height: 11),
                                _ModeActionCard(
                                  customIcon: ClubIconType.practice,
                                  title: 'PRACTICE ARENA',
                                  subtitle: 'Freestyle board to master angles & tricks',
                                  categoryTag: 'SOLO MASTERY • UNTIMED',
                                  variant: _ModeCardVariant.walnutPrimary,
                                  onTap: () => _startGame(GameMode.practice),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 3. Unified Bottom Navigation Dock
                            _buildBottomNavigationDock(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Crest Logo with subtle depth
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const ClubCrestLogo(size: 40),
        ),
        const SizedBox(width: 12),

        // Brand Title & Tagline Lockup
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CARROM ZONE',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'CHAMPIONSHIP CLUB EDITION',
                style: GoogleFonts.outfit(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
        ),

        // Top-Right Utility Action Buttons
        ClubIconButton(
          customIcon: ClubIconType.rules,
          tooltip: 'How to Play',
          size: 38,
          iconColor: AppColors.goldLight,
          onTap: _openTutorial,
        ),
        const SizedBox(width: 8),
        ClubIconButton(
          customIcon: ClubIconType.settings,
          tooltip: 'Settings',
          size: 38,
          iconColor: AppColors.goldLight,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _buildHeroBrandHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Micro Badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBgElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.40),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ClubIcon(
                type: ClubIconType.queen,
                size: 13,
                color: AppColors.goldLight,
              ),
              const SizedBox(width: 6),
              Text(
                'POINTS-BASED CLUB PLAY',
                style: GoogleFonts.outfit(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Hero Title with Controlled Typography Hierarchy
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Play Carrom\n',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                  height: 1.08,
                ),
              ),
              TextSpan(
                text: 'Your Way',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: AppColors.goldLight,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Realistic tabletop physics, tactile strikes & championship play',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemePreviewCard() {
    final bool isFree = ThemeService().isThemeFree(_currentTheme);
    final String themeName = AppColors.getThemeName(_currentTheme);
    final String themeSubtitle = AppColors.getThemeSubtitle(_currentTheme);

    return _PressableCard(
      onTap: _openThemeCollection,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1014243B),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color(0x35FFFFFF),
              blurRadius: 1.5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Exact Miniature In-Game Board Preview
            ThemeBoardPreview(
              theme: _currentTheme,
              size: 52,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),

            // Metadata: Overline, Theme Name & Subtitle
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
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isFree
                              ? const Color(0xFFEAF5EE)
                              : const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isFree
                                ? const Color(0xFF9FD4B3)
                                : const Color(0xFFE5C370),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFree
                                    ? const Color(0xFF1B6A45)
                                    : const Color(0xFF8B6415),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFree ? 'FREE' : 'PREMIUM',
                              style: GoogleFonts.outfit(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isFree
                                    ? const Color(0xFF1B6A45)
                                    : const Color(0xFF784F07),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    themeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$themeSubtitle • 11 Championship Boards',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Refined Action Affordance Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: AppColors.cardBgElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EXPLORE',
                    style: GoogleFonts.outfit(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const ClubIcon(
                    type: ClubIconType.chevronRight,
                    color: AppColors.goldLight,
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

  Widget _buildRulesetSelector() {
    final bool isClassic = _selectedRuleset == CarromRuleset.classic;
    return Container(
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E14243B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _rulesetOptionPill(
              title: 'CLASSIC CARROM',
              subtitle: 'White vs Black • +3 Queen',
              selected: isClassic,
              onTap: () {
                if (!isClassic) {
                  AudioService().hapticSelection();
                  setState(() => _selectedRuleset = CarromRuleset.classic);
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _rulesetOptionPill(
              title: 'FREESTYLE POINTS',
              subtitle: 'W:10 • B:20 • Q:50 • 160 Pts',
              selected: !isClassic,
              onTap: () {
                if (isClassic) {
                  AudioService().hapticSelection();
                  setState(() => _selectedRuleset = CarromRuleset.freestyle);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rulesetOptionPill({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8BD56), Color(0xFFC5993B)],
                )
              : null,
          color: selected ? null : AppColors.cardBgElevated,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.cardBorderSubtle,
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: selected
                    ? const Color(0xFF14243B)
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1.5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 9.0,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF1B3150)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationDock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1414243B),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x40FFFFFF),
            blurRadius: 1.5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          _DockNavButton(
            customIcon: ClubIconType.rules,
            label: 'RULES',
            onTap: _openTutorial,
          ),
          _dockDivider(),
          _DockNavButton(
            customIcon: ClubIconType.school,
            label: 'THEMES',
            onTap: _openThemeCollection,
          ),
          _dockDivider(),
          _DockNavButton(
            customIcon: ClubIconType.settings,
            label: 'SETTINGS',
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _dockDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.cardBorderSubtle,
    );
  }
}

enum _ModeCardVariant {
  goldPrimary,
  navyPrimary,
  walnutPrimary,
}

class _ModeActionCard extends StatefulWidget {
  final ClubIconType customIcon;
  final String title;
  final String subtitle;
  final String categoryTag;
  final String? difficultyTag;
  final _ModeCardVariant variant;
  final VoidCallback onTap;

  const _ModeActionCard({
    required this.customIcon,
    required this.title,
    required this.subtitle,
    required this.categoryTag,
    this.difficultyTag,
    required this.variant,
    required this.onTap,
  });

  @override
  State<_ModeActionCard> createState() => _ModeActionCardState();
}

class _ModeActionCardState extends State<_ModeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);

    // Controlled luxury palette tokens
    final (
      Gradient badgeGradient,
      Color badgeIconColor,
      Color accentColor,
    ) = switch (widget.variant) {
      _ModeCardVariant.goldPrimary => (
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE5B850), Color(0xFFB8851E)],
          ),
          const Color(0xFF14243B),
          AppColors.goldLight,
        ),
      _ModeCardVariant.navyPrimary => (
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF27446C), Color(0xFF14243B)],
          ),
          const Color(0xFFFAF6EF),
          const Color(0xFF1B3150),
        ),
      _ModeCardVariant.walnutPrimary => (
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFA0622D), Color(0xFF6E3E18)],
          ),
          const Color(0xFFFAF6EF),
          const Color(0xFF7A4B2A),
        ),
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: (_pressed && !reducedMotion) ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1214243B),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Handcrafted Squircle Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: badgeGradient,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: widget.customIcon,
                      color: badgeIconColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Subtitle & Micro Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.categoryTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (widget.difficultyTag != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFE5C370),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.difficultyTag!,
                                style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: const Color(0xFF784F07),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Action Trigger
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: AppColors.cardBgElevated,
                    border: Border.all(
                      color: accentColor.withOpacity(0.32),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: ClubIconType.play,
                      color: accentColor,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockNavButton extends StatefulWidget {
  final ClubIconType customIcon;
  final String label;
  final VoidCallback onTap;

  const _DockNavButton({
    required this.customIcon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_DockNavButton> createState() => _DockNavButtonState();
}

class _DockNavButtonState extends State<_DockNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          AudioService().hapticSelection();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: (_pressed && !reducedMotion) ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: widget.customIcon,
                      color: AppColors.goldLight,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _PressableCard({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: (_pressed && !reducedMotion) ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
