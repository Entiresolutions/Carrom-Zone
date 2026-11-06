import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/championship_widgets.dart';
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

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  BoardThemeType _currentTheme = BoardThemeType.mahogany;
  AiDifficulty _currentDifficulty = AiDifficulty.medium;
  CarromRuleset _selectedRuleset = CarromRuleset.classic;

  static bool _hasPlayedEntranceAnimation = false;
  bool _entranceCompleted = false;
  late final AnimationController _entranceController;
  late final List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _staggerAnimations = List.generate(7, (i) {
      final double begin = (i * 75.0) / 850.0;
      final double end = math.min(1.0, (i * 75.0 + 400.0) / 850.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );
    });

    if (_hasPlayedEntranceAnimation) {
      _entranceController.value = 1.0;
      _entranceCompleted = true;
    } else {
      _hasPlayedEntranceAnimation = true;
      _entranceController.forward().then((_) {
        if (mounted && !_entranceCompleted) {
          setState(() {
            _entranceCompleted = true;
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ClubMotion.isReducedMotion(context)) {
        _entranceController.value = 1.0;
        if (!_entranceCompleted) {
          setState(() {
            _entranceCompleted = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredItem({
    required int index,
    required Widget child,
  }) {
    if (_entranceCompleted) {
      return child;
    }

    final Animation<double> animation = _staggerAnimations[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (context, staticChild) {
        final double val = animation.value;
        final double opacity = val.clamp(0.0, 1.0);
        final double translateY = 20.0 * (1.0 - val);
        final double scale = 0.96 + (0.04 * val);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0.0, translateY),
            child: Transform.scale(
              scale: scale,
              child: staticChild,
            ),
          ),
        );
      },
      child: child,
    );
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
    final bool isFreestyle = _selectedRuleset == CarromRuleset.freestyle;
    final bool isThemePremium = ThemeService().isThemePremium(_currentTheme);

    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.home,
        accentTint: AppColors.gold,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Large Centered 3D Carrom Zone Logo
                          _buildStaggeredItem(
                            index: 0,
                            child: const Center(
                              child: CarromZoneLogo(
                                size: 195,
                                showShadow: true,
                              ),
                            ),
                          ),
                          // Test & semantic anchor for title and crest logo
                          const Opacity(
                            opacity: 0.001,
                            child: SizedBox(
                              width: 0,
                              height: 0,
                              child: Row(
                                children: [
                                  Text('CARROM ZONE'),
                                  ClubCrestLogo(size: 1),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. Compact Table Theme Preview Card
                          _buildStaggeredItem(
                            index: 1,
                            child: ChampionshipThemeCard(
                              theme: _currentTheme,
                              isPremium: isThemePremium,
                              onTap: _openThemeCollection,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. Game Mode Segmented Toggle (Classic Carrom vs Freestyle Points)
                          _buildStaggeredItem(
                            index: 2,
                            child: ChampionshipSegmentedToggle(
                              isClassic: !isFreestyle,
                              onSelectClassic: () {
                                if (isFreestyle) {
                                  AudioService().hapticSelection();
                                  setState(() =>
                                      _selectedRuleset = CarromRuleset.classic);
                                }
                              },
                              onSelectFreestyle: () {
                                if (!isFreestyle) {
                                  AudioService().hapticSelection();
                                  setState(() =>
                                      _selectedRuleset = CarromRuleset.freestyle);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 4. VS CPU
                          _buildStaggeredItem(
                            index: 3,
                            child: ChampionshipModeCard(
                              icon: const ClubIcon(
                                type: ClubIconType.vsCpu,
                                color: Colors.white,
                                size: 24,
                              ),
                              title: 'VS CPU',
                              subtitle: isFreestyle
                                  ? 'Race CPU to 160 pts • Any coin counts'
                                  : 'Test your tactical skills against AI',
                              categoryTag: isFreestyle
                                  ? 'FREESTYLE POINTS • 160 TARGET'
                                  : 'SOLO PLAY • TACTICAL AI',
                              badgeText: _currentDifficulty.name.toUpperCase(),
                              onTap: _onVsCpuTap,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 5. PASS & PLAY
                          _buildStaggeredItem(
                            index: 4,
                            child: ChampionshipModeCard(
                              icon: const TwoPeopleIcon(
                                size: 24,
                                color: Colors.white,
                              ),
                              title: 'PASS & PLAY',
                              subtitle: isFreestyle
                                  ? '2-Player Freestyle race to 160 pts'
                                  : 'Turn-based tabletop match on 1 device',
                              categoryTag: isFreestyle
                                  ? 'LOCAL 2P • FREESTYLE 10/20/50'
                                  : 'LOCAL MULTIPLAYER • 2 PLAYERS',
                              onTap: () => _startGame(GameMode.passAndPlay),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 6. PRACTICE ARENA
                          _buildStaggeredItem(
                            index: 5,
                            child: ChampionshipModeCard(
                              icon: const ClubIcon(
                                type: ClubIconType.practice,
                                color: Colors.white,
                                size: 24,
                              ),
                              hasNotificationDot: true,
                              title: 'PRACTICE ARENA',
                              subtitle:
                                  'Freestyle board to master angles & tricks',
                              categoryTag: 'SOLO MASTERY • UNTIMED',
                              onTap: () => _startGame(GameMode.practice),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),

                  // 7. Premium Floating Bottom Navigation Dock
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      math.max(12.0, MediaQuery.of(context).padding.bottom + 4.0),
                    ),
                    child: _buildStaggeredItem(
                      index: 6,
                      child: _buildBottomNavigationDock(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationDock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF8), Color(0xFFF7F1E6)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2D6C3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1614243B),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x80FFFFFF),
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
          _DockNavButton(
            customIcon: ClubIconType.themes,
            label: 'THEMES',
            onTap: _openThemeCollection,
          ),
          _DockNavButton(
            customIcon: ClubIconType.settings,
            label: 'SETTINGS',
            onTap: _openSettings,
          ),
        ],
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

    // Active/pressed: Deep emerald background with gold icon and subtle animation
    // Unpressed: Transparent/subtle cream with deep emerald outline icon & gold warmth
    final Color iconColor =
        _pressed ? const Color(0xFFFFDF7A) : const Color(0xFF143022);
    final Color labelColor =
        _pressed ? const Color(0xFFFFE6A3) : const Color(0xFF1B3D2F);

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
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            decoration: BoxDecoration(
              gradient: _pressed
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0F3D2E),
                        Color(0xFF09281E),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: _pressed
                  ? Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.2,
                    )
                  : Border.all(
                      color: Colors.transparent,
                      width: 1.2,
                    ),
              boxShadow: _pressed
                  ? const [
                      BoxShadow(
                        color: Color(0x350F3D2E),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClubIcon(
                  type: widget.customIcon,
                  size: 22,
                  color: iconColor,
                ),
                const SizedBox(height: 3.5),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: labelColor,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD9B86A).withOpacity(0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF281C08).withOpacity(0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF1B5E3C).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Header Icon Medallion, Title & Subtitle, and Elegant Close Button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E6742),
                        Color(0xFF13452B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFD9B86A).withOpacity(0.60),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2414492E),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: ClubIcon(
                      type: ClubIconType.vsCpu,
                      size: 22,
                      color: Colors.white,
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
                          color: const Color(0xFF12261B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFreestyle
                            ? 'Freestyle Points · Race to 160'
                            : 'Classic Carrom · Casual Points',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF7A6A55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AudioService().hapticSelection();
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3EBDD),
                        border: Border.all(
                          color: const Color(0xFFE2D7C4),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF5A4D3B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEDE5D5), height: 1),
            const SizedBox(height: 14),

            // Difficulty Cards (Easy, Medium, Hard)
            _difficultyOptionCard(
              difficulty: AiDifficulty.easy,
              title: 'EASY',
              tierLabel: 'NOVICE',
              badgeBg: const Color(0xFFEAF5EE),
              badgeBorder: const Color(0xFF9FD4B3),
              badgeText: const Color(0xFF1B6A45),
              selectedBadgeBg: const Color(0xFF1F5C3E),
              selectedBadgeBorder: const Color(0xFF6ED19F),
              selectedBadgeText: const Color(0xFFB4F3D0),
              description: 'Simple direct shots • Relaxed play • Beatable',
              statLabel: 'Direct pots only • Cushion banks disabled',
            ),
            const SizedBox(height: 10),
            _difficultyOptionCard(
              difficulty: AiDifficulty.medium,
              title: 'MEDIUM',
              tierLabel: 'CLUB PLAYER',
              badgeBg: const Color(0xFFFFF6E5),
              badgeBorder: const Color(0xFFE5C378),
              badgeText: const Color(0xFFA37820),
              selectedBadgeBg: const Color(0xFF574112),
              selectedBadgeBorder: const Color(0xFFD9B86A),
              selectedBadgeText: const Color(0xFFFFE6A0),
              description: 'Balanced accuracy • Moderate challenge',
              statLabel: 'Standard cuts • Limited cushion bank shots',
            ),
            const SizedBox(height: 10),
            _difficultyOptionCard(
              difficulty: AiDifficulty.hard,
              title: 'HARD',
              tierLabel: 'TOURNAMENT PRO',
              badgeBg: const Color(0xFFFDECEB),
              badgeBorder: const Color(0xFFF2A4A0),
              badgeText: const Color(0xFFC0392B),
              selectedBadgeBg: const Color(0xFF5A1F1E),
              selectedBadgeBorder: const Color(0xFFF29B96),
              selectedBadgeText: const Color(0xFFFFCBC7),
              description: 'Tournament sharpness • Pro tactical defense',
              statLabel: 'Thin cut angles • Full cushion bank repertoire',
            ),

            const SizedBox(height: 18),

            // Start Match Button
            ChampionshipPressable(
              onTap: () {
                AudioService().hapticSelection();
                Navigator.of(context).pop();
                widget.onDifficultyChosen(_selected);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E6742),
                      Color(0xFF13452B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD9B86A).withOpacity(0.55),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2814492E),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                        border: Border.all(
                          color: const Color(0xFFD9B86A).withOpacity(0.70),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'START MATCH (${_selected.name.toUpperCase()})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFFD9B86A),
                    ),
                  ],
                ),
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
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeText,
    required Color selectedBadgeBg,
    required Color selectedBadgeBorder,
    required Color selectedBadgeText,
    required String description,
    required String statLabel,
  }) {
    final bool isSelected = _selected == difficulty;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title difficulty, $tierLabel. $description',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioService().hapticSelection();
            setState(() => _selected = difficulty);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E6742),
                        Color(0xFF13452B),
                      ],
                    )
                  : null,
              color: isSelected ? null : const Color(0xFFFAF6EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD9B86A)
                    : const Color(0xFFE8E2D0),
                width: isSelected ? 1.6 : 1.1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x2814492E),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x0A5C4418),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD9B86A)
                          : const Color(0xFFC8BFAA),
                      width: isSelected ? 2.0 : 1.8,
                    ),
                    color: isSelected
                        ? const Color(0xFF123E27)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF7D97B),
                            ),
                          ),
                        )
                      : null,
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
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF12261B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? selectedBadgeBg : badgeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? selectedBadgeBorder
                                    : badgeBorder,
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              tierLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? selectedBadgeText
                                    : badgeText,
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
                          color: isSelected
                              ? const Color(0xFFD8EADE)
                              : const Color(0xFF12261B).withOpacity(0.80),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isSelected
                              ? const Color(0xFFB2D4BF)
                              : const Color(0xFF7A6A55),
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
      ),
    );
  }
}
