import 'package:flutter/foundation.dart';
import '../core/app_colors.dart';
import 'storage_service.dart';

/// Classification of Carrom Zone board themes.
enum ThemeTier {
  free,
  premium,
}

/// Centralized Theme Catalog Item representing a board theme's metadata,
/// pricing tier, and unlock entitlement status.
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
  });

  bool get isFree => tier == ThemeTier.free;
  bool get isPremium => tier == ThemeTier.premium;
}

/// Centralized, production-architected Theme Catalog and Entitlement Service.
///
/// Features:
/// - Explicit Free vs Premium theme separation
/// - Real entitlement persistence separated from developer testing overrides
/// - Mock billing metadata (ready for Google Play Billing)
/// - Safe fallback to free theme if unentitled
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  /// Lifecycle initialization hook for consistency with other services
  Future<void> init() async {}

  /// Default free theme when no theme is selected or entitlement is lost
  static const BoardThemeType defaultTheme = BoardThemeType.mahogany;

  /// Free themes available to all players
  static const Set<BoardThemeType> freeThemes = {
    BoardThemeType.mahogany, // Classic Birch & Rosewood
    BoardThemeType.emerald, // Heritage Club Teal
    BoardThemeType.midnight, // Royal Navy Lounge
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
  bool isThemePremium(BoardThemeType theme) => premiumThemes.contains(theme);

  /// Returns whether [theme] is unlocked for the player.
  /// Free themes are always unlocked.
  /// Premium themes require genuine entitlement or active developer testing override.
  bool isThemeUnlocked(BoardThemeType theme) {
    if (isThemeFree(theme)) return true;

    final storage = StorageService();
    // 1. Check genuine permanent purchase entitlements
    if (storage.getPurchasedThemes().contains(theme.name)) {
      return true;
    }

    // 2. Check debug/developer testing overrides (strictly ignored in release mode)
    if (!kReleaseMode && storage.getDevMockUnlockedThemes().contains(theme.name)) {
      return true;
    }

    return false;
  }

  /// Equips [theme] if entitled; returns true if successful.
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
      final bool unlocked = isThemeUnlocked(theme);
      final bool selected = theme == activeTheme;

      return ThemeCatalogItem(
        theme: theme,
        id: theme.name,
        name: AppColors.getThemeName(theme),
        subtitle: AppColors.getThemeSubtitle(theme),
        description: AppColors.getThemeDescription(theme),
        tier: isFree ? ThemeTier.free : ThemeTier.premium,
        isUnlocked: unlocked,
        isSelected: selected,
        mockProductId: 'carrom.theme.${theme.name}',
        priceDisplay: isFree ? 'Free' : '\$1.99',
        assetPreview: AppColors.getThemeAsset(theme),
      );
    }).toList();
  }

  // ─── Developer Testing Overrides (Debug Only) ─────────────────────────────

  /// Unlocks an individual premium theme for testing.
  Future<void> devUnlockTheme(BoardThemeType theme) async {
    if (kReleaseMode) return;
    final storage = StorageService();
    final list = storage.getDevMockUnlockedThemes();
    if (!list.contains(theme.name)) {
      list.add(theme.name);
      await storage.setDevMockUnlockedThemes(list);
    }
  }

  /// Locks an individual premium theme for testing.
  Future<void> devLockTheme(BoardThemeType theme) async {
    if (kReleaseMode) return;
    final storage = StorageService();
    final list = storage.getDevMockUnlockedThemes();
    list.remove(theme.name);
    await storage.setDevMockUnlockedThemes(list);

    if (getActiveTheme() == theme && !isThemeUnlocked(theme)) {
      await storage.setBoardThemeRaw(defaultTheme);
    }
  }

  /// Unlocks all premium themes for testing.
  Future<void> devUnlockAllThemes() async {
    if (kReleaseMode) return;
    final storage = StorageService();
    final allNames = premiumThemes.map((e) => e.name).toList();
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
