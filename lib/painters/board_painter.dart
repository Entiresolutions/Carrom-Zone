import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/game_config.dart';

class BoardPainter extends CustomPainter {
  final BoardThemeType theme;

  BoardPainter({this.theme = BoardThemeType.mahogany});

  bool get _isLightSurface =>
      theme == BoardThemeType.mahogany ||
      theme == BoardThemeType.walnutClub ||
      theme == BoardThemeType.sakuraStudio ||
      theme == BoardThemeType.goldenPalace;

  Color get _primaryLineColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return AppColors.boardLineDark;
      case BoardThemeType.walnutClub:
        return const Color(0xFF381F0E);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFF881337);
      case BoardThemeType.goldenPalace:
        return const Color(0xFF78350F);
      case BoardThemeType.royalIndigo:
        return const Color(0xFFC7D2FE);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF6EE7B7);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF67E8F9);
      case BoardThemeType.neonArena:
        return const Color(0xFFF0ABFC);
      case BoardThemeType.cosmicElite:
        return const Color(0xFFDDD6FE);
      case BoardThemeType.emerald:
      case BoardThemeType.midnight:
        return AppColors.goldLight;
    }
  }

  Color get _secondaryLineColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return AppColors.boardCrimson;
      case BoardThemeType.walnutClub:
        return const Color(0xFFB45309);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFE11D48);
      case BoardThemeType.goldenPalace:
        return const Color(0xFFD97706);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF818CF8);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF34D399);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF38BDF8);
      case BoardThemeType.neonArena:
        return const Color(0xFFE879F9);
      case BoardThemeType.cosmicElite:
        return const Color(0xFFA78BFA);
      case BoardThemeType.emerald:
      case BoardThemeType.midnight:
        return AppColors.gold.withOpacity(0.75);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale =
        size.width / (GameConfig.boardSize + GameConfig.frameWidth * 2);
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    _drawOuterFrame(canvas);
    _drawSurface(canvas);
    _drawThemeTexture(canvas);
    _drawCushionShadows(canvas);
    _drawBoundaries(canvas);
    _drawBaselines(canvas);
    _drawDiagonalArrows(canvas);
    _drawCenterMandala(canvas);
    _drawSideMidpointMedallions(canvas);
    _drawPockets(canvas);
    _drawCornerClubPlates(canvas);

    canvas.restore();
  }

  void _drawOuterFrame(Canvas canvas) {
    const double totalSize = GameConfig.boardSize + GameConfig.frameWidth * 2;

    // Soft elevation shadow beneath board
    final RRect shadowRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, 10),
        width: totalSize + 12,
        height: totalSize + 12,
      ),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      shadowRRect,
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Outer protective bumper rim
    final RRect outerRim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: totalSize + 4,
        height: totalSize + 4,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(outerRim, Paint()..color = const Color(0xFF140B07));

    // Main hardwood cabinet frame
    final RRect frameBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: totalSize, height: totalSize),
      const Radius.circular(18),
    );

    List<Color> frameColors;
    switch (theme) {
      case BoardThemeType.mahogany:
        frameColors = const [
          Color(0xFF542B18),
          Color(0xFF3E1E10),
          Color(0xFF2C140A),
          Color(0xFF1E0D06),
        ];
        break;
      case BoardThemeType.emerald:
        frameColors = const [
          Color(0xFF472918),
          Color(0xFF331C10),
          Color(0xFF24130A),
          Color(0xFF180C06),
        ];
        break;
      case BoardThemeType.midnight:
        frameColors = const [
          Color(0xFF243146),
          Color(0xFF182232),
          Color(0xFF111824),
          Color(0xFF0B1018),
        ];
        break;
      case BoardThemeType.walnutClub:
        frameColors = const [
          Color(0xFF452311),
          Color(0xFF30160A),
          Color(0xFF220D05),
          Color(0xFF160803),
        ];
        break;
      case BoardThemeType.royalIndigo:
        frameColors = const [
          Color(0xFF1E2238),
          Color(0xFF141728),
          Color(0xFF0E101D),
          Color(0xFF080912),
        ];
        break;
      case BoardThemeType.emeraldLounge:
        frameColors = const [
          Color(0xFF4F1D11),
          Color(0xFF37120A),
          Color(0xFF240A05),
          Color(0xFF170503),
        ];
        break;
      case BoardThemeType.oceanBreeze:
        frameColors = const [
          Color(0xFF4A5560),
          Color(0xFF37414A),
          Color(0xFF262E35),
          Color(0xFF1A2025),
        ];
        break;
      case BoardThemeType.sakuraStudio:
        frameColors = const [
          Color(0xFF3E1B20),
          Color(0xFF2C1115),
          Color(0xFF1C090C),
          Color(0xFF120507),
        ];
        break;
      case BoardThemeType.neonArena:
        frameColors = const [
          Color(0xFF1C1A27),
          Color(0xFF14121E),
          Color(0xFF0D0B14),
          Color(0xFF07060B),
        ];
        break;
      case BoardThemeType.goldenPalace:
        frameColors = const [
          Color(0xFF4E101B),
          Color(0xFF360A12),
          Color(0xFF23050A),
          Color(0xFF160205),
        ];
        break;
      case BoardThemeType.cosmicElite:
        frameColors = const [
          Color(0xFF24193B),
          Color(0xFF1A112D),
          Color(0xFF120A20),
          Color(0xFF0A0513),
        ];
        break;
    }

    final Rect frameRect =
        Rect.fromCenter(center: Offset.zero, width: totalSize, height: totalSize);

    canvas.drawRRect(
      frameBody,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frameColors,
        ).createShader(frameRect),
    );

    // Subtle wood/chamfer bevel ring inside the frame
    final RRect midChamber = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: totalSize - 14,
        height: totalSize - 14,
      ),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      midChamber,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Inner Brushed Brass / Cushion Inlay Bevel
    final RRect cushionTrim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConfig.boardSize + 6,
        height: GameConfig.boardSize + 6,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      cushionTrim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldLight,
            AppColors.gold,
            AppColors.goldDark,
          ],
        ).createShader(frameRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  void _drawSurface(Canvas canvas) {
    Color surfaceMid;
    Color surfaceLight;
    Color surfaceDark;

    switch (theme) {
      case BoardThemeType.mahogany:
        surfaceMid = AppColors.boardSurface;
        surfaceLight = AppColors.boardSurfaceLight;
        surfaceDark = AppColors.boardSurfaceDark;
        break;
      case BoardThemeType.emerald:
        surfaceMid = AppColors.emeraldSurface;
        surfaceLight = AppColors.emeraldSurfaceLight;
        surfaceDark = AppColors.emeraldSurfaceDark;
        break;
      case BoardThemeType.midnight:
        surfaceMid = AppColors.midnightSurface;
        surfaceLight = AppColors.midnightSurfaceLight;
        surfaceDark = AppColors.midnightSurfaceDark;
        break;
      case BoardThemeType.walnutClub:
        surfaceMid = AppColors.walnutSurface;
        surfaceLight = AppColors.walnutSurfaceLight;
        surfaceDark = AppColors.walnutSurfaceDark;
        break;
      case BoardThemeType.royalIndigo:
        surfaceMid = AppColors.royalIndigoSurface;
        surfaceLight = AppColors.royalIndigoSurfaceLight;
        surfaceDark = AppColors.royalIndigoSurfaceDark;
        break;
      case BoardThemeType.emeraldLounge:
        surfaceMid = AppColors.emeraldLoungeSurface;
        surfaceLight = AppColors.emeraldLoungeSurfaceLight;
        surfaceDark = AppColors.emeraldLoungeSurfaceDark;
        break;
      case BoardThemeType.oceanBreeze:
        surfaceMid = AppColors.oceanBreezeSurface;
        surfaceLight = AppColors.oceanBreezeSurfaceLight;
        surfaceDark = AppColors.oceanBreezeSurfaceDark;
        break;
      case BoardThemeType.sakuraStudio:
        surfaceMid = AppColors.sakuraSurface;
        surfaceLight = AppColors.sakuraSurfaceLight;
        surfaceDark = AppColors.sakuraSurfaceDark;
        break;
      case BoardThemeType.neonArena:
        surfaceMid = AppColors.neonArenaSurface;
        surfaceLight = AppColors.neonArenaSurfaceLight;
        surfaceDark = AppColors.neonArenaSurfaceDark;
        break;
      case BoardThemeType.goldenPalace:
        surfaceMid = AppColors.goldenPalaceSurface;
        surfaceLight = AppColors.goldenPalaceSurfaceLight;
        surfaceDark = AppColors.goldenPalaceSurfaceDark;
        break;
      case BoardThemeType.cosmicElite:
        surfaceMid = AppColors.cosmicEliteSurface;
        surfaceLight = AppColors.cosmicEliteSurfaceLight;
        surfaceDark = AppColors.cosmicEliteSurfaceDark;
        break;
    }

    final Rect boardRect = Rect.fromCenter(
      center: Offset.zero,
      width: GameConfig.boardSize,
      height: GameConfig.boardSize,
    );

    canvas.drawRect(boardRect, Paint()..color = surfaceMid);

    // Natural overhead club table lighting gradient
    final Paint surfaceShader = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.1),
        radius: 0.92,
        colors: [
          surfaceLight,
          surfaceMid,
          surfaceDark,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(boardRect);
    canvas.drawRect(boardRect, surfaceShader);
  }

  void _drawThemeTexture(Canvas canvas) {
    const double half = GameConfig.halfBoard;

    if (theme == BoardThemeType.mahogany) {
      // Fine birchwood plywood grain
      final Paint grainPaint = Paint()
        ..color = AppColors.boardSurfaceHighlight.withOpacity(0.16)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (double y = -half + 8; y < half; y += 8.0) {
        final Path path = Path();
        path.moveTo(-half, y);
        for (double x = -half; x <= half; x += 25.0) {
          final double wave = math.sin((x * 0.6 + y * 1.4) * 0.035) * 1.4;
          path.lineTo(x, y + wave);
        }
        canvas.drawPath(path, grainPaint);
      }
    } else if (theme == BoardThemeType.emerald) {
      // Subtle woven club baize texture
      final Paint weavePaint = Paint()
        ..color = AppColors.emeraldSurfaceLight.withOpacity(0.08)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;

      for (double d = -half; d < half; d += 10.0) {
        canvas.drawLine(Offset(-half, d), Offset(half, d), weavePaint);
        canvas.drawLine(Offset(d, -half), Offset(d, half), weavePaint);
      }
    } else if (theme == BoardThemeType.midnight) {
      // Architectural concentric subtle grid lines
      final Paint subtleGrid = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset.zero, 118, subtleGrid);
      canvas.drawCircle(Offset.zero, 152, subtleGrid);
    } else if (theme == BoardThemeType.walnutClub) {
      // Warm amber grain lines
      final Paint walnutGrain = Paint()
        ..color = const Color(0xFF8C5326).withOpacity(0.12)
        ..strokeWidth = 0.85
        ..style = PaintingStyle.stroke;
      for (double y = -half + 10; y < half; y += 12.0) {
        final Path p = Path()..moveTo(-half, y);
        for (double x = -half; x <= half; x += 30.0) {
          final double wave = math.sin((x * 0.45 + y * 1.2) * 0.03) * 2.0;
          p.lineTo(x, y + wave);
        }
        canvas.drawPath(p, walnutGrain);
      }
    } else if (theme == BoardThemeType.royalIndigo) {
      // Royal diamond velvet lattice
      final Paint lattice = Paint()
        ..color = const Color(0xFF818CF8).withOpacity(0.06)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      for (double d = -half * 2; d < half * 2; d += 24.0) {
        canvas.drawLine(Offset(-half, d), Offset(half, d + half * 2), lattice);
        canvas.drawLine(Offset(-half, d + half * 2), Offset(half, d), lattice);
      }
    } else if (theme == BoardThemeType.emeraldLounge) {
      // Opulent crosshatch gold filigree weave
      final Paint weave = Paint()
        ..color = const Color(0xFFD4AF37).withOpacity(0.07)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      for (double d = -half; d < half; d += 14.0) {
        canvas.drawLine(Offset(-half, d), Offset(half, d), weave);
        canvas.drawLine(Offset(d, -half), Offset(d, half), weave);
      }
    } else if (theme == BoardThemeType.oceanBreeze) {
      // Coastal lagoon caustic waves
      final Paint wavePaint = Paint()
        ..color = const Color(0xFF67E8F9).withOpacity(0.07)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (double y = -half + 14; y < half; y += 18.0) {
        final Path p = Path()..moveTo(-half, y);
        for (double x = -half; x <= half; x += 20.0) {
          final double wave = math.sin((x * 0.8 + y) * 0.04) * 2.8;
          p.lineTo(x, y + wave);
        }
        canvas.drawPath(p, wavePaint);
      }
    } else if (theme == BoardThemeType.sakuraStudio) {
      // Delicate sakura floral circular rings
      final Paint sakuraPaint = Paint()
        ..color = const Color(0xFFF43F5E).withOpacity(0.08)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset.zero, 110, sakuraPaint);
      canvas.drawCircle(Offset.zero, 140, sakuraPaint);
    } else if (theme == BoardThemeType.neonArena) {
      // Cyber matte laser grid
      final Paint cyberGrid = Paint()
        ..color = const Color(0xFFD946EF).withOpacity(0.08)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      for (double d = -half; d < half; d += 24.0) {
        canvas.drawLine(Offset(-half, d), Offset(half, d), cyberGrid);
        canvas.drawLine(Offset(d, -half), Offset(d, half), cyberGrid);
      }
    } else if (theme == BoardThemeType.goldenPalace) {
      // Imperial 24k gold diamond mesh
      final Paint goldLattice = Paint()
        ..color = const Color(0xFFB45309).withOpacity(0.08)
        ..strokeWidth = 0.65
        ..style = PaintingStyle.stroke;
      for (double d = -half * 2; d < half * 2; d += 20.0) {
        canvas.drawLine(Offset(-half, d), Offset(half, d + half * 2), goldLattice);
      }
    } else if (theme == BoardThemeType.cosmicElite) {
      // Nebula orbital rings and stardust
      final Paint cosmicOrbit = Paint()
        ..color = const Color(0xFFA78BFA).withOpacity(0.08)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset.zero, 95, cosmicOrbit);
      canvas.drawCircle(Offset.zero, 135, cosmicOrbit);
      canvas.drawCircle(Offset.zero, 165, cosmicOrbit);
    }
  }

  void _drawCushionShadows(Canvas canvas) {
    const double half = GameConfig.halfBoard;
    const double shadowDepth = 11.0;
    final Color shadowStart =
        _isLightSurface ? const Color(0x402C180C) : const Color(0x80000000);

    // Top cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, -half, half, -half + shadowDepth),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, -half, half, -half + shadowDepth)),
    );
    // Bottom cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, half - shadowDepth, half, half),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, half - shadowDepth, half, half)),
    );
    // Left cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, -half, -half + shadowDepth, half),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, -half, -half + shadowDepth, half)),
    );
    // Right cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(half - shadowDepth, -half, half, half),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(half - shadowDepth, -half, half, half)),
    );
  }

  void _drawBoundaries(Canvas canvas) {
    const double half = GameConfig.halfBoard;
    final Paint boundaryPaint = Paint()
      ..color = _primaryLineColor.withOpacity(_isLightSurface ? 0.45 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: half * 2 - 22,
        height: half * 2 - 22,
      ),
      boundaryPaint,
    );
  }

  void _drawBaselines(Canvas canvas) {
    const double lineHalf = GameConfig.baselineHalfWidth;
    const double circleR = 13.5;
    const double baseOffset = GameConfig.baselineYWhite;
    const double trackHalfGap = 11.5;

    final Paint outerLinePaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.88)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint innerLinePaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.65)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final Paint circleRingPaint = Paint()
      ..color = _primaryLineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint crimsonFill = Paint()
      ..color = AppColors.boardCrimson
      ..style = PaintingStyle.fill;

    // 1. Horizontal Baselines (Top & Bottom)
    for (final double ySign in [-1.0, 1.0]) {
      final double y = baseOffset * ySign;
      canvas.drawLine(
        Offset(-lineHalf, y - trackHalfGap),
        Offset(lineHalf, y - trackHalfGap),
        outerLinePaint,
      );
      canvas.drawLine(
        Offset(-lineHalf, y + trackHalfGap),
        Offset(lineHalf, y + trackHalfGap),
         innerLinePaint,
      );
      // Center guide line
      canvas.drawLine(
        Offset(-lineHalf, y),
        Offset(lineHalf, y),
        Paint()
          ..color = _secondaryLineColor.withOpacity(0.32)
          ..strokeWidth = 1.0,
      );

      for (final double xEnd in [-lineHalf, lineHalf]) {
        final Offset c = Offset(xEnd, y);
        canvas.drawCircle(c, circleR, crimsonFill);
        canvas.drawCircle(c, circleR, circleRingPaint);
        canvas.drawCircle(
          c,
          circleR * 0.45,
          Paint()
            ..color = AppColors.ivory
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(c, 2.2, Paint()..color = AppColors.ivory);
      }
    }

    // 2. Vertical Baselines (Left & Right)
    for (final double xSign in [-1.0, 1.0]) {
      final double x = baseOffset * xSign;
      canvas.drawLine(
        Offset(x - trackHalfGap, -lineHalf),
        Offset(x - trackHalfGap, lineHalf),
        outerLinePaint,
      );
      canvas.drawLine(
        Offset(x + trackHalfGap, -lineHalf),
        Offset(x + trackHalfGap, lineHalf),
        innerLinePaint,
      );

      for (final double yEnd in [-lineHalf, lineHalf]) {
        final Offset c = Offset(x, yEnd);
        canvas.drawCircle(c, circleR, crimsonFill);
        canvas.drawCircle(c, circleR, circleRingPaint);
        canvas.drawCircle(
          c,
          circleR * 0.45,
          Paint()
            ..color = AppColors.ivory
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(c, 2.2, Paint()..color = AppColors.ivory);
      }
    }
  }

  void _drawDiagonalArrows(Canvas canvas) {
    final Paint arrowPaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.82)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final List<Offset> signs = const [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 1),
      Offset(1, 1),
    ];

    for (final sign in signs) {
      final Offset start = Offset(60 * sign.dx, 60 * sign.dy);
      final Offset end = Offset(152 * sign.dx, 152 * sign.dy);

      // Main diagonal shaft
      canvas.drawLine(start, end, arrowPaint);

      // Decorative tournament semicircular arc near pocket end
      final Offset arcCenter = Offset(136 * sign.dx, 136 * sign.dy);
      final double baseAngle = math.atan2(sign.dy, sign.dx);
      final Path arcPath = Path()
        ..addArc(
          Rect.fromCircle(center: arcCenter, radius: 18.0),
          baseAngle + math.pi * 0.55,
          math.pi * 0.9,
        );
      canvas.drawPath(arcPath, arrowPaint);

      // Precision arrowhead tip pointing toward pocket
      final Offset tipLeft = Offset(
        end.dx - math.cos(baseAngle - 0.42) * 10,
        end.dy - math.sin(baseAngle - 0.42) * 10,
      );
      final Offset tipRight = Offset(
        end.dx - math.cos(baseAngle + 0.42) * 10,
        end.dy - math.sin(baseAngle + 0.42) * 10,
      );
      canvas.drawLine(end, tipLeft, arrowPaint);
      canvas.drawLine(end, tipRight, arrowPaint);

      // Tail fletching diamond at inner start
      canvas.drawCircle(start, 3.2, Paint()..color = _secondaryLineColor);
      canvas.drawCircle(
        start,
        6.0,
        Paint()
          ..color = _primaryLineColor.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawCenterMandala(Canvas canvas) {
    final Paint linePaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Outer Tournament Circle (R = 74) & double ring (R = 70)
    canvas.drawCircle(Offset.zero, 74.0, linePaint);
    canvas.drawCircle(
      Offset.zero,
      70.0,
      Paint()
        ..color = _secondaryLineColor.withOpacity(0.65)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // 12-Point Geometric Compass Rose Star
    const int points = 12;
    const double innerR = 22.0;
    const double outerR = 67.0;

    for (int i = 0; i < points; i++) {
      final double angle = (i / points) * math.pi * 2;
      final double halfStep = (0.5 / points) * math.pi * 2;

      final Offset tip = Offset(
        math.cos(angle) * outerR,
        math.sin(angle) * outerR,
      );
      final Offset leftBase = Offset(
        math.cos(angle - halfStep) * innerR,
        math.sin(angle - halfStep) * innerR,
      );
      final Offset rightBase = Offset(
        math.cos(angle + halfStep) * innerR,
        math.sin(angle + halfStep) * innerR,
      );

      final Path petal = Path()
        ..moveTo(0, 0)
        ..lineTo(leftBase.dx, leftBase.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(rightBase.dx, rightBase.dy)
        ..close();

      final bool isPrimaryPetal = i % 2 == 0;
      canvas.drawPath(
        petal,
        Paint()
          ..color = isPrimaryPetal
              ? AppColors.boardCrimson.withOpacity(_isLightSurface ? 0.78 : 0.65)
              : _primaryLineColor.withOpacity(_isLightSurface ? 0.75 : 0.45)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        petal,
        Paint()
          ..color = _primaryLineColor.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Mid ring (R = 46)
    canvas.drawCircle(
      Offset.zero,
      46.0,
      Paint()
        ..color = _primaryLineColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Center Queen Circle (R = 16)
    canvas.drawCircle(
      Offset.zero,
      16.0,
      Paint()..color = AppColors.boardCrimson,
    );
    canvas.drawCircle(
      Offset.zero,
      16.0,
      Paint()
        ..color = _isLightSurface ? AppColors.ivory : AppColors.goldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset.zero,
      6.0,
      Paint()
        ..color = AppColors.ivory.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawSideMidpointMedallions(Canvas canvas) {
    const double offset = GameConfig.baselineYWhite;
    const double r = 11.5;

    final List<Offset> centers = const [
      Offset(0.0, -offset),
      Offset(0.0, offset),
      Offset(-offset, 0.0),
      Offset(offset, 0.0),
    ];

    for (final pos in centers) {
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = _primaryLineColor.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        pos,
        3.5,
        Paint()..color = _secondaryLineColor,
      );
    }
  }

  void _drawPockets(Canvas canvas) {
    for (final pocket in GameConfig.pockets) {
      final Offset p = Offset(pocket.x, pocket.y);

      // 1. Outer Brass / Wood Collar
      canvas.drawCircle(
        p,
        GameConfig.pocketRadius + 6.5,
        Paint()..color = AppColors.goldDark.withOpacity(0.75),
      );

      // 2. Dark Leather / Hardwood Bezel
      canvas.drawCircle(
        p,
        GameConfig.pocketRadius + 4.0,
        Paint()..color = AppColors.pocketRing,
      );

      // 3. Deep Pocket Cavity
      canvas.drawCircle(
        p,
        GameConfig.pocketRadius,
        Paint()..color = AppColors.pocketHole,
      );

      // 4. Woven Cord Netting inside Pocket
      final Paint netPaint = Paint()
        ..color = const Color(0xFF281D16)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;

      canvas.save();
      final Path clipPocket = Path()
        ..addOval(
          Rect.fromCircle(center: p, radius: GameConfig.pocketRadius - 1.5),
        );
      canvas.clipPath(clipPocket);

      for (double offset = -GameConfig.pocketRadius;
          offset <= GameConfig.pocketRadius;
          offset += 5.5) {
        canvas.drawLine(
          Offset(p.dx - GameConfig.pocketRadius, p.dy + offset),
          Offset(
            p.dx + GameConfig.pocketRadius,
            p.dy + offset + GameConfig.pocketRadius * 0.75,
          ),
          netPaint,
        );
        canvas.drawLine(
          Offset(
            p.dx - GameConfig.pocketRadius,
            p.dy + offset + GameConfig.pocketRadius * 0.75,
          ),
          Offset(p.dx + GameConfig.pocketRadius, p.dy + offset),
          netPaint,
        );
      }
      canvas.restore();

      // 5. Inner 3D Depth Shadow
      canvas.drawCircle(
        Offset(p.dx + 2.0, p.dy + 2.0),
        GameConfig.pocketRadius - 2.5,
        Paint()..color = Colors.black.withOpacity(0.72),
      );

      // 6. Crisp Rim Highlight
      final Path rimArc = Path()
        ..addArc(
          Rect.fromCircle(center: p, radius: GameConfig.pocketRadius),
          -math.pi * 0.75,
          math.pi * 0.55,
        );
      canvas.drawPath(
        rimArc,
        Paint()
          ..color = AppColors.goldLight.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawCornerClubPlates(Canvas canvas) {
    const double halfTotal =
        GameConfig.boardSize / 2.0 + GameConfig.frameWidth;
    const double inset = 14.0;

    final List<Map<String, dynamic>> corners = [
      {'pos': const Offset(-halfTotal + inset, -halfTotal + inset), 'angle': 0.0},
      {'pos': const Offset(halfTotal - inset, -halfTotal + inset), 'angle': math.pi / 2},
      {'pos': const Offset(halfTotal - inset, halfTotal - inset), 'angle': math.pi},
      {'pos': const Offset(-halfTotal + inset, halfTotal - inset), 'angle': -math.pi / 2},
    ];

    final Paint plateStroke = Paint()
      ..color = AppColors.gold.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint rivetPaint = Paint()..color = AppColors.goldLight;

    for (final corner in corners) {
      canvas.save();
      final Offset pos = corner['pos'] as Offset;
      final double rot = corner['angle'] as double;
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      // Clean geometric brass L-joint inlay with rivets
      final Path bracket = Path()
        ..moveTo(0, 26)
        ..lineTo(0, 4)
        ..quadraticBezierTo(0, 0, 4, 0)
        ..lineTo(26, 0);
      canvas.drawPath(bracket, plateStroke);

      canvas.drawCircle(const Offset(5, 5), 2.0, rivetPaint);
      canvas.drawCircle(const Offset(20, 3), 1.4, rivetPaint);
      canvas.drawCircle(const Offset(3, 20), 1.4, rivetPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
