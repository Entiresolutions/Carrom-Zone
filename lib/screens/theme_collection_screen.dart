import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../core/dev_options.dart';
import '../models/piece_model.dart';
import '../services/ad_manager.dart';
import '../services/audio_service.dart';
import '../services/piece_asset_service.dart';
import '../services/storage_service.dart';
import '../services/striker_asset_service.dart';
import '../services/theme_service.dart';

/// Dedicated, premium Theme Collection screen in Emerald Green + Gold + Cream style.
class ThemeCollectionScreen extends StatefulWidget {
  const ThemeCollectionScreen({super.key});

  @override
  State<ThemeCollectionScreen> createState() => _ThemeCollectionScreenState();
}

class _ThemeCollectionScreenState extends State<ThemeCollectionScreen> {
  late BoardThemeType _selectedTheme;
  BoardThemeType? _loadingRewardedTheme;
  bool _isSwitchingTheme = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    _selectedTheme = StorageService().getBoardTheme();
  }

  void _showClubSnackbar(
    String message, {
    IconData icon = Icons.check_circle_rounded,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isWarning ? const Color(0xFF3E1C1A) : const Color(0xFF14243B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color:
                isWarning ? const Color(0xFFE57373) : const Color(0xFFD6B24E),
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  isWarning ? const Color(0xFFFFB4AB) : const Color(0xFFD6B24E),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFAF6EF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: isWarning ? 3 : 2),
      ),
    );
  }

  Future<void> _equipUnlockedTheme(
    ThemeCatalogItem item, {
    String? customToast,
    bool playWinChime = false,
  }) async {
    final bool equipped = await StorageService().setBoardTheme(item.theme);
    if (!equipped || !mounted) return;

    if (playWinChime) {
      AudioService().playWin();
      AudioService().hapticCelebration();
    } else {
      AudioService().playHit();
    }

    setState(() {
      _selectedTheme = item.theme;
    });

    _showClubSnackbar(
      customToast ?? '${item.name} activated for play!',
      icon: playWinChime
          ? Icons.workspace_premium_rounded
          : Icons.check_circle_rounded,
    );
  }

  Future<void> _handleRewardedThemeTap(ThemeCatalogItem item) async {
    if (_loadingRewardedTheme != null || _isSwitchingTheme) return;
    AudioService().hapticSelection();

    bool newlyUnlocked = false;
    await AdManager().showRewardedAd(
      loadTimeout: const Duration(seconds: 5),
      canPresent: () => mounted,
      onLoadingStart: () {
        if (mounted) {
          setState(() => _loadingRewardedTheme = item.theme);
        }
      },
      onLoadingEnd: () {
        if (mounted) {
          setState(() => _loadingRewardedTheme = null);
        }
      },
      onUserEarnedReward: () async {
        newlyUnlocked = await ThemeService().recordRewardedAdWatch(item.theme);
      },
      onAdDismissed: (bool rewardEarned) async {
        if (!mounted) return;
        if (!rewardEarned) {
          setState(() {});
          return;
        }

        if (newlyUnlocked || ThemeService().isThemeUnlocked(item.theme)) {
          // Automatically unlock & apply theme without triggering a back-to-back Interstitial Ad.
          await _equipUnlockedTheme(
            item,
            customToast: '${item.name} Unlocked!',
            playWinChime: true,
          );
        } else {
          final int watched = ThemeService().getWatchedRewardedAds(item.theme);
          AudioService().playHit();
          setState(() {});
          _showClubSnackbar(
            'Reward earned! ${item.name}: $watched/${item.requiredAds} ads watched',
            icon: Icons.play_circle_filled_rounded,
          );
        }
      },
      onAdUnavailable: () {
        _showClubSnackbar(
          'Ad not available right now. Please check your internet and try again.',
          icon: Icons.wifi_off_rounded,
          isWarning: true,
        );
      },
    );
  }

  void _selectTheme(ThemeCatalogItem item) {
    if (_loadingRewardedTheme != null || _isSwitchingTheme) return;

    if (!item.isUnlocked) {
      if (item.isRewarded) {
        _handleRewardedThemeTap(item);
        return;
      }
      AudioService().hapticSelection();
      _showPurchaseUnavailableDialog(item);
      return;
    }

    if (item.isSelected) {
      return;
    }

    AudioService().hapticSelection();
    _isSwitchingTheme = true;
    AdManager().showInterstitial(
      onComplete: () async {
        _isSwitchingTheme = false;
        if (!mounted) return;
        await _equipUnlockedTheme(item);
      },
    );
  }

  void _showPurchaseUnavailableDialog(ThemeCatalogItem item) {
    showDialog<void>(
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
            border: Border.all(color: const Color(0xFFE8D5B0), width: 1.4),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFD6B24E),
                        width: 1.2,
                      ),
                    ),
                    child: ThemeBoardPreview(
                      theme: item.theme,
                      size: 68,
                      showStrikerBadge: false,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StrikerAssetService.buildPreview(
                    theme: item.theme,
                    size: 54,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PieceAssetService.buildPreview(
                            theme: item.theme,
                            type: PieceType.white,
                            size: 26,
                          ),
                          const SizedBox(width: 4),
                          PieceAssetService.buildPreview(
                            theme: item.theme,
                            type: PieceType.black,
                            size: 26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      PieceAssetService.buildPreview(
                        theme: item.theme,
                        type: PieceType.queen,
                        size: 26,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: const Color(0xFF14243B),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5C472), width: 0.8),
                ),
                child: Text(
                  'PREMIUM TABLE THEME • ${item.priceDisplay}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF784E07),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF7A6E5D),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEADFCF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: Color(0xFF0F5A3E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'In-app purchases are coming soon! Google Play Billing integration is currently in preparation.',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF6B6050),
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
                        side: const BorderSide(color: Color(0xFFE2D6C3)),
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
                          color: const Color(0xFF14243B),
                          letterSpacing: 0.6,
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
                          backgroundColor: const Color(0xFF0F5A3E),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFFD6B24E),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          'DEV UNLOCK',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
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
    final rewardedItems = items.where((i) => i.isRewarded).toList();
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
                        _buildBackButton(),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'THEME COLLECTION',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFF14243B),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'CHAMPIONSHIP TABLE STYLING',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: const Color(0xFFA37820),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (DevOptions.enabled)
                          _buildDevTesterButton()
                        else
                          const SizedBox(width: 40), // Balance back button
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
                          // Starter Free Theme Section
                          _buildSectionHeader('STARTER THEME (FREE)'),
                          const SizedBox(height: 8),
                          ...freeItems.map(_buildThemeCard),

                          const SizedBox(height: 16),

                          // Rewarded-Ad Unlockable Themes Section
                          _buildSectionHeader('REWARDED CLUB THEMES (WATCH ADS)'),
                          const SizedBox(height: 8),
                          ...rewardedItems.map(_buildThemeCard),

                          const SizedBox(height: 16),

                          // Premium Championship Themes Section
                          _buildSectionHeader('CHAMPIONSHIP THEMES (PREMIUM)'),
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        AudioService().hapticSelection();
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
            color: Color(0xFF14243B),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildDevTesterButton() {
    return GestureDetector(
      onTap: () {
        AudioService().hapticSelection();
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
            Icons.tune_rounded,
            color: Color(0xFF0F5A3E),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: const Color(0xFF9E7238),
        ),
      ),
    );
  }

  Widget _buildThemeCard(ThemeCatalogItem item) {
    final bool isSelected = item.isSelected;
    final bool isUnlocked = item.isUnlocked;
    final bool isLockedRewarded = item.isRewarded && !isUnlocked;
    final bool isLoadingThis = _loadingRewardedTheme == item.theme;

    final String subtitleText;
    if (isLockedRewarded) {
      subtitleText = isLoadingThis
          ? 'Loading rewarded ad...'
          : 'Watch ${item.requiredAds} Ads to Unlock • ${item.watchedAds}/${item.requiredAds}';
    } else if (item.isRewarded && isUnlocked) {
      subtitleText = isSelected ? 'Unlocked • Selected' : 'Unlocked • Club Edition';
    } else if (item.isFree) {
      subtitleText = 'Starter Table • Free Unlock';
    } else {
      subtitleText = 'Championship Club Edition';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectTheme(item),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFFFFF)
                : const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F5A3E)
                  : (isLockedRewarded
                      ? const Color(0xFFD9B86A)
                      : const Color(0xFFE8D5B0)),
              width: isSelected ? 1.8 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x200F5A3E)
                    : const Color(0x1014243B),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Color(0x60FFFFFF),
                blurRadius: 1.5,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. In-game theme preview thumbnail with golden border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected || isLockedRewarded
                          ? const Color(0xFFD6B24E)
                          : const Color(0xFFE2D6C3),
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ThemeBoardPreview(
                    theme: item.theme,
                    size: 52,
                    isLocked: !isUnlocked,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),

                const SizedBox(width: 14),

                // 2. Theme Name, Metadata & Rewarded Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked
                              ? const Color(0xFF14243B)
                              : const Color(0xFF3E3529),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight:
                              isLockedRewarded ? FontWeight.w600 : FontWeight.w500,
                          color: isLockedRewarded
                              ? const Color(0xFF8B6415)
                              : const Color(0xFF7A6E5D),
                        ),
                      ),
                      if (isLockedRewarded) ...[
                        const SizedBox(height: 6),
                        _buildRewardProgressBar(item.rewardProgress),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 3. Status Badge / Interactive Watch Ad Pill
                _buildStatusIndicator(
                  item,
                  isSelected,
                  isUnlocked,
                  isLoadingThis: isLoadingThis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardProgressBar(double progress) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6D2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE0CCA4),
          width: 0.6,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double fillWidth =
                (constraints.maxWidth * progress.clamp(0.0, 1.0));
            return Stack(
              children: [
                if (fillWidth > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: fillWidth,
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF146C49),
                          Color(0xFFD6B24E),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    ThemeCatalogItem item,
    bool isSelected,
    bool isUnlocked, {
    bool isLoadingThis = false,
  }) {
    if (isSelected) {
      // Emerald Green ACTIVE badge with golden checkmark
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
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
            const Icon(
              Icons.check_rounded,
              size: 13,
              color: Color(0xFFD6B24E),
            ),
            const SizedBox(width: 4),
            Text(
              'ACTIVE',
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    if (!isUnlocked && item.isRewarded) {
      // Interactive Gold/Emerald WATCH AD pill button
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF146C49), Color(0xFF0C4D34)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD6B24E),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x280C4D34),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isLoadingThis
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFDF7A)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    size: 14,
                    color: Color(0xFFFFDF7A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.watchedAds}/${item.requiredAds}',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
      );
    }

    if (!isUnlocked) {
      // Gold/Amber LOCKED badge with price
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5C472),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 11,
              color: Color(0xFF784E07),
            ),
            const SizedBox(width: 4),
            Text(
              item.priceDisplay,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF784E07),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    if (item.isFree) {
      // Light Green FREE badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF91D4A8),
            width: 0.8,
          ),
        ),
        child: Text(
          'FREE',
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B6A45),
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    // Unlocked Rewarded or Premium Theme -> SELECT affordance
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F5A3E),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200F5A3E),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        'SELECT',
        style: GoogleFonts.outfit(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
