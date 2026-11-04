import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/app_colors.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/painters/board_painter.dart';
import 'package:carrom_master/painters/piece_painter.dart';

void main() {
  test('Render exact board thumbnails for all 11 themes', () async {
    const double renderSize = 512.0;

    // Build standard initial piece layout matching game_screen.dart
    final List<PieceModel> pieces = [];
    int idCounter = 0;

    // Center Queen
    pieces.add(
      PieceModel(
        id: idCounter++,
        type: PieceType.queen,
        position: GameConfig.queenInitialPos,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      ),
    );

    // Inner ring (6 pieces)
    for (final p in GameConfig.innerRingPieces) {
      pieces.add(
        PieceModel(
          id: idCounter++,
          type: (p['isWhite'] as bool) ? PieceType.white : PieceType.black,
          position: p['pos'] as Vector2,
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      );
    }

    // Outer ring (12 pieces)
    for (final p in GameConfig.outerRingPieces) {
      pieces.add(
        PieceModel(
          id: idCounter++,
          type: (p['isWhite'] as bool) ? PieceType.white : PieceType.black,
          position: p['pos'] as Vector2,
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      );
    }

    final PieceModel striker = PieceModel(
      id: 99,
      type: PieceType.striker,
      position: const Vector2(0.0, GameConfig.baselineYWhite),
      radius: GameConfig.strikerRadius,
      mass: GameConfig.strikerMass,
    );

    for (final theme in BoardThemeType.values) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, renderSize, renderSize));

      // 1. Paint Board
      final boardPainter = BoardPainter(theme: theme);
      boardPainter.paint(canvas, const Size(renderSize, renderSize));

      // 2. Paint Pieces & Striker
      final piecePainter = PiecePainter(
        theme: theme,
        pieces: pieces,
        striker: striker,
        strikerGlowPhase: 0.5,
      );
      piecePainter.paint(canvas, const Size(renderSize, renderSize));

      final picture = recorder.endRecording();
      final image = await picture.toImage(renderSize.toInt(), renderSize.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      expect(byteData, isNotNull);
      final pngBytes = byteData!.buffer.asUint8List();
      expect(pngBytes.length, greaterThan(1000));

      final String assetPath = AppColors.getThemeAsset(theme);
      final String pngPath = assetPath.replaceAll('.webp', '.png');

      // Production safety: Only overwrite checked-in assets when GENERATE_THUMBNAILS=true is set
      final bool shouldWrite =
          Platform.environment['GENERATE_THUMBNAILS'] == 'true';

      if (shouldWrite) {
        final File pngFile = File(pngPath);
        await pngFile.parent.create(recursive: true);
        await pngFile.writeAsBytes(pngBytes);

        final File webpFile = File(assetPath);
        await webpFile.writeAsBytes(pngBytes);

        // ignore: avoid_print
        print('Rendered exact thumbnail for ${theme.name} -> $pngPath & $assetPath (${pngBytes.length} bytes)');
      } else {
        // Assert asset exists and is non-empty
        final File webpFile = File(assetPath);
        expect(webpFile.existsSync(), isTrue,
            reason: 'Production asset $assetPath must exist');
        expect(await webpFile.length(), greaterThan(1000));
      }
    }
  });
}
