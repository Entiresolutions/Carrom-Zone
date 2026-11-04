import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/services/storage_service.dart';
import 'package:carrom_master/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
    await ThemeService().init();
  });

  group('ThemeService Premium Catalog & Entitlement Tests', () {
    test('Starter themes are free and unlocked by default', () {
      final service = ThemeService();

      expect(service.isThemeUnlocked(BoardThemeType.mahogany), isTrue);
      expect(service.isThemeUnlocked(BoardThemeType.emerald), isTrue);
      expect(service.isThemeUnlocked(BoardThemeType.midnight), isTrue);
    });

    test('All 8 championship themes are premium and locked by default', () {
      final service = ThemeService();

      final premiumThemes = [
        BoardThemeType.walnutClub,
        BoardThemeType.royalIndigo,
        BoardThemeType.emeraldLounge,
        BoardThemeType.oceanBreeze,
        BoardThemeType.sakuraStudio,
        BoardThemeType.neonArena,
        BoardThemeType.goldenPalace,
        BoardThemeType.cosmicElite,
      ];

      for (final theme in premiumThemes) {
        expect(
          service.isThemeUnlocked(theme),
          isFalse,
          reason: '${theme.name} should be locked by default',
        );
      }
    });

    test('Catalog items provide valid product IDs and display prices', () {
      final service = ThemeService();
      final items = service.getCatalogItems();

      expect(items.length, equals(11));

      for (final item in items) {
        expect(item.mockProductId, equals('carrom.theme.${item.theme.name}'));
        if (item.isFree) {
          expect(item.priceDisplay, equals('Free'));
        } else {
          expect(item.priceDisplay, equals('\$1.99'));
        }
      }
    });

    test('Selecting unentitled theme fails and falls back to safe mahogany', () async {
      final service = ThemeService();

      final selected = await service.selectTheme(BoardThemeType.goldenPalace);
      expect(selected, isFalse);

      // Active theme remains mahogany or safe fallback
      expect(service.getActiveTheme(), equals(BoardThemeType.mahogany));
    });

    test('Dev unlock enables theme and allows equipping', () async {
      final service = ThemeService();

      expect(service.isThemeUnlocked(BoardThemeType.goldenPalace), isFalse);

      await service.devUnlockTheme(BoardThemeType.goldenPalace);
      expect(service.isThemeUnlocked(BoardThemeType.goldenPalace), isTrue);

      final selected = await service.selectTheme(BoardThemeType.goldenPalace);
      expect(selected, isTrue);
      expect(service.getActiveTheme(), equals(BoardThemeType.goldenPalace));
    });

    test('Dev unlock all and reset restores locked state and safe default theme', () async {
      final service = ThemeService();

      await service.devUnlockAllThemes();
      for (final theme in BoardThemeType.values) {
        expect(service.isThemeUnlocked(theme), isTrue);
      }

      await service.selectTheme(BoardThemeType.cosmicElite);
      expect(service.getActiveTheme(), equals(BoardThemeType.cosmicElite));

      // Reset developer mock unlocks
      await service.devResetMockUnlocks();

      // Cosmic Elite should now be locked
      expect(service.isThemeUnlocked(BoardThemeType.cosmicElite), isFalse);

      // Active theme safely reset to free mahogany
      expect(service.getActiveTheme(), equals(BoardThemeType.mahogany));

      // Free starter themes remain unlocked
      expect(service.isThemeUnlocked(BoardThemeType.mahogany), isTrue);
      expect(service.isThemeUnlocked(BoardThemeType.emerald), isTrue);
      expect(service.isThemeUnlocked(BoardThemeType.midnight), isTrue);
    });
  });
}
