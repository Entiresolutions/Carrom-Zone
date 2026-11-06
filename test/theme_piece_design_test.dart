import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/core/design_system.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/theme_piece_style.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/painters/piece_painter.dart';
import 'package:carrom_master/painters/particle_painter.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/services/piece_asset_service.dart';
import 'package:carrom_master/services/striker_asset_service.dart';

void main() {
  group('Theme-Based Piece Design System Test Suite', () {
    test('1. Single Source of Truth: All 11 themes have complete styling config', () {
      expect(BoardThemeType.values.length, equals(11));

      for (final theme in BoardThemeType.values) {
        final style = ThemePieceStyle.of(theme);
        final styleFromAppColors = AppColors.getPieceStyle(theme);

        expect(style.theme, equals(theme));
        expect(styleFromAppColors.theme, equals(theme));

        // White pieces
        expect(style.whiteGradient.length, greaterThanOrEqualTo(3));
        expect(style.whiteRim, isNotNull);
        expect(style.whiteGroove, isNotNull);
        expect(style.whiteCenter, isNotNull);

        // Black pieces
        expect(style.blackGradient.length, greaterThanOrEqualTo(3));
        expect(style.blackRim, isNotNull);
        expect(style.blackGroove, isNotNull);
        expect(style.blackCenter, isNotNull);

        // Queen
        expect(style.queenGradient.length, greaterThanOrEqualTo(3));
        expect(style.queenOuterRing, isNotNull);
        expect(style.queenStarColor, isNotNull);
        expect(style.queenCenterPip, isNotNull);
        expect(style.queenStarPoints, equals(8));

        // Striker
        expect(style.strikerGradient.length, greaterThanOrEqualTo(3));
        expect(style.strikerOuterRim, isNotNull);
        expect(style.strikerBezelRing, isNotNull);
        expect(style.strikerAccentRing, isNotNull);
        expect(style.strikerEmblemColor, isNotNull);
        expect(style.strikerGemCore, isNotNull);
        expect(style.strikerGlow, isNotNull);
      }
    });

    test('2. Visual Contrast & Readability: White vs Black vs Queen contrast', () {
      for (final theme in BoardThemeType.values) {
        final style = ThemePieceStyle.of(theme);

        // White pieces primary color must be substantially lighter than black pieces
        final whiteLum = style.whiteGradient[1].computeLuminance();
        final blackLum = style.blackGradient[1].computeLuminance();
        expect(
          whiteLum,
          greaterThan(blackLum + 0.35),
          reason: 'Theme ${theme.name} must preserve high contrast between white and black pieces',
        );

        // Queen must have strong red/magenta saturation to remain instantly recognizable
        final queenColor = style.queenGradient[1];
        expect(
          queenColor.red,
          greaterThan(queenColor.blue),
          reason: 'Queen in theme ${theme.name} must have strong crimson/red identity',
        );
        expect(
          queenColor.red,
          greaterThan(queenColor.green),
          reason: 'Queen in theme ${theme.name} must have strong crimson/red identity',
        );

        // Striker must have distinctive metallic bezel
        expect(style.strikerBezelRing.opacity, greaterThan(0.5));
      }
    });

    test('3. Canvas Paint Execution: PiecePainter renders all 11 themes without errors', () {
      final List<PieceModel> pieces = [
        PieceModel(
          id: 0,
          type: PieceType.queen,
          position: Vector2.zero,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        ),
        PieceModel(
          id: 1,
          type: PieceType.white,
          position: const Vector2(20.0, 20.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
        PieceModel(
          id: 2,
          type: PieceType.black,
          position: const Vector2(-20.0, -20.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      ];

      final PieceModel striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      const Size size = Size(500, 500);

      for (final theme in BoardThemeType.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final painter = PiecePainter(
          theme: theme,
          pieces: pieces,
          striker: striker,
          strikerGlowPhase: 0.35,
        );

        expect(() => painter.paint(canvas, size), returnsNormally);
        recorder.endRecording();
      }
    });

    test('4. Physical Invariance: Rendering NEVER alters physics, positions or radiuses', () {
      final queen = PieceModel(
        id: 0,
        type: PieceType.queen,
        position: const Vector2(12.5, -8.3),
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
        velocity: const Vector2(10.0, -5.0),
      );

      final striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(45.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      for (final theme in BoardThemeType.values) {
        final painter = PiecePainter(
          theme: theme,
          pieces: [queen],
          striker: striker,
          strikerGlowPhase: 0.75,
        );
        painter.paint(canvas, const Size(400, 400));

        // Physics invariant checks
        expect(queen.position.x, equals(12.5));
        expect(queen.position.y, equals(-8.3));
        expect(queen.radius, equals(GameConfig.queenRadius));
        expect(queen.velocity.x, equals(10.0));
        expect(striker.position.x, equals(45.0));
        expect(striker.radius, equals(GameConfig.strikerRadius));
      }
      recorder.endRecording();
    });

    testWidgets('5. ClubCoinBadge Theme Adaptation: Renders cleanly for all themes', (tester) async {
      for (final theme in BoardThemeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ClubCoinBadge(theme: theme, isWhite: true, size: 28),
                  ClubCoinBadge(theme: theme, isWhite: false, size: 28),
                  ClubCoinBadge(theme: theme, isQueen: true, size: 28),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ClubCoinBadge), findsNWidgets(3));
      }
    });

    test('6. Striker Theme Identity & VFX Colors: Complete for all 11 themes', () {
      final expectedMaterials = {
        BoardThemeType.mahogany: 'Pearl Ivory and Rosewood',
        BoardThemeType.emerald: 'Silver and Teal',
        BoardThemeType.midnight: 'Midnight Blue and Gold',
        BoardThemeType.walnutClub: 'Walnut Wood and Brass',
        BoardThemeType.royalIndigo: 'Sapphire and Platinum',
        BoardThemeType.emeraldLounge: 'Emerald and Antique Gold',
        BoardThemeType.oceanBreeze: 'Aquamarine and Silver',
        BoardThemeType.sakuraStudio: 'Porcelain Pink and Rose Gold',
        BoardThemeType.neonArena: 'Carbon Black and Cyan Neon',
        BoardThemeType.goldenPalace: 'Ivory Marble and Polished Gold',
        BoardThemeType.cosmicElite: 'Obsidian and Cosmic Violet',
      };

      for (final theme in BoardThemeType.values) {
        final style = ThemePieceStyle.of(theme);

        // Material verification
        expect(style.strikerMaterialName, equals(expectedMaterials[theme]));

        // VFX color presence
        expect(style.launchEffectColor, isNotNull);
        expect(style.impactFlashColor, isNotNull);
        expect(style.trailColor, isNotNull);
        expect(style.powerRingColor, isNotNull);
        expect(style.strikerGlow, isNotNull);
        expect(style.strikerEmblemType, isNotNull);

        // Alpha / Opacity checks
        expect(style.launchEffectColor.alpha, greaterThan(0));
        expect(style.impactFlashColor.alpha, greaterThan(0));
        expect(style.trailColor.alpha, greaterThan(0));
        expect(style.powerRingColor.alpha, greaterThan(0));
      }
    });

    test('7. Striker Aiming & Motion Trail Rendering: Renders smoothly without exceptions', () {
      final striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(0.0, GameConfig.baselineYWhite),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final trail = [
        const Vector2(0.0, 150.0),
        const Vector2(5.0, 140.0),
        const Vector2(12.0, 125.0),
        const Vector2(20.0, 100.0),
      ];

      for (final theme in BoardThemeType.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final painter = PiecePainter(
          theme: theme,
          pieces: const [],
          striker: striker,
          strikerGlowPhase: 0.65,
          isAiming: true,
          aimPower: 0.85,
          aimAngle: 1.15,
          strikerTrail: trail,
        );

        expect(
          () => painter.paint(canvas, const Size(500, 500)),
          returnsNormally,
          reason: 'PiecePainter must render aiming power ring and trail smoothly for theme ${theme.name}',
        );

        recorder.endRecording();
      }
    });

    test('8. ParticlePainter Striker Sparks & Shapes: Renders all spark shapes cleanly', () {
      final sparks = [
        StrikerSparkParticle(
          origin: const Vector2(0, 0),
          angle: 0.0,
          speed: 1.0,
          color: const Color(0xFFD4AF37),
          shape: SparkShape.circle,
          life: 0.8,
        ),
        StrikerSparkParticle(
          origin: const Vector2(10, 10),
          angle: 1.0,
          speed: 1.2,
          color: const Color(0xFF00E5FF),
          shape: SparkShape.star,
          life: 0.7,
        ),
        StrikerSparkParticle(
          origin: const Vector2(-10, -10),
          angle: 2.0,
          speed: 0.9,
          color: const Color(0xFFFFB7C5),
          shape: SparkShape.petal,
          life: 0.6,
        ),
        StrikerSparkParticle(
          origin: const Vector2(5, -5),
          angle: 3.0,
          speed: 1.5,
          color: const Color(0xFFA855F7),
          shape: SparkShape.diamond,
          life: 0.9,
        ),
      ];

      final rings = [
        PocketRingEffect(
          origin: const Vector2(0, 0),
          color: const Color(0xFFD4AF37),
          progress: 0.5,
          maxRadius: 40.0,
          strokeWidth: 2.5,
        ),
      ];

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final painter = ParticlePainter(
        particles: const [],
        rings: rings,
        strikerSparks: sparks,
      );

      expect(
        () => painter.paint(canvas, const Size(500, 500)),
        returnsNormally,
        reason: 'ParticlePainter must render all SparkShape variants without exceptions',
      );

      recorder.endRecording();
    });

    test('9. Striker Collision Callback: Fires onStrikerCollision during physics simulation', () {
      final piece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(0.0, 100.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(0.0, 100.0 + GameConfig.strikerRadius + GameConfig.pieceRadius - 1.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
        velocity: const Vector2(0.0, -50.0),
      );

      bool callbackFired = false;
      double recordedImpulse = 0.0;
      bool recordedIsWall = false;

      final physics = CarromPhysics(
        pieces: [piece],
        striker: striker,
        onStrikerCollision: (contact, impulse, isWall) {
          callbackFired = true;
          recordedImpulse = impulse;
          recordedIsWall = isWall;
        },
      );

      physics.update(1.0 / 60.0);

      expect(callbackFired, isTrue);
      expect(recordedImpulse, greaterThan(0.0));
      expect(recordedIsWall, isFalse);
    });

    test('10. Queen Exclusivity & No Red Dominance for Regular Pieces', () {
      for (final theme in BoardThemeType.values) {
        final style = ThemePieceStyle.of(theme);

        // Black pieces must NEVER have red/wine dominance in their body
        for (final c in style.blackGradient) {
          expect(
            c.red,
            lessThan(60),
            reason: 'Black piece body in theme ${theme.name} must be charcoal/graphite, not red or pink',
          );
        }

        // White pieces must be primarily ivory/white
        expect(
          style.whiteGradient[0].computeLuminance(),
          greaterThan(0.90),
          reason: 'White piece in theme ${theme.name} must start with high-luminance ivory/white',
        );

        // Queen MUST have unmistakable crimson/ruby dominance
        final queenCore = style.queenGradient[1];
        expect(
          queenCore.red,
          greaterThan(190),
          reason: 'Queen in theme ${theme.name} must be rich ruby red',
        );
        expect(
          queenCore.red,
          greaterThan(queenCore.green * 1.8),
          reason: 'Queen in theme ${theme.name} must be decisively red',
        );
        expect(
          queenCore.red,
          greaterThan(queenCore.blue * 1.8),
          reason: 'Queen in theme ${theme.name} must be decisively red',
        );
      }
    });

    test('11. Board Surface Separation: High-contrast rims for Black and White pieces', () {
      for (final theme in BoardThemeType.values) {
        final style = ThemePieceStyle.of(theme);

        // Black piece rim must have high visibility (brass, silver, gold, cyan, rose-gold)
        expect(
          style.blackRim.computeLuminance(),
          greaterThan(0.18),
          reason: 'Black piece rim in theme ${theme.name} must provide high contrast on dark boards',
        );
        expect(style.blackRim.alpha, equals(255));

        // White piece rim must be significantly darker than its body to separate from light surfaces & white board lines
        expect(
          style.whiteRim.computeLuminance(),
          lessThan(0.35),
          reason: 'White piece rim in theme ${theme.name} must provide sharp outline definition',
        );
        expect(style.whiteRim.alpha, equals(255));
      }
    });

    testWidgets('12. In-Game Theme Thumbnails: All 11 themes render exact top-down in-game board preview widgets', (tester) async {
      for (final theme in BoardThemeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ThemeBoardPreview(
                  theme: theme,
                  size: 78,
                  isLocked: false,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ThemeBoardPreview), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2)); // Board image + Striker badge preview
      }
    });

    test('13. Striker Asset Completeness: All 11 themes have high-res WebP files on disk', () {
      for (final theme in BoardThemeType.values) {
        final String webpPath = AppColors.getStrikerAsset(theme);
        final webpFile = File(webpPath);

        expect(webpFile.existsSync(), isTrue, reason: 'WebP asset missing for ${theme.name} at $webpPath');
        expect(webpFile.lengthSync(), greaterThan(20000), reason: 'WebP file size suspiciously small for ${theme.name}');
      }
    });

    testWidgets('14. Striker Preview Widget: buildPreview renders correctly for all 11 themes', (tester) async {
      for (final theme in BoardThemeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: StrikerAssetService.buildPreview(theme: theme, size: 48),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Container), findsWidgets);
        expect(find.byType(Image), findsOneWidget);
      }
    });

    test('15. StrikerPainter Animation Coverage: PiecePainter executes animations for all 11 themes', () {
      final List<PieceModel> pieces = [
        PieceModel(
          id: 0,
          type: PieceType.queen,
          position: Vector2.zero,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        ),
      ];
      final PieceModel striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(0.0, 160.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(500, 500);

      for (final theme in BoardThemeType.values) {
        for (double phase = 0.0; phase <= 1.0; phase += 0.25) {
          final painter = PiecePainter(
            theme: theme,
            pieces: pieces,
            striker: striker,
            strikerGlowPhase: phase,
            isAiming: true,
            aimPower: 0.75,
            aimAngle: 0.5,
          );
          expect(
            () => painter.paint(canvas, size),
            returnsNormally,
            reason: 'PiecePainter must paint striker animation without exception for ${theme.name} at phase $phase',
          );
        }
      }
      recorder.endRecording();
    });

    test('16. Piece Asset Completeness: All 33 pieces have high-res WebP files on disk', () {
      int verifiedPieces = 0;
      for (final theme in BoardThemeType.values) {
        for (final type in [PieceType.white, PieceType.black, PieceType.queen]) {
          final String webpPath = PieceAssetService.getPieceAsset(theme, type);
          final webpFile = File(webpPath);

          expect(webpFile.existsSync(), isTrue,
              reason: 'WebP piece missing for ${theme.name} ${type.name} at $webpPath');
          expect(webpFile.lengthSync(), greaterThan(10000),
              reason: 'WebP file size suspiciously small for ${theme.name} ${type.name}');

          verifiedPieces++;
        }
      }
      expect(verifiedPieces, equals(33), reason: 'Must verify exactly 33 piece assets');
    });

    testWidgets('17. Piece Preview Widget: buildPreview renders correctly for all 33 pieces', (tester) async {
      for (final theme in BoardThemeType.values) {
        for (final type in [PieceType.white, PieceType.black, PieceType.queen]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: PieceAssetService.buildPreview(theme: theme, type: type, size: 36),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(Container), findsWidgets);
          expect(find.byType(Image), findsOneWidget);
        }
      }
    });

    testWidgets('18. ClubCoinBadge Theme Parity: Renders piece badge for all themes', (tester) async {
      for (final theme in BoardThemeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ClubCoinBadge(
                  theme: theme,
                  isWhite: true,
                  isQueen: false,
                  size: 28,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(ClubCoinBadge), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      }
    });
  });
}

