import 'package:flutter/foundation.dart';
import '../core/app_colors.dart';
import 'storage_service.dart';

/// Classification of Carrom Zone board themes.
enum ThemeTier {
  free,
  rewarded,
  premium,
}

/// Centralized Theme Catalog Item representing a board theme's metadata,
/// pricing/reward tier, and unlock entitlement status.
class ThemeCatalogItem {
  final BoardThemeType theme;
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final ThemeTier tier;
  final bool isUnlocked;
  final bool isSelected;
  final String mockProductId;
  final String priceDisplay;
  final String assetPreview;
  final int requiredAds;
  final int watchedAds;

  const ThemeCatalogItem({
    required this.theme,
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.tier,
    required this.isUnlocked,
    required this.isSelected,
    required this.mockProductId,
    required this.priceDisplay,
    required this.assetPreview,
    this.requiredAds = 0,
    this.watchedAds = 0,
  });

  bool get isFree => tier == ThemeTier.free;
  bool get isRewarded => tier == ThemeTier.rewarded;
  bool get isPremium => tier == ThemeTier.premium;

  double get rewardProgress =>
      requiredAds > 0 ? (watchedAds / requiredAds).clamp(0.0, 1.0) : 1.0;
}

/// Centralized, production-architected Theme Catalog and Entitlement Service.
///
/// Features:
/// - Explicit Free vs Rewarded Ad Unlock vs Premium theme separation
/// - Persistent rewarded ad watch progress & permanent unlock flags
/// - Real entitlement persistence separated from developer testing overrides
/// - Safe fallback to free default theme if unentitled
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  /// Lifecycle initialization hook for consistency with other services
  Future<void> init() async {}

  /// Default free theme when no theme is selected or entitlement is lost
  static const BoardThemeType defaultTheme = BoardThemeType.mahogany;

  /// Free themes available to all players by default
  static const Set<BoardThemeType> freeThemes = {
    BoardThemeType.mahogany, // Classic Birch & Rosewood
  };

  /// Themes unlocked permanently by watching rewarded video ads
  static const Map<BoardThemeType, int> rewardedThemeRequirements = {
    BoardThemeType.emerald: 10, // Heritage Club Teal -> 10 Rewarded Ads
    BoardThemeType.midnight: 15, // Royal Navy Lounge -> 15 Rewarded Ads
  };

  /// Premium themes requiring purchase entitlement
  static const Set<BoardThemeType> premiumThemes = {
    BoardThemeType.walnutClub, // Walnut Club
    BoardThemeType.royalIndigo, // Royal Indigo
    BoardThemeType.emeraldLounge, // Emerald Lounge
    BoardThemeType.oceanBreeze, // Ocean Breeze
    BoardThemeType.sakuraStudio, // Sakura Studio
    BoardThemeType.neonArena, // Neon Arena
    BoardThemeType.goldenPalace, // Golden Palace
    BoardThemeType.cosmicElite, // Cosmic Elite
  };

  bool isThemeFree(BoardThemeType theme) => freeThemes.contains(theme);
  bool isThemeRewarded(BoardThemeType theme) =>
      rewardedThemeRequirements.containsKey(theme);
  bool isThemePremium(BoardThemeType theme) => premiumThemes.contains(theme);

  int getRequiredRewardedAds(BoardThemeType theme) =>
      rewardedThemeRequirements[theme] ?? 0;

  int getWatchedRewardedAds(BoardThemeType theme) {
    final int requiredAds = getRequiredRewardedAds(theme);
    if (requiredAds <= 0) return 0;
    return StorageService().getThemeAdProgress(theme).clamp(0, requiredAds);
  }

  /// Returns whether [theme] is unlocked for the player.
  /// Free themes are always unlocked.
  /// Rewarded themes unlock permanently once [requiredAds] are watched (or mock-unlocked in debug).
  /// Premium themes require genuine entitlement or active developer testing override.
  bool isThemeUnlocked(BoardThemeType theme) {
    if (isThemeFree(theme)) return true;

    final storage = StorageService();
    if (isThemeRewarded(theme)) {
      final int requiredAds = getRequiredRewardedAds(theme);
      if (storage.isRewardedThemeUnlocked(theme) ||
          storage.getThemeAdProgress(theme) >= requiredAds) {
        return true;
      }
      if (!kReleaseMode &&
          storage.getDevMockUnlockedThemes().contains(theme.name)) {
        return true;
      }
      return false;
    }

    // 1. Check genuine permanent purchase entitlements
    if (storage.getPurchasedThemes().contains(theme.name)) {
      return true;
    }

    // 2. Check debug/developer testing overrides (strictly ignored in release mode)
    if (!kReleaseMode &&
        storage.getDevMockUnlockedThemes().contains(theme.name)) {
      return true;
    }

    return false;
  }

  /// Records one verified completed Rewarded Ad watch for [theme].
  ///
  /// Must be called strictly from the official `onUserEarnedReward` callback.
  /// Returns `true` if this watch caused [theme] to cross its unlock threshold.
  Future<bool> recordRewardedAdWatch(BoardThemeType theme) async {
    final int requiredAds = getRequiredRewardedAds(theme);
    if (requiredAds <= 0) return false;

    final storage = StorageService();
    final bool wasAlreadyUnlocked = storage.isRewardedThemeUnlocked(theme);
    final int current = storage.getThemeAdProgress(theme);
    final int next = (current + 1).clamp(0, requiredAds);
    await storage.setThemeAdProgress(theme, next);

    if (next >= requiredAds) {
      await storage.setRewardedThemeUnlocked(theme, true);
      return !wasAlreadyUnlocked;
    }
    return false;
  }

  /// Equips [theme] if entitled; returns true if successful.
  /// Locked themes can never be equipped.
  Future<bool> selectTheme(BoardThemeType theme) async {
    if (!isThemeUnlocked(theme)) {
      return false;
    }
    await StorageService().setBoardThemeRaw(theme);
    return true;
  }

  /// Returns the current active board theme, with fallback to [defaultTheme] if unentitled.
  BoardThemeType getActiveTheme() {
    final theme = StorageService().getBoardThemeRaw();
    if (!isThemeUnlocked(theme)) {
      return defaultTheme;
    }
    return theme;
  }

  /// Builds the complete centralized catalog for UI presentation.
  List<ThemeCatalogItem> getCatalogItems() {
    final activeTheme = getActiveTheme();

    return BoardThemeType.values.map((theme) {
      final bool isFree = isThemeFree(theme);
      final bool isRewarded = isThemeRewarded(theme);
      final bool unlocked = isThemeUnlocked(theme);
      final bool selected = theme == activeTheme;
      final int requiredAds = getRequiredRewardedAds(theme);
      final int watchedAds = getWatchedRewardedAds(theme);

      final ThemeTier tier = isFree
          ? ThemeTier.free
          : (isRewarded ? ThemeTier.rewarded : ThemeTier.premium);

      final String priceDisplay = isFree
          ? 'Free'
          : (isRewarded ? '$watchedAds/$requiredAds Ads' : '\$1.99');

      return ThemeCatalogItem(
        theme: theme,
        id: theme.name,
        name: AppColors.getThemeName(theme),
        subtitle: AppColors.getThemeSubtitle(theme),
        description: AppColors.getThemeDescription(theme),
        tier: tier,
        isUnlocked: unlocked,
        isSelected: selected,
        mockProductId: 'carrom.theme.${theme.name}',
        priceDisplay: priceDisplay,
        assetPreview: AppColors.getThemeAsset(theme),
        requiredAds: requiredAds,
        watchedAds: unlocked && isRewarded ? requiredAds : watchedAds,
      );
    }).toList();
  }

  // ─── Developer Testing Overrides (Debug Only) ─────────────────────────────

  /// Unlocks an individual non-free theme for testing.
  Future<void> devUnlockTheme(BoardThemeType theme) async {
    if (kReleaseMode || isThemeFree(theme)) return;
    final storage = StorageService();
    final list = storage.getDevMockUnlockedThemes();
    if (!list.contains(theme.name)) {
      list.add(theme.name);
      await storage.setDevMockUnlockedThemes(list);
    }
  }

  /// Locks an individual non-free theme for testing.
  Future<void> devLockTheme(BoardThemeType theme) async {
    if (kReleaseMode || isThemeFree(theme)) return;
    final storage = StorageService();
    final list = storage.getDevMockUnlockedThemes();
    list.remove(theme.name);
    await storage.setDevMockUnlockedThemes(list);

    if (getActiveTheme() == theme && !isThemeUnlocked(theme)) {
      await storage.setBoardThemeRaw(defaultTheme);
    }
  }

  /// Unlocks all non-free themes for testing.
  Future<void> devUnlockAllThemes() async {
    if (kReleaseMode) return;
    final storage = StorageService();
    final allNames = BoardThemeType.values
        .where((e) => !isThemeFree(e))
        .map((e) => e.name)
        .toList();
    await storage.setDevMockUnlockedThemes(allNames);
  }

  /// Resets all mock developer unlocks without affecting real entitlements.
  Future<void> devResetMockUnlocks() async {
    if (kReleaseMode) return;
    final storage = StorageService();
    await storage.setDevMockUnlockedThemes([]);
    if (!isThemeUnlocked(getActiveTheme())) {
      await storage.setBoardThemeRaw(defaultTheme);
    }
  }
}
