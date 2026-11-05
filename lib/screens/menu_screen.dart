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

  void _startGame(GameMode mode, {AiDifficulty? difficulty}) {
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
          difficulty: difficulty ?? _currentDifficulty,
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

  void _onVsCpuTap() {
    AudioService().hapticSelection();
    _showDifficultyDialog();
  }

  void _showDifficultyDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DifficultySelectionDialog(
        currentDifficulty: _currentDifficulty,
        ruleset: _selectedRuleset,
        onDifficultyChosen: (chosenDiff) {
          StorageService().setAiDifficulty(chosenDiff);
          setState(() {
            _currentDifficulty = chosenDiff;
          });
          _startGame(GameMode.vsCpu, difficulty: chosenDiff);
        },
      ),
    );
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
                                  difficultyTag: _currentDifficulty.name.toUpperCase(),
                                  variant: _ModeCardVariant.goldPrimary,
                                  onTap: _onVsCpuTap,
                                ),
                                const SizedBox(height: 10),
                                _ModeActionCard(
                                  customIcon: ClubIconType.passAndPlay,
                                  title: 'PASS & PLAY',
                                  variant: _ModeCardVariant.navyPrimary,
                                  onTap: () => _startGame(GameMode.passAndPlay),
                                ),
                                const SizedBox(height: 10),
                                _ModeActionCard(
                                  customIcon: ClubIconType.practice,
                                  title: 'PRACTICE ARENA',
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

        // Brand Title Lockup
        Expanded(
          child: Text(
            'CARROM ZONE',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
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
    return RichText(
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
    );
  }

  Widget _buildThemePreviewCard() {
    final bool isFree = ThemeService().isThemeFree(_currentTheme);
    final String themeName = AppColors.getThemeName(_currentTheme);

    return _PressableCard(
      onTap: _openThemeCollection,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              size: 46,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),

            // Theme Name & Status Badge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      themeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ),
            const SizedBox(width: 10),

            // Action Affordance Pill
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
              subtitle: 'W:20 • B:10 • Q:50 • 160 Pts',
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF9), Color(0xFFF7F1E7)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2D6C3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1414243B),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0xA0FFFFFF),
            blurRadius: 2,
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
            customIcon: ClubIconType.themes,
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
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0x28D4C4AC),
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
  final String? difficultyTag;
  final _ModeCardVariant variant;
  final VoidCallback onTap;

  const _ModeActionCard({
    required this.customIcon,
    required this.title,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Handcrafted Squircle Badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: badgeGradient,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.22),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: widget.customIcon,
                      color: badgeIconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Difficulty Tag
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.difficultyTag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE5C370),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.difficultyTag!,
                            style: GoogleFonts.outfit(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: const Color(0xFF784F07),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

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
          scale: (_pressed && !reducedMotion) ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Luxury Ivory-Satin Button Container with Soft Depth
                AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _pressed
                          ? const [Color(0xFFFFF9EE), Color(0xFFF7EACD)]
                          : const [Color(0xFFFFFFFF), Color(0xFFF2EADC)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _pressed
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFFDDD2C0),
                      width: _pressed ? 1.5 : 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _pressed
                            ? const Color(0x35D4AF37)
                            : const Color(0x1014243B),
                        blurRadius: _pressed ? 10 : 5,
                        offset: const Offset(0, 2),
                      ),
                      const BoxShadow(
                        color: Color(0x90FFFFFF),
                        blurRadius: 1.5,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClubIcon(
                      type: widget.customIcon,
                      size: 24,
                      color: _pressed
                          ? const Color(0xFF8B6415)
                          : const Color(0xFF14243B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _pressed
                        ? const Color(0xFF8B6415)
                        : const Color(0xFF14243B),
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

class _DifficultySelectionDialog extends StatefulWidget {
  final AiDifficulty currentDifficulty;
  final CarromRuleset ruleset;
  final ValueChanged<AiDifficulty> onDifficultyChosen;

  const _DifficultySelectionDialog({
    required this.currentDifficulty,
    required this.ruleset,
    required this.onDifficultyChosen,
  });

  @override
  State<_DifficultySelectionDialog> createState() =>
      _DifficultySelectionDialogState();
}

class _DifficultySelectionDialogState
    extends State<_DifficultySelectionDialog> {
  late AiDifficulty _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFreestyle = widget.ruleset == CarromRuleset.freestyle;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Header Icon, Title & Close Button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.40),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: ClubIcon(
                      type: ClubIconType.vsCpu,
                      size: 24,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOOSE DIFFICULTY',
                        style: GoogleFonts.cinzel(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ivory,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFreestyle
                            ? 'Freestyle Points • Race to 160'
                            : 'Classic Carrom • Casual Points',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.woodLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AudioService().hapticSelection();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.woodLight,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 14),

            // Difficulty Cards (Easy, Medium, Hard)
            _difficultyOptionCard(
              difficulty: AiDifficulty.easy,
              title: 'EASY',
              tierLabel: 'NOVICE',
              tagColor: const Color(0xFF22C55E),
              description: 'Simple direct shots • Relaxed play • Beatable',
              statLabel: 'Direct pots only • Cushion banks disabled',
            ),
            const SizedBox(height: 10),
            _difficultyOptionCard(
              difficulty: AiDifficulty.medium,
              title: 'MEDIUM',
              tierLabel: 'CLUB PLAYER',
              tagColor: const Color(0xFFEAB308),
              description: 'Balanced accuracy • Moderate challenge',
              statLabel: 'Standard cuts • Limited cushion bank shots',
            ),
            const SizedBox(height: 10),
            _difficultyOptionCard(
              difficulty: AiDifficulty.hard,
              title: 'HARD',
              tierLabel: 'TOURNAMENT PRO',
              tagColor: const Color(0xFFEF4444),
              description: 'Tournament sharpness • Pro tactical defense',
              statLabel: 'Thin cut angles • Full cushion bank repertoire',
            ),

            const SizedBox(height: 18),

            // Start Match Button
            ElevatedButton(
              onPressed: () {
                AudioService().hapticSelection();
                Navigator.of(context).pop();
                widget.onDifficultyChosen(_selected);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'START MATCH (${_selected.name.toUpperCase()})',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
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

  Widget _difficultyOptionCard({
    required AiDifficulty difficulty,
    required String title,
    required String tierLabel,
    required Color tagColor,
    required String description,
    required String statLabel,
  }) {
    final bool isSelected = _selected == difficulty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AudioService().hapticSelection();
          setState(() => _selected = difficulty);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cardBgElevated : AppColors.cardBgLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.goldDark
                        : AppColors.woodLight.withOpacity(0.5),
                    width: isSelected ? 5.5 : 1.8,
                  ),
                  color: isSelected ? AppColors.goldLight : Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.goldDark : AppColors.ivory,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.5, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tagColor.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tierLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tagColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.ivory.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppColors.woodLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
