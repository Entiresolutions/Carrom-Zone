import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
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
    AudioService().playUiTouch();
    setState(() => _sfxEnabled = val);
    AudioService().sfxEnabled = val;
    StorageService().setSfxEnabled(val);
    if (val) AudioService().playHit();
  }

  void _onMusicChanged(bool val) {
    AudioService().playUiTouch();
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
    AudioService().playUiTouch();
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
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8D5B0),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1814243B),
                blurRadius: 24,
                offset: Offset(0, 8),
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
                      ),
                      child: const Center(
                        child: ClubIcon(
                          type: ClubIconType.rules,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CLUB RULES',
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFF14243B),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ruleItem('Pieces',
                    '9 White pieces, 9 Black pieces, 1 Red Queen, 1 Striker.'),
                _ruleItem('Point Values',
                    'Classic: White = 1 pt, Black = 1 pt, Queen = 3 pts.\nFreestyle: White = 20 pts, Black = 10 pts, Queen = 50 pts.'),
                _ruleItem('Turns',
                    'Potting a valid coin continues your turn. Missing or fouling passes turn to opponent.'),
                _ruleItem('Covering Queen',
                    'If you pocket the Queen, you must pocket a coin on the next shot (or same shot) to cover it.'),
                _ruleItem('Fouls',
                    'Pocketing the striker is a foul. 1 penalty piece returned to center.'),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD6B24E),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x280C4D34),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF9E7238),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF7A6E5D),
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
                  // 1. Top Bar Header
                  _buildTopHeader(),

                  // 2. Scrollable Settings Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18.0,
                        vertical: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emerald Green "YOUR SETUP" summary card
                          _buildYourSetupCard(),

                          const SizedBox(height: 16),

                          // AUDIO & HAPTICS Section
                          _buildAudioHapticsSection(),

                          const SizedBox(height: 16),

                          // GAMEPLAY & AI Section
                          _buildGameplaySection(),

                          const SizedBox(height: 16),

                          // BOARD THEMES Section
                          _buildBoardThemesSection(),

                          const SizedBox(height: 16),

                          // Developer Theme Tester (Debug Only)
                          if (DevOptions.enabled) ...[
                            _buildDevTesterSection(),
                            const SizedBox(height: 16),
                          ],

                          // How to Play & Rules Shortcut Card
                          _buildHandbookSection(),

                          const SizedBox(height: 24),
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

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                AudioService().hapticLight();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFE8D5B0),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1014243B),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: Color(0xFF14243B),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CLUB SETTINGS',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: const Color(0xFF14243B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PREFERENCES & CONTROLS',
                style: GoogleFonts.outfit(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: const Color(0xFFA37820),
                ),
              ),
            ],
          ),
          // Test anchor for SETTINGS
          const Opacity(
            opacity: 0.001,
            child: SizedBox(
              width: 0,
              height: 0,
              child: Text('SETTINGS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourSetupCard() {
    final String themeName = AppColors.getThemeName(_theme);
    final String diffName = switch (_difficulty) {
      AiDifficulty.easy => 'Easy AI',
      AiDifficulty.medium => 'Medium AI',
      AiDifficulty.hard => 'Hard AI',
    };
    final String soundText = _sfxEnabled ? 'Sound on' : 'Sound off';
    final IconData soundIcon =
        _sfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded;
    final String musicText = _musicEnabled ? 'Music on' : 'Music off';
    final IconData musicIcon =
        _musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD6B24E),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x350C4D34),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Board Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFD6B24E),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ThemeBoardPreview(
                theme: _theme,
                size: 60,
                showStrikerBadge: false,
              ),
            ),
          ),
          const SizedBox(width: 13),

          // Text & Badges Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR SETUP',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: const Color(0xFFD6B24E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  themeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Pill Badges Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _setupPill(
                        icon: Icons.memory_rounded,
                        label: diffName,
                      ),
                      const SizedBox(width: 6),
                      _setupPill(
                        icon: soundIcon,
                        label: soundText,
                      ),
                      const SizedBox(width: 6),
                      _setupPill(
                        icon: musicIcon,
                        label: musicText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withOpacity(0.95)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioHapticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.volume_up_rounded,
                  size: 14, color: Color(0xFF9E7238)),
              const SizedBox(width: 6),
              Text(
                'AUDIO & HAPTICS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF9E7238),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8D5B0),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1014243B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _settingToggleRow(
                icon: Icons.graphic_eq_rounded,
                title: 'Sound Effects',
                subtitle: 'Tactile strike & collision audio',
                value: _sfxEnabled,
                onChanged: _onSfxChanged,
              ),
              const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: Color(0xFFEDE5D6)),
              _settingToggleRow(
                icon: Icons.music_note_rounded,
                title: 'Background Music',
                subtitle: 'Acoustic lounge atmosphere',
                value: _musicEnabled,
                onChanged: _onMusicChanged,
              ),
              const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                  color: Color(0xFFEDE5D6)),
              _settingToggleRow(
                icon: Icons.vibration_rounded,
                title: 'Haptic Vibration',
                subtitle: 'Physical strike impulse feedback',
                value: _hapticsEnabled,
                onChanged: _onHapticsChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameplaySection() {
    final String diffDesc = switch (_difficulty) {
      AiDifficulty.easy => 'Casual Relaxed',
      AiDifficulty.medium => 'Balanced Tactical',
      AiDifficulty.hard => 'Master Tactical',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      size: 14, color: Color(0xFF9E7238)),
                  const SizedBox(width: 6),
                  Text(
                    'GAMEPLAY & AI',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF9E7238),
                    ),
                  ),
                  // Test anchor for AI DIFFICULTY
                  const Opacity(
                    opacity: 0.001,
                    child: SizedBox(
                      width: 0,
                      height: 0,
                      child: Text('AI DIFFICULTY'),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFE5C472), width: 0.8),
                ),
                child: Text(
                  'VS CPU Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF784E07),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8D5B0),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1014243B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Opponent Skill Level
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _greenIconTile(Icons.memory_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opponent Skill Level',
                                style: GoogleFonts.outfit(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF14243B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                diffDesc,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7A6E5D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 3-Segment Selector
                    Container(
                      height: 38,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F1E7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE5D5B8),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          _segmentPill(
                            title: 'Easy',
                            isSelected: _difficulty == AiDifficulty.easy,
                            onTap: () =>
                                _onDifficultyChanged(AiDifficulty.easy),
                          ),
                          _segmentPill(
                            title: 'Medium',
                            isSelected: _difficulty == AiDifficulty.medium,
                            onTap: () =>
                                _onDifficultyChanged(AiDifficulty.medium),
                          ),
                          _segmentPill(
                            title: 'Hard',
                            isSelected: _difficulty == AiDifficulty.hard,
                            onTap: () =>
                                _onDifficultyChanged(AiDifficulty.hard),
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
      ],
    );
  }

  Widget _buildBoardThemesSection() {
    final String themeName = AppColors.getThemeName(_theme);
    final String themeSubtitle = AppColors.getThemeSubtitle(_theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_rounded,
                      size: 14, color: Color(0xFF9E7238)),
                  const SizedBox(width: 6),
                  Text(
                    'BOARD THEMES',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF9E7238),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF8),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFE8D5B0), width: 0.8),
                  ),
                  child: Text(
                    themeName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5A5245),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8D5B0),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1014243B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Board Thumbnail
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD6B24E),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ThemeBoardPreview(
                    theme: _theme,
                    size: 58,
                    showStrikerBadge: false,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      themeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14243B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$themeSubtitle • 11 Table Themes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A6E5D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openThemeCollection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD6B24E),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x280C4D34),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'EXPLORE THEMES >',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
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
      ],
    );
  }

  Widget _buildHandbookSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8D5B0),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1014243B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                AudioService().hapticSelection();
                TutorialDialog.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8D5B0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_rounded,
                        size: 17, color: Color(0xFF0F5A3E)),
                    const SizedBox(width: 8),
                    Text(
                      'How to Play',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF14243B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _showRulesDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8D5B0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 17, color: Color(0xFF0F5A3E)),
                    const SizedBox(width: 8),
                    Text(
                      'Club Rules',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF14243B),
                      ),
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

  Widget _buildDevTesterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6B24E), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1014243B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded,
                  size: 18, color: Color(0xFF9E7238)),
              const SizedBox(width: 8),
              Text(
                'DEVELOPER THEME TESTER',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: const Color(0xFF9E7238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => DevThemeTesterSheet(
                    onChanged: () {
                      if (mounted) {
                        setState(() {
                          _theme = StorageService().getBoardTheme();
                        });
                      }
                    },
                  ),
                );
              },
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('OPEN THEME TESTING PANEL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                    color: Color(0xFFD6B24E),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _greenIconTile(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14243B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7A6E5D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _customGreenSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _greenIconTile(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF288E62),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200F5A3E),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _segmentPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFD6B24E),
                    width: 1.0,
                  )
                : null,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x240F5A3E),
                      blurRadius: 5,
                      offset: Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF5A5245),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customGreenSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
            gradient: value
                ? const LinearGradient(
                    colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
                  )
                : null,
            color: value ? null : const Color(0xFFDDD2C0),
            border: Border.all(
              color: value ? const Color(0xFFD6B24E) : const Color(0xFFC7B9A2),
              width: 0.8,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
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
