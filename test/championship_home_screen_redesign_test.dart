import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/core/championship_widgets.dart';
import 'package:carrom_master/core/design_system.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/screens/settings_screen.dart';
import 'package:carrom_master/screens/theme_collection_screen.dart';
import 'package:carrom_master/services/audio_service.dart';
import 'package:carrom_master/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  tearDown(() {
    AudioService().stopAll();
  });

  Widget buildTestableScreen(Widget screen, {
    Size size = const Size(390, 844),
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    );
  }

  group('Championship Club UI/UX Redesign Test Suite', () {
    testWidgets('1. Header & Brand Elements: Crest, titles, and utility icon buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();

      // Brand Title & Tagline
      expect(find.text('CARROM ZONE'), findsOneWidget);
      expect(find.text('CHAMPIONSHIP CLUB EDITION'), findsOneWidget);
      expect(find.byType(ClubCrestLogo), findsOneWidget);

      // Top-right Header icon buttons (Rules & Settings)
      expect(find.byType(ChampionshipIconButton), findsNWidgets(2));
      expect(find.byTooltip('Rules & Tutorial'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('2. Badge Pill & Hero Section Typography', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();

      // Points-based badge pill
      expect(find.text('POINTS-BASED CLUB PLAY'), findsOneWidget);
      expect(find.byType(ChampionshipGoldPill), findsOneWidget);

      // Hero Tagline
      expect(
        find.text('Realistic tabletop physics, tactile strikes & championship play'),
        findsOneWidget,
      );
    });

    testWidgets('3. Table Theme Card: Metadata, thumbnail, and EXPLORE button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChampionshipThemeCard), findsOneWidget);
      expect(find.text('TABLE THEME'), findsOneWidget);
      expect(find.text('EXPLORE'), findsOneWidget);
      expect(find.byType(ThemeBoardPreview), findsOneWidget);
    });

    testWidgets('4. Game Mode Segmented Toggle: Classic Carrom vs Freestyle Points', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChampionshipSegmentedToggle), findsOneWidget);
      expect(find.text('CLASSIC CARROM'), findsOneWidget);
      expect(find.text('White vs Black · +3 Queen'), findsOneWidget);
      expect(find.text('FREESTYLE POINTS'), findsOneWidget);
      expect(find.text('W:10 · B:20 · Q:50 · 160 Pts'), findsOneWidget);

      // Toggle to Freestyle Points
      await tester.tap(find.text('FREESTYLE POINTS'));
      await tester.pumpAndSettle();

      // Mode cards should reflect freestyle category tags & subtitles
      expect(find.text('FREESTYLE POINTS • 160 TARGET'), findsOneWidget);
      expect(find.text('Race CPU to 160 pts • Any coin counts'), findsOneWidget);
      expect(find.text('LOCAL 2P • FREESTYLE 10/20/50'), findsOneWidget);
      expect(find.text('2-Player Freestyle race to 160 pts'), findsOneWidget);

      // Toggle back to Classic Carrom
      await tester.tap(find.text('CLASSIC CARROM'));
      await tester.pumpAndSettle();

      expect(find.text('SOLO PLAY • TACTICAL AI'), findsOneWidget);
      expect(find.text('Test your tactical skills against AI'), findsOneWidget);
      expect(find.text('LOCAL MULTIPLAYER • 2 PLAYERS'), findsOneWidget);
      expect(find.text('Turn-based tabletop match on 1 device'), findsOneWidget);
    });

    testWidgets('5. Three Mode Action Cards: VS CPU, PASS & PLAY, PRACTICE ARENA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChampionshipModeCard), findsNWidgets(3));

      // Card 1: VS CPU
      expect(find.text('VS CPU'), findsOneWidget);
      expect(find.text('SOLO PLAY • TACTICAL AI'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget); // Default AI difficulty

      // Card 2: PASS & PLAY
      expect(find.text('PASS & PLAY'), findsOneWidget);
      expect(find.text('LOCAL MULTIPLAYER • 2 PLAYERS'), findsOneWidget);
      expect(find.byType(TwoPeopleIcon), findsOneWidget);

      // Card 3: PRACTICE ARENA
      expect(find.text('PRACTICE ARENA'), findsOneWidget);
      expect(find.text('SOLO MASTERY • UNTIMED'), findsOneWidget);
    });

    testWidgets('6. Floating Bottom Navigation Dock: Dynamic Active Tab on Home vs Settings vs Themes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      // 6A. On Home Screen -> activeTab is null (none selected)
      await tester.pumpWidget(buildTestableScreen(const MenuScreen()));
      await tester.pumpAndSettle();
      final navOnHome = tester.widget<ChampionshipBottomNav>(find.byType(ChampionshipBottomNav));
      expect(navOnHome.activeTab, isNull);

      // 6B. On Settings Screen -> activeTab is ChampionshipTab.settings
      await tester.pumpWidget(buildTestableScreen(const SettingsScreen()));
      await tester.pumpAndSettle();
      final navOnSettings = tester.widget<ChampionshipBottomNav>(find.byType(ChampionshipBottomNav));
      expect(navOnSettings.activeTab, equals(ChampionshipTab.settings));

      // 6C. On Themes Screen -> activeTab is ChampionshipTab.themes
      await tester.pumpWidget(buildTestableScreen(const ThemeCollectionScreen()));
      await tester.pumpAndSettle();
      final navOnThemes = tester.widget<ChampionshipBottomNav>(find.byType(ChampionshipBottomNav));
      expect(navOnThemes.activeTab, equals(ChampionshipTab.themes));
    });

    testWidgets('7. Settings Screen: 4 Sections, Toggles & Difficulty Selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Sections
      expect(find.text('AUDIO & HAPTICS'), findsOneWidget);
      expect(find.text('AI DIFFICULTY'), findsOneWidget);
      expect(find.text('BOARD THEMES'), findsOneWidget);
      expect(find.text('DISPLAY'), findsOneWidget);
      expect(find.text('ABOUT & HANDBOOK'), findsOneWidget);

      // Toggles
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Background Music'), findsOneWidget);
      expect(find.text('Haptic Vibration'), findsOneWidget);
      expect(find.text('Aim Trajectory Line'), findsOneWidget);
      expect(find.text('Show Coin Shadows'), findsOneWidget);
      expect(find.text('Reduce Animations'), findsOneWidget);

      // Toggle Sound Effects
      expect(StorageService().getSfxEnabled(), isTrue);
      await tester.tap(find.text('Sound Effects'));
      await tester.pumpAndSettle();
      expect(StorageService().getSfxEnabled(), isFalse);

      // Toggle Difficulty
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();
      expect(StorageService().getAiDifficulty(), equals(AiDifficulty.hard));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('8. Theme Collection Screen: Current Theme Showcase & 2-Column Grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableScreen(const ThemeCollectionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('THEME COLLECTION'), findsOneWidget);
      expect(find.text('CURRENTLY EQUIPPED'), findsOneWidget);
      expect(find.text('STARTER THEMES (FREE)'), findsOneWidget);
      expect(find.text('CHAMPIONSHIP THEMES (PREMIUM)'), findsOneWidget);

      // 11 Themes should be rendered in grid
      expect(find.byType(ChampionshipThemeGridCard), findsNWidgets(11));

      // Selecting Emerald Starter Theme
      await tester.tap(find.text('Emerald'));
      await tester.pumpAndSettle();
      expect(StorageService().getBoardTheme(), equals(BoardThemeType.emerald));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('9. Responsive Viewport Test: Compact 360x600 screen has zero overflow across all screens', (tester) async {
      // Small screen size (360x600)
      await tester.binding.setSurfaceSize(const Size(360, 600));

      // MenuScreen
      await tester.pumpWidget(buildTestableScreen(const MenuScreen(), size: const Size(360, 600)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // SettingsScreen
      await tester.pumpWidget(buildTestableScreen(const SettingsScreen(), size: const Size(360, 600)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // ThemeCollectionScreen
      await tester.pumpWidget(buildTestableScreen(const ThemeCollectionScreen(), size: const Size(360, 600)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
