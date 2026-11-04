import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'theme_collection_screen.dart';
import 'tutorial_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;
  AiDifficulty _difficulty = AiDifficulty.medium;
  BoardThemeType _theme = BoardThemeType.mahogany;

  @override
  void initState() {
    super.initState();
    _sfxEnabled = StorageService().getSfxEnabled();
    _musicEnabled = StorageService().getMusicEnabled();
    _hapticsEnabled = StorageService().getHapticsEnabled();
    _difficulty = StorageService().getAiDifficulty();
    _theme = StorageService().getBoardTheme();
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

  void _onThemeChanged(BoardThemeType theme) {
    if (!ThemeService().isThemeUnlocked(theme) && !DevOptions.enabled) {
      AudioService().hapticSelection();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navyPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.gold.withOpacity(0.4)),
          ),
          content: Text(
            '${AppColors.getThemeName(theme)} is a Premium Theme! (Purchases coming soon)',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFAF6EF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }
    AudioService().hapticSelection();
    setState(() => _theme = theme);
    StorageService().setBoardTheme(theme);
  }

  void _showRulesDialog() {
    AudioService().hapticSelection();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 372),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.gold,
              width: 1.2,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x1814243B),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              const BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
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
                        color: AppColors.gold.withOpacity(0.14),
                      ),
                      child: const ClubIcon(
                        type: ClubIconType.rules,
                        color: AppColors.goldLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CLUB RULES',
                        style: GoogleFonts.outfit(
                          color: AppColors.ivory,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
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
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.bgDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'GOT IT',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
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
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.secondary,
        accentTint: AppColors.getThemeAccent(_theme),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        ClubIconButton(
                          customIcon: ClubIconType.back,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'SETTINGS',
                            textAlign: TextAlign.center,
                            style: ClubTypography.displayMedium(),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Audio & Haptics Section (Clean Single-Line Toggles)
                          const ClubSectionHeader(title: 'AUDIO & HAPTICS'),
                          ClubCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                _toggleRow(
                                  customIcon: ClubIconType.sfx,
                                  title: 'Sound Effects',
                                  value: _sfxEnabled,
                                  onChanged: _onSfxChanged,
                                ),
                                Divider(
                                  color: AppColors.cardBorderSubtle,
                                  height: 1,
                                ),
                                _toggleRow(
                                  customIcon: ClubIconType.music,
                                  title: 'Background Music',
                                  value: _musicEnabled,
                                  onChanged: _onMusicChanged,
                                ),
                                Divider(
                                  color: AppColors.cardBorderSubtle,
                                  height: 1,
                                ),
                                _toggleRow(
                                  customIcon: ClubIconType.haptic,
                                  title: 'Haptic Vibration',
                                  value: _hapticsEnabled,
                                  onChanged: _onHapticsChanged,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. AI Difficulty Section (Clean Segmented Control)
                          const ClubSectionHeader(
                            title: 'AI DIFFICULTY',
                            trailingText: 'VS CPU Mode',
                          ),
                          ClubCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const ClubIcon(
                                      type: ClubIconType.vsCpu,
                                      color: AppColors.goldLight,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Opponent Skill Level',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ivory,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _difficulty == AiDifficulty.easy
                                          ? 'Casual'
                                          : (_difficulty == AiDifficulty.medium
                                              ? 'Balanced'
                                              : 'Pro & Banks'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Unified Segmented Pill Control
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _difficultySegment(
                                        label: 'Easy',
                                        diff: AiDifficulty.easy,
                                      ),
                                      _difficultySegment(
                                        label: 'Medium',
                                        diff: AiDifficulty.medium,
                                      ),
                                      _difficultySegment(
                                        label: 'Hard',
                                        diff: AiDifficulty.hard,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 3. Board Themes Section (Direct Cards — No Outer Wrapper Box)
                          ClubSectionHeader(
                            title: 'BOARD THEMES',
                            trailingText: AppColors.getThemeName(_theme),
                          ),
                          Row(
                            children: [
                              _themeCard(
                                name: 'Mahogany',
                                sub: 'Classic Wood',
                                theme: BoardThemeType.mahogany,
                              ),
                              const SizedBox(width: 8),
                              _themeCard(
                                name: 'Emerald',
                                sub: 'Club Teal',
                                theme: BoardThemeType.emerald,
                              ),
                              const SizedBox(width: 8),
                              _themeCard(
                                name: 'Midnight',
                                sub: 'Dark Lounge',
                                theme: BoardThemeType.midnight,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              AudioService().hapticSelection();
                              Navigator.of(context)
                                  .push(
                                ClubPageRoute(
                                  page: const ThemeCollectionScreen(),
                                  reducedMotion:
                                      ClubMotion.isReducedMotion(context),
                                ),
                              )
                                  .then((_) {
                                if (mounted) {
                                  setState(() {
                                    _theme = StorageService().getBoardTheme();
                                  });
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.cardBorderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const ClubIcon(
                                    type: ClubIconType.school,
                                    size: 16,
                                    color: AppColors.goldLight,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Explore All 11 Table Themes & Unlocks',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ivory,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppColors.goldLight,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 4. Club Handbook (Compact 2-Column Row)
                          const ClubSectionHeader(title: 'CLUB HANDBOOK'),
                          Row(
                            children: [
                              Expanded(
                                child: _handbookButton(
                                  customIcon: ClubIconType.school,
                                  label: 'How to Play',
                                  onTap: () {
                                    AudioService().hapticSelection();
                                    TutorialDialog.show(context);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _handbookButton(
                                  customIcon: ClubIconType.rules,
                                  label: 'Club Rules',
                                  onTap: _showRulesDialog,
                                ),
                              ),
                            ],
                          ),

                          // 5. Developer Testing Options (Easily toggled off via DevOptions.enabled)
                          if (DevOptions.enabled) ...[
                            const SizedBox(height: 20),
                            DevThemeTesterCard(
                              onStateChanged: () {
                                if (mounted) {
                                  setState(() {
                                    _theme = StorageService().getBoardTheme();
                                  });
                                }
                              },
                            ),
                          ],

                          const SizedBox(height: 20),
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
    );
  }

  Widget _toggleRow({
    required ClubIconType customIcon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClubIcon(type: customIcon, color: AppColors.goldLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ivory,
                ),
              ),
            ),
            ClubToggleSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultySegment({
    required String label,
    required AiDifficulty diff,
  }) {
    final bool isSelected = _difficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onDifficultyChanged(diff),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF0CA68), Color(0xFFC89828)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0x28C89828),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF141C28)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeCard({
    required String name,
    required String sub,
    required BoardThemeType theme,
  }) {
    final bool isSelected = _theme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onThemeChanged(theme),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? const Color(0xFFFFFDF8) : const Color(0xFFFAF8F5),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : AppColors.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x24D4AF37)
                    : const Color(0x0A182436),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    BoardSurfaceThumbnail(
                      theme: theme,
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF0D9488)
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: const Color(0xFFD4AF37),
                    ),
                    child: const Center(
                      child: ClubIcon(
                        type: ClubIconType.check,
                        size: 11,
                        color: Colors.white,
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

  Widget _handbookButton({
    required ClubIconType customIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              const BoxShadow(
                color: Color(0x1014243B),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              const BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClubIcon(type: customIcon, color: AppColors.goldLight, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
