import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/championship_theme.dart';
import '../core/championship_widgets.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'theme_collection_screen.dart';
import 'tutorial_dialog.dart';

/// Redesigned Settings Screen for "Carrom Zone".
/// Pure UI/UX redesign: matches the Championship Club warm cream & emerald green design system,
/// 60-30-10 color balance, clean white cards with light neutral borders.
/// ZERO changes to game logic or service layers.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;
  AiDifficulty _difficulty = AiDifficulty.medium;
  BoardThemeType _theme = BoardThemeType.mahogany;

  // Visual placeholders for UI specification with TODOs (no new logic added)
  bool _aimGuideEnabled = true; // TODO: connect when aim guide persistence is added
  bool _coinShadowsEnabled = true; // TODO: connect when shadow toggle persistence is added
  bool _reduceAnimations = false; // TODO: connect when reduced motion preference is persisted
  int _strikerControlIndex = 0; // 0: Slider, 1: Drag // TODO: connect when striker control preference is added

  AnimationController? _entranceController;

  @override
  void initState() {
    super.initState();
    _sfxEnabled = StorageService().getSfxEnabled();
    _musicEnabled = StorageService().getMusicEnabled();
    _hapticsEnabled = StorageService().getHapticsEnabled();
    _difficulty = StorageService().getAiDifficulty();
    _theme = StorageService().getBoardTheme();
    _initEntranceController();
  }

  void _initEntranceController() {
    _entranceController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController?.dispose();
    super.dispose();
  }

  void _onSfxChanged(bool val) {
    setState(() => _sfxEnabled = val);
    AudioService().sfxEnabled = val;
    StorageService().setSfxEnabled(val);
    if (val) AudioService().playHit();
  }

  void _onMusicChanged(bool val) {
    setState(() => _musicEnabled = val);
    AudioService().musicEnabled = val;
    StorageService().setMusicEnabled(val);
    if (val) {
      AudioService().playBgm();
    } else {
      AudioService().pauseBgm();
    }
  }

  void _onHapticsChanged(bool val) {
    setState(() => _hapticsEnabled = val);
    AudioService().hapticsEnabled = val;
    StorageService().setHapticsEnabled(val);
    if (val) AudioService().hapticMedium();
  }

  void _onDifficultyChanged(AiDifficulty diff) {
    AudioService().hapticSelection();
    setState(() => _difficulty = diff);
    StorageService().setAiDifficulty(diff);
  }

  void _openTutorial() {
    AudioService().hapticSelection();
    TutorialDialog.show(context);
  }

  void _openThemeCollection() {
    AudioService().hapticSelection();
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    Navigator.of(context).push(
      ClubPageRoute(
        page: const ThemeCollectionScreen(),
        reducedMotion: reducedMotion,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _theme = StorageService().getBoardTheme();
        });
      }
    });
  }

  void _showRulesDialog() {
    AudioService().hapticSelection();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ChampionshipColors.cardSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: ChampionshipColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: ChampionshipColors.floatingDockShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: ChampionshipColors.greenGradient,
                      ),
                      child: const ClubIcon(
                        type: ClubIconType.rules,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CLUB RULES',
                        style: ChampionshipTypography.brandTitle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ruleItem(
                  'Match Objective',
                  'Pocket all 9 of your assigned Carrom pieces (White or Black) before your opponent to win the round.',
                ),
                const SizedBox(height: 10),
                _ruleItem(
                  'Covering the Queen (+3 pts)',
                  'After pocketing the Red Queen, cover it by pocketing one of your own pieces on the same or immediate next shot.',
                ),
                const SizedBox(height: 10),
                _ruleItem(
                  'Striker Fouls & Penalties',
                  'Pocketing the striker returns one of your pocketed coins to the center and passes your turn.',
                ),
                const SizedBox(height: 10),
                _ruleItem(
                  'Turn Continuation',
                  'Pocketing at least one of your own pieces without fouling grants another consecutive shot.',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ChampionshipColors.greenGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ChampionshipColors.greenButtonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'GOT IT',
                        style: ChampionshipTypography.exploreButtonText(fontSize: 12),
                      ),
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

  Widget _ruleItem(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChampionshipColors.backgroundAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChampionshipColors.cardBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ChampionshipTypography.cardTitle(
              fontSize: 13,
              color: ChampionshipColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: ChampionshipTypography.subtitle(
              fontSize: 12,
              color: ChampionshipColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedItem({required int index, required Widget child}) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);
    final controller = _entranceController;
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
          // Bottom navbar hata diya, is liye Stack ki zarurat nahi rahi
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Shared Page Header
                    _animatedItem(
                      index: 0,
                      child: ChampionshipAppHeader(
                        title: 'CLUB SETTINGS',
                        subtitle: 'PREFERENCES & CONTROLS',
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),

                    // Scrollable Sections
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        // Bottom 24: navbar nahi hai to bari padding ki zarurat nahi
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. AUDIO & HAPTICS Section
                            _animatedItem(
                              index: 1,
                              child: ChampionshipSectionCard(
                                sectionTitle: 'AUDIO & HAPTICS',
                                children: [
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.sfx,
                                    title: 'Sound Effects',
                                    subtitle: 'Tactile strike & collision audio',
                                    control: ChampionshipSwitch(
                                      value: _sfxEnabled,
                                      onChanged: _onSfxChanged,
                                    ),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.music,
                                    title: 'Background Music',
                                    subtitle: 'Acoustic lounge atmosphere',
                                    control: ChampionshipSwitch(
                                      value: _musicEnabled,
                                      onChanged: _onMusicChanged,
                                    ),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.haptic,
                                    title: 'Haptic Vibration',
                                    subtitle: 'Physical strike impulse feedback',
                                    control: ChampionshipSwitch(
                                      value: _hapticsEnabled,
                                      onChanged: _onHapticsChanged,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 2. AI DIFFICULTY & GAMEPLAY Section
                            _animatedItem(
                              index: 2,
                              child: ChampionshipSectionCard(
                                sectionTitle: 'AI DIFFICULTY',
                                trailingText: 'VS CPU Mode',
                                children: [
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.vsCpu,
                                    title: 'Opponent Skill Level',
                                    subtitle: _difficulty == AiDifficulty.easy
                                        ? 'Casual & Relaxed'
                                        : (_difficulty == AiDifficulty.medium
                                            ? 'Balanced Tactical'
                                            : 'Championship Pro'),
                                    control: _buildDifficultySegment(),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.aimFlick,
                                    title: 'Aim Trajectory Line',
                                    subtitle: 'Show shot angle & rebound guide',
                                    control: ChampionshipSwitch(
                                      value: _aimGuideEnabled,
                                      onChanged: (val) {
                                        // TODO: connect when aim guide persistence is added
                                        setState(() => _aimGuideEnabled = val);
                                      },
                                    ),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.strikerPosition,
                                    title: 'Striker Control Style',
                                    subtitle: 'Baseline positioning interaction',
                                    control: _buildControlStyleSegment(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 3. BOARD THEMES Showcase Card
                            _animatedItem(
                              index: 3,
                              child: ChampionshipSectionCard(
                                sectionTitle: 'BOARD THEMES',
                                trailingText: AppColors.getThemeName(_theme),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: ChampionshipColors.cardBorder,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: ThemeBoardPreview(
                                            theme: _theme,
                                            size: 50,
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppColors.getThemeName(_theme),
                                                style: ChampionshipTypography.themeTitle(fontSize: 15),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${AppColors.getThemeSubtitle(_theme)} • 11 Table Themes',
                                                style: ChampionshipTypography.subtitle(fontSize: 11.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: ChampionshipColors.greenGradient,
                                            borderRadius: BorderRadius.circular(999),
                                            boxShadow: ChampionshipColors.greenButtonShadow,
                                          ),
                                          child: InkWell(
                                            onTap: _openThemeCollection,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'EXPLORE',
                                                  style: ChampionshipTypography.exploreButtonText(fontSize: 10.5),
                                                ),
                                                const SizedBox(width: 3),
                                                const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
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
                            const SizedBox(height: 18),

                            // 4. DISPLAY Section
                            _animatedItem(
                              index: 4,
                              child: ChampionshipSectionCard(
                                sectionTitle: 'DISPLAY',
                                children: [
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.coin,
                                    title: 'Show Coin Shadows',
                                    subtitle: 'Dynamic 3D woodgrain depth',
                                    control: ChampionshipSwitch(
                                      value: _coinShadowsEnabled,
                                      onChanged: (val) {
                                        // TODO: connect when shadow toggle persistence is added
                                        setState(() => _coinShadowsEnabled = val);
                                      },
                                    ),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.restart,
                                    title: 'Reduce Animations',
                                    subtitle: 'Simplify UI motion effects',
                                    control: ChampionshipSwitch(
                                      value: _reduceAnimations,
                                      onChanged: (val) {
                                        // TODO: connect when reduced motion preference is persisted
                                        setState(() => _reduceAnimations = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 5. ABOUT & HANDBOOK Section
                            _animatedItem(
                              index: 5,
                              child: ChampionshipSectionCard(
                                sectionTitle: 'ABOUT & HANDBOOK',
                                children: [
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.school,
                                    title: 'How to Play',
                                    subtitle: 'Interactive 5-step carrom tutorial',
                                    control: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: ChampionshipColors.textSecondary,
                                    ),
                                    onTap: _openTutorial,
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.rules,
                                    title: 'Club Rules',
                                    subtitle: 'Official tournament rulebook',
                                    control: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: ChampionshipColors.textSecondary,
                                    ),
                                    onTap: _showRulesDialog,
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.trophy,
                                    title: 'App Version',
                                    subtitle: 'Carrom Zone v1.0.0+1',
                                    control: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ChampionshipColors.backgroundAlt,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ChampionshipColors.cardBorder,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'RELEASE',
                                        style: ChampionshipTypography.microBadge(
                                          fontSize: 9,
                                          color: ChampionshipColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _divider(),
                                  ChampionshipSettingRow(
                                    icon: ClubIconType.queen,
                                    title: 'Privacy Policy',
                                    subtitle: 'Data protection & club terms',
                                    control: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: ChampionshipColors.textSecondary,
                                    ),
                                    onTap: () {
                                      // TODO: Open Privacy Policy web URL
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // 6. Developer Testing Options (Debug only)
                            if (DevOptions.enabled) ...[
                              const SizedBox(height: 18),
                              _animatedItem(
                                index: 6,
                                child: DevThemeTesterCard(
                                  onStateChanged: () {
                                    if (mounted) {
                                      setState(() {
                                        _theme = StorageService().getBoardTheme();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: ChampionshipColors.cardBorderSubtle,
    );
  }

  Widget _buildDifficultySegment() {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: ChampionshipColors.backgroundAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ChampionshipColors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _difficultyChip(label: 'Easy', diff: AiDifficulty.easy),
          _difficultyChip(label: 'Med', diff: AiDifficulty.medium),
          _difficultyChip(label: 'Hard', diff: AiDifficulty.hard),
        ],
      ),
    );
  }

  Widget _difficultyChip({
    required String label,
    required AiDifficulty diff,
  }) {
    final bool isSelected = _difficulty == diff;
    return GestureDetector(
      onTap: () => _onDifficultyChanged(diff),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isSelected ? ChampionshipColors.greenGradient : null,
          boxShadow: isSelected ? ChampionshipColors.greenButtonShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : ChampionshipColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildControlStyleSegment() {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: ChampionshipColors.backgroundAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ChampionshipColors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlStyleChip(label: 'Slider', index: 0),
          _controlStyleChip(label: 'Drag', index: 1),
        ],
      ),
    );
  }

  Widget _controlStyleChip({required String label, required int index}) {
    final bool isSelected = _strikerControlIndex == index;
    return GestureDetector(
      onTap: () {
        AudioService().hapticSelection();
        // TODO: connect when striker control preference is added
        setState(() => _strikerControlIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isSelected ? ChampionshipColors.greenGradient : null,
          boxShadow: isSelected ? ChampionshipColors.greenButtonShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : ChampionshipColors.textSecondary,
          ),
        ),
      ),
    );
  }
}