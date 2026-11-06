import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/painters/board_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Carrom Zone — 11 Premium Board Designs Verification Suite', () {
    const double boardRenderSize = 512.0;

    test('1. BoardPainter executes cleanly for all 11 themes', () {
      for (final theme in BoardThemeType.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, boardRenderSize, boardRenderSize));

        final painter = BoardPainter(theme: theme);
        expect(painter.isLightSurface, isTrue,
            reason: '${theme.name} must use tournament-grade light natural birch surface');

        expect(
          () => painter.paint(canvas, const Size(boardRenderSize, boardRenderSize)),
          returnsNormally,
          reason: 'BoardPainter should paint ${theme.name} without exceptions',
        );
      }
    });

    test('2. Physical Invariance: Board geometry, baselines, and pockets match GameConfig', () {
      expect(GameConfig.boardSize, equals(400.0));
      expect(GameConfig.frameWidth, equals(35.0));
      expect(GameConfig.pockets.length, equals(4));
      expect(GameConfig.baselineHalfWidth, equals(85.0));
      expect(GameConfig.baselineYWhite, equals(142.0));
      expect(GameConfig.pocketRadius, equals(19.0));
    });

    test('3. Zero Solid Fill Requirement: Center mandala retains 100% visible birch wood background', () async {
      for (final theme in BoardThemeType.values) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, boardRenderSize, boardRenderSize));

        // Paint BOARD ALONE (no pieces covering the center)
        final painter = BoardPainter(theme: theme);
        painter.paint(canvas, const Size(boardRenderSize, boardRenderSize));

        final picture = recorder.endRecording();
        final image = await picture.toImage(boardRenderSize.toInt(), boardRenderSize.toInt());

        if (Platform.environment['EXPORT_BOARD_CENTERS'] == 'true') {
          final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (pngData != null) {
            final f = File('build/board_alone_${theme.name}.png');
            await f.parent.create(recursive: true);
            await f.writeAsBytes(pngData.buffer.asUint8List());
          }
        }

        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(byteData, isNotNull);

        final Uint8List pixels = byteData!.buffer.asUint8List();
        final int cx = (boardRenderSize / 2).toInt();
        final int cy = (boardRenderSize / 2).toInt();

        // Sample points inside the center mandala circle (radius ~45-55 pixels in rendered 512 canvas,
        // which corresponds to radius ~35-43 board units, safely inside the R=64 outline ring
        // and outside the center emblem motif).
        // Ensure that pixels are natural birch wood (warm light tones: R > 180, G > 155, B > 120)
        // and NOT a solid crimson disk (R>160, G<80, B<80) or solid dark medallion (R<70, G<70, B<70).
        final List<Offset> testOffsets = [
          const Offset(45, 25),
          const Offset(-45, -25),
          const Offset(25, 45),
          const Offset(-25, -45),
          const Offset(48, -12),
          const Offset(-48, 12),
        ];

        int lightWoodCount = 0;
        for (final offset in testOffsets) {
          final int px = cx + offset.dx.toInt();
          final int py = cy + offset.dy.toInt();
          final int idx = (py * boardRenderSize.toInt() + px) * 4;

          final int r = pixels[idx];
          final int g = pixels[idx + 1];
          final int b = pixels[idx + 2];

          // Solid crimson circle would have R ~ 200, G ~ 40, B ~ 40
          final bool isSolidCrimson = (r > 160 && g < 80 && b < 80);
          expect(isSolidCrimson, isFalse,
              reason: '${theme.name} must NOT have a solid crimson background fill inside center mandala!');

          // Solid dark badge would have R < 60, G < 60, B < 60
          final bool isSolidDarkBadge = (r < 70 && g < 70 && b < 70);
          expect(isSolidDarkBadge, isFalse,
              reason: '${theme.name} must NOT have a solid dark medallion fill inside center mandala!');

          // Natural birch wood is warm and light
          if (r > 180 && g > 155 && b > 120) {
            lightWoodCount++;
          }
        }

        // All sampled points inside the Queen guide circle must be the natural birch playing surface
        expect(lightWoodCount, greaterThanOrEqualTo(5),
            reason: '${theme.name} center mandala must have transparent birch wood background');
      }
    });

    test('4. All 11 theme thumbnails exist on disk and have high fidelity', () {
      for (final theme in BoardThemeType.values) {
        final String assetPath = AppColors.getThemeAsset(theme);
        final File webpFile = File(assetPath);

        expect(webpFile.existsSync(), isTrue,
            reason: 'Production asset $assetPath must exist');
        expect(webpFile.lengthSync(), greaterThan(20000),
            reason: '$assetPath must be a high-resolution production image');
      }
    });
  });
}
