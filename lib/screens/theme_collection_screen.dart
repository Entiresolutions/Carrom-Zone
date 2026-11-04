import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

/// Dedicated, premium Theme Collection screen.
///
/// Features high-fidelity in-game previews for all 11 Carrom Zone themes,
/// clean Free vs. Premium classification, locked states, and smooth theme activation.
class ThemeCollectionScreen extends StatefulWidget {
  const ThemeCollectionScreen({super.key});

  @override
  State<ThemeCollectionScreen> createState() => _ThemeCollectionScreenState();
}

class _ThemeCollectionScreenState extends State<ThemeCollectionScreen> {
  late BoardThemeType _selectedTheme;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    _selectedTheme = StorageService().getBoardTheme();
  }

  void _selectTheme(ThemeCatalogItem item) {
    if (!item.isUnlocked) {
      AudioService().hapticSelection();
      _showPurchaseUnavailableDialog(item);
      return;
    }

    AudioService().hapticSelection();
    AudioService().playHit();
    StorageService().setBoardTheme(item.theme);
    setState(() {
      _selectedTheme = item.theme;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF14243B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
        ),
        content: Row(
          children: [
            const ClubIcon(
              type: ClubIconType.check,
              size: 18,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.name} activated for play!',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFAF6EF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPurchaseUnavailableDialog(ThemeCatalogItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2814243B),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemeBoardPreview(
                theme: item.theme,
                size: 72,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(height: 14),
              Text(
                item.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.ivory,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PREMIUM TABLE THEME • ${item.priceDisplay}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'In-app purchases are coming soon! Google Play Billing integration is currently in preparation.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (DevOptions.enabled) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await ThemeService().devUnlockTheme(item.theme);
                          await StorageService().setBoardTheme(item.theme);
                          setState(_loadState);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5993B),
                          foregroundColor: const Color(0xFF14243B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'DEV UNLOCK',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ThemeCatalogItem> items = ThemeService().getCatalogItems();
    final freeItems = items.where((i) => i.isFree).toList();
    final premiumItems = items.where((i) => i.isPremium).toList();

    return Scaffold(
      body: ClubBackground(
        preset: ClubBackgroundPreset.secondary,
        accentTint: AppColors.getThemeAccent(_selectedTheme),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // 1. Top Bar
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'THEME COLLECTION',
                                textAlign: TextAlign.center,
                                style: ClubTypography.displayMedium(),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '11 Championship Table Themes',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (DevOptions.enabled)
                          ClubIconButton(
                            customIcon: ClubIconType.school,
                            tooltip: 'Dev Testing Console',
                            iconColor: const Color(0xFFD4AF37),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => DevThemeTesterSheet(
                                  onChanged: () {
                                    if (mounted) setState(_loadState);
                                  },
                                ),
                              );
                            },
                          )
                        else
                          const SizedBox(width: 38), // Balance back button
                      ],
                    ),
                  ),

                  // 2. Main Scrollable List
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Starter Themes Section
                          const ClubSectionHeader(
                            title: 'STARTER THEMES (FREE)',
                            trailingText: 'Always Unlocked',
                          ),
                          const SizedBox(height: 8),
                          ...freeItems.map(_buildThemeCard),

                          const SizedBox(height: 18),

                          // Premium Championship Themes Section
                          const ClubSectionHeader(
                            title: 'CHAMPIONSHIP THEMES (PREMIUM)',
                            trailingText: 'Exclusive Table Finishes',
                          ),
                          const SizedBox(height: 8),
                          ...premiumItems.map(_buildThemeCard),

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

  Widget _buildThemeCard(ThemeCatalogItem item) {
    final bool isSelected = item.isSelected;
    final bool isUnlocked = item.isUnlocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectTheme(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFFDF8) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : (isUnlocked
                      ? AppColors.cardBorder
                      : AppColors.cardBorderSubtle),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x24D4AF37)
                    : const Color(0x1014243B),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Color(0x35FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. In-game theme preview
                ThemeBoardPreview(
                  theme: item.theme,
                  size: 78,
                  isLocked: !isUnlocked,
                  borderRadius: BorderRadius.circular(14),
                ),

                const SizedBox(width: 14),

                // 2. Metadata & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isUnlocked
                                    ? AppColors.ivory
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Badge: Active / Free / Premium Price
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check,
                                    size: 11,
                                    color: Color(0xFF14243B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'ACTIVE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF14243B),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (!isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    size: 10,
                                    color: AppColors.goldLight,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.priceDisplay,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (item.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'FREE',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF137333),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getThemeAccent(item.theme),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.25,
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
