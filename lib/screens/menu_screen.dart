import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/championship_theme.dart';
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

/// Redesigned Championship Club Home Screen for "Carrom Zone".
/// Pure UI/UX redesign: premium warm cream background, crisp white cards,
/// thin gold borders, deep emerald green accents, elegant serif typography,
/// and floating bottom navigation dock.
/// ZERO changes to game logic, state models, or service layers.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  // ---- Layout constants (responsive tuning yahan se karein) ----
  // Bottom dock ke liye jagah (dock height + padding)
  static const double _dockSpace = 90.0;
  // Logo ke ilawa baqi content (cards + toggle + gaps) ki andaazan height.
  // Agar logo bohot chota/bara lage to is value ko 20-30 se kam/zyada karein.
  static const double _contentHeightEstimate = 430.0;
  static const double _logoMin = 100.0;
  static const double _logoMax = 220.0;

  BoardThemeType _currentTheme = BoardThemeType.mahogany;
  AiDifficulty _currentDifficulty = AiDifficulty.medium;
  CarromRuleset _selectedRuleset = CarromRuleset.classic;

  AnimationController? _entranceController;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initEntranceController();
  }

  void _initEntranceController() {
    _entranceController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    super.dispose();
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

  Widget _animatedItem({required int index, required Widget child}) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final AnimationController? controller = _entranceController;
    if (reducedMotion || controller == null) return child;

    final double start = (index * 0.08).clamp(0.0, 0.75);
    final double end = math.min(1.0, start + 0.45);
    final Animation<double> curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - curved.value) * 16.0),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    _initEntranceController();
    final bool isFreestyle = _selectedRuleset == CarromRuleset.freestyle;
    final bool isThemePremium = ThemeService().isThemePremium(_currentTheme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ChampionshipColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: ChampionshipBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Content
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: LayoutBuilder(
                      builder: (context, viewport) {
                        // Logo ka size: screen ki bachi hui height se tay hota hai
                        final double availableForLogo = viewport.maxHeight -
                            _dockSpace -
                            _contentHeightEstimate;
                        final double widthCap = viewport.maxWidth * 0.5;
                        final double logoSize = availableForLogo
                            .clamp(_logoMin, math.min(_logoMax, widthCap))
                            .toDouble();

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              18, 0, 18, _dockSpace),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Logo
                              _animatedItem(
                                index: 0,
                                child: _buildHeaderRow(logoSize),
                              ),
                              const SizedBox(height: 8),

                              // 2. Table Theme card
                              _animatedItem(
                                index: 4,
                                child: ChampionshipThemeCard(
                                  theme: _currentTheme,
                                  isPremium: isThemePremium,
                                  onTap: _openThemeCollection,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 3. Game mode toggle
                              _animatedItem(
                                index: 5,
                                child: ChampionshipSegmentedToggle(
                                  isClassic: !isFreestyle,
                                  onSelectClassic: () {
                                    if (isFreestyle) {
                                      AudioService().hapticSelection();
                                      setState(() => _selectedRuleset =
                                          CarromRuleset.classic);
                                    }
                                  },
                                  onSelectFreestyle: () {
                                    if (!isFreestyle) {
                                      AudioService().hapticSelection();
                                      setState(() => _selectedRuleset =
                                          CarromRuleset.freestyle);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 4. VS CPU
                              _animatedItem(
                                index: 6,
                                child: ChampionshipModeCard(
                                  icon: const ClubIcon(
                                    type: ClubIconType.vsCpu,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  title: 'VS CPU',
                                  subtitle: isFreestyle
                                      ? 'Race CPU to 160 pts • Any coin counts'
                                      : 'Test your tactical skills against AI',
                                  categoryTag: isFreestyle
                                      ? 'FREESTYLE POINTS • 160 TARGET'
                                      : 'SOLO PLAY • TACTICAL AI',
                                  badgeText:
                                      _currentDifficulty.name.toUpperCase(),
                                  onTap: () => _startGame(GameMode.vsCpu),
                                ),
                              ),
                              const SizedBox(height: 11),

                              // 5. PASS & PLAY
                              _animatedItem(
                                index: 7,
                                child: ChampionshipModeCard(
                                  icon: const TwoPeopleIcon(
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                  title: 'PASS & PLAY',
                                  subtitle: isFreestyle
                                      ? '2-Player Freestyle race to 160 pts'
                                      : 'Turn-based tabletop match on 1 device',
                                  categoryTag: isFreestyle
                                      ? 'LOCAL 2P • FREESTYLE 10/20/50'
                                      : 'LOCAL MULTIPLAYER • 2 PLAYERS',
                                  onTap: () =>
                                      _startGame(GameMode.passAndPlay),
                                ),
                              ),
                              const SizedBox(height: 11),

                              // 6. PRACTICE ARENA
                              _animatedItem(
                                index: 8,
                                child: ChampionshipModeCard(
                                  icon: const ClubIcon(
                                    type: ClubIconType.practice,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  hasNotificationDot: true,
                                  title: 'PRACTICE ARENA',
                                  subtitle:
                                      'Freestyle board to master angles & tricks',
                                  categoryTag: 'SOLO MASTERY • UNTIMED',
                                  onTap: () => _startGame(GameMode.practice),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bottom Navigation (Floating Pill Dock)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: ChampionshipBottomNav(
                          onOpenRules: _openTutorial,
                          onOpenThemes: _openThemeCollection,
                          onOpenSettings: _openSettings,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(double size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ChampionshipColors.cardBorder.withOpacity(0.6),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x155C4418),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: ClubCrestLogo(size: size),
          ),
        ),
      ],
    );
  }
}