import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

/// Developer Testing Configuration & Runtime Debug Tooling.
///
/// Controls debug theme unlocking and preview features.
/// Overrides are strictly separated from genuine purchase entitlements
/// and completely disabled in production/release builds.
class DevOptions {
  /// Master toggle for developer options.
  /// Set to `false` (or run in release mode) to completely hide developer options from all screens.
  static const bool enabled = !kReleaseMode;
}

/// Embedded developer card for testing theme unlocks and visual finishes.
class DevThemeTesterCard extends StatelessWidget {
  final VoidCallback? onStateChanged;

  const DevThemeTesterCard({super.key, this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    if (!DevOptions.enabled) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1ADB9E14),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5993B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.developer_mode,
                  color: Color(0xFF14243B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVELOPER THEME TESTER',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF784F07),
                      ),
                    ),
                    Text(
                      'Debug testing tool (disabled in release mode)',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: const Color(0xFF9E6D13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => DevThemeTesterSheet(
                    onChanged: onStateChanged,
                  ),
                );
              },
              icon: const Icon(Icons.tune, size: 16),
              label: Text(
                'OPEN THEME TESTING PANEL',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5993B),
                foregroundColor: const Color(0xFF14243B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comprehensive testing bottom sheet allowing instant theme application,
/// mock unlocking, relocking, and gameplay verification.
class DevThemeTesterSheet extends StatefulWidget {
  final VoidCallback? onChanged;

  const DevThemeTesterSheet({super.key, this.onChanged});

  @override
  State<DevThemeTesterSheet> createState() => _DevThemeTesterSheetState();
}

class _DevThemeTesterSheetState extends State<DevThemeTesterSheet> {
  late BoardThemeType _currentTheme;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _currentTheme = StorageService().getBoardTheme();
  }

  Future<void> _setThemeDirectly(BoardThemeType theme) async {
    AudioService().hapticSelection();
    // Allow developer to equip and unlock for testing
    if (ThemeService().isThemePremium(theme)) {
      await ThemeService().devUnlockTheme(theme);
    }
    await StorageService().setBoardTheme(theme);
    setState(_refresh);
    widget.onChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          content: Text('Theme equipped: ${AppColors.getThemeName(theme)}'),
        ),
      );
    }
  }

  Future<void> _toggleThemeUnlock(BoardThemeType theme) async {
    AudioService().hapticSelection();
    if (ThemeService().isThemeUnlocked(theme)) {
      await ThemeService().devLockTheme(theme);
    } else {
      await ThemeService().devUnlockTheme(theme);
    }
    setState(_refresh);
    widget.onChanged?.call();
  }

  Future<void> _unlockAllThemes() async {
    AudioService().hapticCelebration();
    await ThemeService().devUnlockAllThemes();
    setState(_refresh);
    widget.onChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('All 8 Premium Themes Mock-Unlocked (Dev Override).'),
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    AudioService().hapticSelection();
    await ThemeService().devResetMockUnlocks();
    setState(_refresh);
    widget.onChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('Reset mock developer unlocks. Premium themes relocked.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ThemeService().getCatalogItems();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37), width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3314243B),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0C4B4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title & Close Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THEME TESTING CONSOLE',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: const Color(0xFF14243B),
                        ),
                      ),
                      Text(
                        'Active: ${AppColors.getThemeName(_currentTheme)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B6415),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Quick Automation Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _unlockAllThemes,
                      icon: const Icon(Icons.lock_open, size: 14),
                      label: Text(
                        'UNLOCK ALL PREMIUM',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137333),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetToDefault,
                      icon: const Icon(Icons.restart_alt, size: 14),
                      label: Text(
                        'RELOCK OVERRIDES',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                        side: const BorderSide(color: Color(0xFFB3261E)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'TAP THEME TO EQUIP DIRECTLY (LONG PRESS TO TOGGLE UNLOCK):',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable Theme Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: catalog.length,
                  itemBuilder: (context, index) {
                    final item = catalog[index];
                    final bool isEquipped = item.isSelected;
                    final bool isUnlocked = item.isUnlocked;
                    final bool isFree = item.isFree;

                    return GestureDetector(
                      onTap: () => _setThemeDirectly(item.theme),
                      onLongPress: isFree ? null : () => _toggleThemeUnlock(item.theme),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? const Color(0xFFFFF9E6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEquipped
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFFE2D9CC),
                            width: isEquipped ? 2.0 : 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ThemeBoardPreview(
                              theme: item.theme,
                              size: 42,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: isEquipped
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: const Color(0xFF14243B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isEquipped
                                    ? const Color(0xFFD4AF37)
                                    : (isUnlocked
                                        ? const Color(0xFFE6F4EA)
                                        : const Color(0xFFFEECEB)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isEquipped
                                    ? 'ACTIVE'
                                    : (isFree
                                        ? 'FREE'
                                        : (isUnlocked ? 'DEV UNLOCKED' : 'LOCKED')),
                                style: GoogleFonts.outfit(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: isEquipped
                                      ? const Color(0xFF14243B)
                                      : (isUnlocked
                                          ? const Color(0xFF137333)
                                          : const Color(0xFFB3261E)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
