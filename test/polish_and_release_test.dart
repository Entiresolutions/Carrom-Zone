import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/core/design_system.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/game_mode.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/painters/aim_painter.dart';
import 'package:carrom_master/painters/board_painter.dart';
import 'package:carrom_master/painters/particle_painter.dart';
import 'package:carrom_master/painters/piece_painter.dart';
import 'package:carrom_master/services/audio_service.dart';
import 'package:carrom_master/services/storage_service.dart';
import 'package:carrom_master/screens/menu_screen.dart';
import 'package:carrom_master/screens/settings_screen.dart';
import 'package:carrom_master/screens/theme_collection_screen.dart';
import 'package:carrom_master/screens/tutorial_dialog.dart';

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

  tearDown(() {
    AudioService().stopAll();
  });

  group('Phase 3 & 4: Polish & Production Readiness Suite', () {
    test('1. Storage & Persistence: Independent settings, themes, difficulties and tutorial status', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      // Test Audio toggles
      expect(storage.getSfxEnabled(), isTrue);
      expect(storage.getMusicEnabled(), isTrue);
      expect(storage.getHapticsEnabled(), isTrue);

      await storage.setSfxEnabled(false);
      await storage.setMusicEnabled(false);
      await storage.setHapticsEnabled(false);

      expect(storage.getSfxEnabled(), isFalse);
      expect(storage.getMusicEnabled(), isFalse);
      expect(storage.getHapticsEnabled(), isFalse);

      // Test AI Difficulty
      expect(storage.getAiDifficulty(), equals(AiDifficulty.medium));
      await storage.setAiDifficulty(AiDifficulty.hard);
      expect(storage.getAiDifficulty(), equals(AiDifficulty.hard));

      // Test Board Theme
      expect(storage.getBoardTheme(), equals(BoardThemeType.mahogany));
      await storage.setBoardTheme(BoardThemeType.midnight);
      expect(storage.getBoardTheme(), equals(BoardThemeType.midnight));

      // Test Tutorial Status
      expect(storage.getTutorialSeen(), isFalse);
      await storage.setTutorialSeen(true);
      expect(storage.getTutorialSeen(), isTrue);

      // Test Theme persistence (Purchases & Dev Mock Unlocks)
      await storage.setPurchasedThemes(['goldenPalace']);
      expect(storage.getPurchasedThemes(), contains('goldenPalace'));

      await storage.setDevMockUnlockedThemes(['cosmicElite', 'neonArena']);
      expect(storage.getDevMockUnlockedThemes(), containsAll(['cosmicElite', 'neonArena']));
    });

    test('2. AudioService: Independent toggles and contextual haptic triggers', () {
      final audio = AudioService();
      audio.sfxEnabled = true;
      audio.musicEnabled = true;
      audio.hapticsEnabled = true;

      // SFX calls should execute without error
      expect(() => audio.playHit(), returnsNormally);
      expect(() => audio.playWall(), returnsNormally);
      expect(() => audio.playPocket(), returnsNormally);
      expect(() => audio.playShoot(), returnsNormally);
      expect(() => audio.playWin(), returnsNormally);

      // Haptics calls should execute without error
      expect(() => audio.hapticLight(), returnsNormally);
      expect(() => audio.hapticMedium(), returnsNormally);
      expect(() => audio.hapticHeavy(), returnsNormally);
      expect(() => audio.hapticSelection(), returnsNormally);
      expect(() => audio.hapticCelebration(), returnsNormally);
    });

    test('3. Theme Metadata Integrity: Names, descriptions and accent palettes for all 3 themes', () {
      for (final theme in BoardThemeType.values) {
        final name = AppColors.getThemeName(theme);
        final desc = AppColors.getThemeDescription(theme);
        final accent = AppColors.getThemeAccent(theme);
        final preview = AppColors.getThemePreviewSurface(theme);

        expect(name.isNotEmpty, isTrue);
        expect(desc.isNotEmpty, isTrue);
        expect(accent, isNotNull);
        expect(preview, isNotNull);
      }
    });

    test('4. CustomPainters: Board, Piece, Aim, and Particle painters render cleanly without exceptions', () {
      final pieces = [
        PieceModel(
          id: 1,
          type: PieceType.queen,
          position: Vector2.zero,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        ),
        PieceModel(
          id: 2,
          type: PieceType.white,
          position: const Vector2(30.0, 30.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
        PieceModel(
          id: 3,
          type: PieceType.black,
          position: const Vector2(-30.0, -30.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);

      // 1. BoardPainter for all 3 themes
      for (final theme in BoardThemeType.values) {
        final boardPainter = BoardPainter(theme: theme);
        expect(() => boardPainter.paint(canvas, size), returnsNormally);
      }

      // 2. PiecePainter
      final piecePainter = PiecePainter(pieces: pieces, striker: striker, strikerGlowPhase: 0.5);
      expect(() => piecePainter.paint(canvas, size), returnsNormally);

      // 3. AimPainter
      final aimPainter = AimPainter(
        strikerPos: striker.position,
        dragVector: const Vector2(0.0, 50.0),
        power: 0.75,
      );
      expect(() => aimPainter.paint(canvas, size), returnsNormally);

      // 4. ParticlePainter with shockwave rings and floating scores
      final particlePainter = ParticlePainter(
        particles: [
          PocketParticle(
            origin: const Vector2(-178, -178),
            angle: 0.5,
            speed: 1.0,
            color: AppColors.queenPiece,
          ),
        ],
        rings: [
          PocketRingEffect(
            origin: const Vector2(-178, -178),
            color: AppColors.goldBright,
          ),
        ],
        floatingScores: [
          FloatingScoreEffect(
            origin: const Vector2(-178, -178),
            text: '+3 QUEEN',
            color: AppColors.queenPiece,
          ),
        ],
      );
      expect(() => particlePainter.paint(canvas, size), returnsNormally);
    });

    testWidgets('5. Tutorial Dialog Smoke Test: Mounts, navigates steps, and dismisses cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TutorialDialog.show(context),
                child: const Text('Show Tutorial'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Tutorial'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('Aim & Flick'), findsOneWidget);

      // Tap NEXT to advance
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('Striker Positioning'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('HOW TO PLAY'), findsNothing);
    });

    testWidgets('6. Redesigned Carrom Club Screens: Menu, Settings & Leaderboard responsive verification', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();

      // Test on compact 360x680 viewport with reduced-motion enabled
      await tester.binding.setSurfaceSize(const Size(360, 680));

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(360, 680),
            disableAnimations: true,
          ),
          child: MaterialApp(
            home: MenuScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CARROM ZONE'), findsOneWidget);
      expect(find.text('VS CPU'), findsOneWidget);
      expect(find.text('PASS & PLAY'), findsOneWidget);
      expect(find.text('PRACTICE ARENA'), findsOneWidget);
      expect(find.byType(ClubCrestLogo), findsOneWidget);

      // Verify all 4 ClubBackgroundPresets & responsive aspect ratios (compact 360x680 & tall 412x915)
      expect(ClubBackgroundAssets.all.length, equals(4));
      for (final preset in ClubBackgroundPreset.values) {
        expect(ClubBackgroundAssets.assetFor(preset).endsWith('.webp'), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClubBackground(
                preset: preset,
                child: const Center(child: Text('Carrom Zone Preset Test')),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Carrom Zone Preset Test'), findsOneWidget);
      }

      // Test tall 20:9 mobile aspect ratio (412x915) on MenuScreen
      await tester.binding.setSurfaceSize(const Size(412, 915));
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(412, 915),
            disableAnimations: true,
          ),
          child: MaterialApp(
            home: MenuScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('CARROM ZONE'), findsOneWidget);

      // Test Settings Screen
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('BOARD THEMES'), findsOneWidget);
      expect(find.text('AI DIFFICULTY'), findsOneWidget);
      expect(find.text('AUDIO & HAPTICS'), findsOneWidget);

      // Test Theme Collection Screen
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemeCollectionScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('THEME COLLECTION'), findsOneWidget);
      expect(find.text('STARTER THEMES (FREE)'), findsOneWidget);
      expect(find.text('CHAMPIONSHIP THEMES (PREMIUM)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    });
  });
}
