import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/game_config.dart';

/// Renders the tournament Carrom board for all 11 themes with exact fidelity to the
/// approved master reference art.
///
/// Features:
/// 1. Theme-specific handcrafted frames (rosewood, teal, navy, walnut, indigo,
///    emerald, aquamarine, sakura rose, carbon neon, ivory marble, cosmic violet).
/// 2. Metallic corner brackets, rivets, and side ornaments.
/// 3. Tournament-grade natural birch wood playing surface across all 11 tables.
/// 4. Crisp tournament baselines, crimson baseline circles, and pocket arrows.
/// 5. Center mandala: 100% transparent center background with ZERO solid disk/badge fills,
///    featuring thin circular outlines and theme-specific vector line artwork.
/// 6. Tournament pockets with netted cavities and metallic collars.
/// 7. 100% physical invariance — zero changes to coordinates, pockets, or bounds.
class BoardPainter extends CustomPainter {
  final BoardThemeType theme;

  BoardPainter({this.theme = BoardThemeType.mahogany});

  /// All 11 themes use tournament-grade light natural birch wood playing surfaces.
  bool get isLightSurface => true;

  Color get _primaryLineColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return const Color(0xFF2C150D);
      case BoardThemeType.walnutClub:
        return const Color(0xFF32170A);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFF3D121B);
      case BoardThemeType.goldenPalace:
        return const Color(0xFF332010);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF1B1D38);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF0C2E1F);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF0C3844);
      case BoardThemeType.neonArena:
        return const Color(0xFF161A24);
      case BoardThemeType.cosmicElite:
        return const Color(0xFF1E1033);
      case BoardThemeType.emerald:
        return const Color(0xFF0D332D);
      case BoardThemeType.midnight:
        return const Color(0xFF142033);
    }
  }

  Color get _secondaryLineColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return AppColors.boardCrimson;
      case BoardThemeType.walnutClub:
        return const Color(0xFFB45309);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFBE185D);
      case BoardThemeType.goldenPalace:
        return const Color(0xFFD4AF37);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF6366F1);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF10B981);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF0284C7);
      case BoardThemeType.neonArena:
        return const Color(0xFF00B4D8);
      case BoardThemeType.cosmicElite:
        return const Color(0xFF8B5CF6);
      case BoardThemeType.emerald:
        return const Color(0xFF147A6B);
      case BoardThemeType.midnight:
        return const Color(0xFFC5993B);
    }
  }

  Color get _emblemStrokeColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return const Color(0xFF5A1D10);
      case BoardThemeType.emerald:
        return const Color(0xFF0E5246);
      case BoardThemeType.midnight:
        return const Color(0xFF9E7728);
      case BoardThemeType.walnutClub:
        return const Color(0xFF8C581E);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF3E3B82);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF9E7728);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF0B647A);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFA22D50);
      case BoardThemeType.neonArena:
        return const Color(0xFF0096C7);
      case BoardThemeType.goldenPalace:
        return const Color(0xFFB8861B);
      case BoardThemeType.cosmicElite:
        return const Color(0xFFA87728);
    }
  }

  Color get _emblemAccentColor {
    switch (theme) {
      case BoardThemeType.mahogany:
        return const Color(0xFFB93322);
      case BoardThemeType.emerald:
        return const Color(0xFF198776);
      case BoardThemeType.midnight:
        return const Color(0xFFD4AF37);
      case BoardThemeType.walnutClub:
        return const Color(0xFFD49A3D);
      case BoardThemeType.royalIndigo:
        return const Color(0xFF6366F1);
      case BoardThemeType.emeraldLounge:
        return const Color(0xFF15803D);
      case BoardThemeType.oceanBreeze:
        return const Color(0xFF0284C7);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFE11D48);
      case BoardThemeType.neonArena:
        return const Color(0xFF00E5FF);
      case BoardThemeType.goldenPalace:
        return const Color(0xFFD4AF37);
      case BoardThemeType.cosmicElite:
        return const Color(0xFF8B5CF6);
    }
  }

  Color get _cushionTrimColor {
    switch (theme) {
      case BoardThemeType.mahogany:
      case BoardThemeType.walnutClub:
      case BoardThemeType.midnight:
      case BoardThemeType.emeraldLounge:
      case BoardThemeType.goldenPalace:
      case BoardThemeType.cosmicElite:
        return const Color(0xFFD4AF37);
      case BoardThemeType.emerald:
      case BoardThemeType.royalIndigo:
      case BoardThemeType.oceanBreeze:
        return const Color(0xFFD1D5DB);
      case BoardThemeType.sakuraStudio:
        return const Color(0xFFE8A598);
      case BoardThemeType.neonArena:
        return const Color(0xFF00E5FF);
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
    _drawFrameSideOrnaments(canvas);
    _drawPockets(canvas);
    _drawCornerClubPlates(canvas);

    canvas.restore();
  }

  void _drawOuterFrame(Canvas canvas) {
    const double totalSize = GameConfig.boardSize + GameConfig.frameWidth * 2;
    final Rect frameRect =
        Rect.fromCenter(center: Offset.zero, width: totalSize, height: totalSize);

    // 1. Soft elevation drop shadow beneath board
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

    // 2. Outer protective bumper rim
    final RRect outerRim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: totalSize + 4,
        height: totalSize + 4,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(outerRim, Paint()..color = const Color(0xFF110A06));

    // 3. Main frame body gradient matching theme
    List<Color> frameColors;
    switch (theme) {
      case BoardThemeType.mahogany:
        frameColors = const [
          Color(0xFF5C2615),
          Color(0xFF42180B),
          Color(0xFF2C0F06),
          Color(0xFF1A0703),
        ];
        break;
      case BoardThemeType.emerald:
        frameColors = const [
          Color(0xFF145C51),
          Color(0xFF0C423A),
          Color(0xFF072A24),
          Color(0xFF031713),
        ];
        break;
      case BoardThemeType.midnight:
        frameColors = const [
          Color(0xFF1E3350),
          Color(0xFF132238),
          Color(0xFF0C1625),
          Color(0xFF060B12),
        ];
        break;
      case BoardThemeType.walnutClub:
        frameColors = const [
          Color(0xFF4C2512),
          Color(0xFF36180A),
          Color(0xFF240E05),
          Color(0xFF150702),
        ];
        break;
      case BoardThemeType.royalIndigo:
        frameColors = const [
          Color(0xFF24274F),
          Color(0xFF181A38),
          Color(0xFF101128),
          Color(0xFF080918),
        ];
        break;
      case BoardThemeType.emeraldLounge:
        frameColors = const [
          Color(0xFF12523A),
          Color(0xFF0B3A28),
          Color(0xFF06261A),
          Color(0xFF03160E),
        ];
        break;
      case BoardThemeType.oceanBreeze:
        frameColors = const [
          Color(0xFF166B85),
          Color(0xFF0E4D61),
          Color(0xFF083341),
          Color(0xFF041F28),
        ];
        break;
      case BoardThemeType.sakuraStudio:
        frameColors = const [
          Color(0xFF5A2534),
          Color(0xFF421724),
          Color(0xFF2E0D17),
          Color(0xFF1C060C),
        ];
        break;
      case BoardThemeType.neonArena:
        frameColors = const [
          Color(0xFF1F222C),
          Color(0xFF13151D),
          Color(0xFF0A0C11),
          Color(0xFF040507),
        ];
        break;
      case BoardThemeType.goldenPalace:
        frameColors = const [
          Color(0xFFF2ECE2),
          Color(0xFFE2D6C6),
          Color(0xFFD0BFAC),
          Color(0xFFB8A692),
        ];
        break;
      case BoardThemeType.cosmicElite:
        frameColors = const [
          Color(0xFF2E1650),
          Color(0xFF1E0C38),
          Color(0xFF130626),
          Color(0xFF0A0215),
        ];
        break;
    }

    final RRect frameBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: totalSize, height: totalSize),
      const Radius.circular(18),
    );

    canvas.drawRRect(
      frameBody,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frameColors,
        ).createShader(frameRect),
    );

    // Marble veins for Golden Palace
    if (theme == BoardThemeType.goldenPalace) {
      final Paint veinPaint = Paint()
        ..color = const Color(0xFFC5993B).withOpacity(0.18)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final Path veinPath = Path()
        ..moveTo(-totalSize / 2 + 10, -totalSize / 2 + 30)
        ..quadraticBezierTo(-totalSize / 4, -totalSize / 2 + 15, 0, -totalSize / 2 + 35)
        ..quadraticBezierTo(totalSize / 4, -totalSize / 2 + 10, totalSize / 2 - 10, -totalSize / 2 + 40);
      canvas.drawPath(veinPath, veinPaint);
      final Path veinPath2 = Path()
        ..moveTo(-totalSize / 2 + 30, totalSize / 2 - 10)
        ..quadraticBezierTo(0, totalSize / 2 - 35, totalSize / 2 - 30, totalSize / 2 - 15);
      canvas.drawPath(veinPath2, veinPaint);
    }

    // 4. Subtle wood / lacquer chamfer line
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
        ..color = (theme == BoardThemeType.goldenPalace)
            ? const Color(0xFF785E2F).withOpacity(0.25)
            : Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 5. Inner Cushion Inlay Bevel
    final RRect cushionTrim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: GameConfig.boardSize + 6,
        height: GameConfig.boardSize + 6,
      ),
      const Radius.circular(8),
    );

    final Paint cushionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    if (theme == BoardThemeType.neonArena) {
      // High-glow electric cyan neon inner conduit
      cushionPaint
        ..color = const Color(0xFF00E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.5);
    } else {
      cushionPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _cushionTrimColor.withOpacity(0.95),
          _cushionTrimColor,
          _cushionTrimColor.withOpacity(0.70),
        ],
      ).createShader(frameRect);
    }
    canvas.drawRRect(cushionTrim, cushionPaint);

    // Neon Arena: Glowing cyan light tubes along the 4 frame borders
    if (theme == BoardThemeType.neonArena) {
      final double halfInner = GameConfig.boardSize / 2.0;
      final double barLength = GameConfig.boardSize - 110.0;
      final double barDist = halfInner + GameConfig.frameWidth * 0.48;

      final Paint neonGlow = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.5)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final Paint neonCore = Paint()
        ..color = const Color(0xFFE0FFFF)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Top bar
      canvas.drawLine(Offset(-barLength / 2, -barDist), Offset(barLength / 2, -barDist), neonGlow);
      canvas.drawLine(Offset(-barLength / 2, -barDist), Offset(barLength / 2, -barDist), neonCore);
      // Bottom bar
      canvas.drawLine(Offset(-barLength / 2, barDist), Offset(barLength / 2, barDist), neonGlow);
      canvas.drawLine(Offset(-barLength / 2, barDist), Offset(barLength / 2, barDist), neonCore);
      // Left bar
      canvas.drawLine(Offset(-barDist, -barLength / 2), Offset(-barDist, barLength / 2), neonGlow);
      canvas.drawLine(Offset(-barDist, -barLength / 2), Offset(-barDist, barLength / 2), neonCore);
      // Right bar
      canvas.drawLine(Offset(barDist, -barLength / 2), Offset(barDist, barLength / 2), neonGlow);
      canvas.drawLine(Offset(barDist, -barLength / 2), Offset(barDist, barLength / 2), neonCore);
    }
  }

  void _drawSurface(Canvas canvas) {
    // Tournament-grade natural birch wood playing surface across all tables
    Color surfaceMid;
    Color surfaceLight;
    Color surfaceDark;

    switch (theme) {
      case BoardThemeType.mahogany:
        surfaceMid = const Color(0xFFF3E2C6);
        surfaceLight = const Color(0xFFFAF0DD);
        surfaceDark = const Color(0xFFE2CCAA);
        break;
      case BoardThemeType.emerald:
        surfaceMid = const Color(0xFFF2E2C8);
        surfaceLight = const Color(0xFFFAF1DF);
        surfaceDark = const Color(0xFFE0CDAD);
        break;
      case BoardThemeType.midnight:
        surfaceMid = const Color(0xFFF4E4CA);
        surfaceLight = const Color(0xFFFCF3E3);
        surfaceDark = const Color(0xFFE4CFB0);
        break;
      case BoardThemeType.walnutClub:
        surfaceMid = const Color(0xFFF3DFC2);
        surfaceLight = const Color(0xFFFBF0DE);
        surfaceDark = const Color(0xFFE1CAA6);
        break;
      case BoardThemeType.royalIndigo:
        surfaceMid = const Color(0xFFF4E4CB);
        surfaceLight = const Color(0xFFFCF2E3);
        surfaceDark = const Color(0xFFE2CEAF);
        break;
      case BoardThemeType.emeraldLounge:
        surfaceMid = const Color(0xFFF2E1C6);
        surfaceLight = const Color(0xFFFAF0DD);
        surfaceDark = const Color(0xFFE0CCAA);
        break;
      case BoardThemeType.oceanBreeze:
        surfaceMid = const Color(0xFFF5E6CE);
        surfaceLight = const Color(0xFFFCF3E5);
        surfaceDark = const Color(0xFFE4D0B4);
        break;
      case BoardThemeType.sakuraStudio:
        surfaceMid = const Color(0xFFF6E5DE);
        surfaceLight = const Color(0xFFFCF2ED);
        surfaceDark = const Color(0xFFE7D1C7);
        break;
      case BoardThemeType.neonArena:
        surfaceMid = const Color(0xFFF3E3CB);
        surfaceLight = const Color(0xFFFAF0DF);
        surfaceDark = const Color(0xFFE2CEAF);
        break;
      case BoardThemeType.goldenPalace:
        surfaceMid = const Color(0xFFF7EAD7);
        surfaceLight = const Color(0xFFFCF5EA);
        surfaceDark = const Color(0xFFE9D6BE);
        break;
      case BoardThemeType.cosmicElite:
        surfaceMid = const Color(0xFFF4E3CA);
        surfaceLight = const Color(0xFFFAF0DF);
        surfaceDark = const Color(0xFFE2CDAD);
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
        center: const Alignment(-0.08, -0.08),
        radius: 0.94,
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

    // Natural wood grain across all themes
    final Paint grainPaint = Paint()
      ..color = const Color(0xFF8B5E3C).withOpacity(0.08)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    for (double y = -half + 8; y < half; y += 10.0) {
      final Path path = Path()..moveTo(-half, y);
      for (double x = -half; x <= half; x += 25.0) {
        final double wave = math.sin((x * 0.5 + y * 1.3) * 0.035) * 1.5;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, grainPaint);
    }
  }

  void _drawCushionShadows(Canvas canvas) {
    const double half = GameConfig.halfBoard;
    const double shadowDepth = 11.0;
    const Color shadowStart = Color(0x382C180C);

    // Top cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, -half, half, -half + shadowDepth),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, -half, half, -half + shadowDepth)),
    );
    // Bottom cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, half - shadowDepth, half, half),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, half - shadowDepth, half, half)),
    );
    // Left cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(-half, -half, -half + shadowDepth, half),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(-half, -half, -half + shadowDepth, half)),
    );
    // Right cushion shadow
    canvas.drawRect(
      Rect.fromLTRB(half - shadowDepth, -half, half, half),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [shadowStart, Colors.transparent],
        ).createShader(Rect.fromLTRB(half - shadowDepth, -half, half, half)),
    );
  }

  void _drawBoundaries(Canvas canvas) {
    const double half = GameConfig.halfBoard;
    final Paint boundaryPaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

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
      ..strokeWidth = 1.8
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
          ..color = _secondaryLineColor.withOpacity(0.35)
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
            ..color = const Color(0xFFFFF7ED)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(c, 2.2, Paint()..color = const Color(0xFFFFF7ED));
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
            ..color = const Color(0xFFFFF7ED)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(c, 2.2, Paint()..color = const Color(0xFFFFF7ED));
      }
    }
  }

  void _drawDiagonalArrows(Canvas canvas) {
    final Paint arrowPaint = Paint()
      ..color = _primaryLineColor.withOpacity(0.80)
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

      // Decorative tournament arc near pocket end
      final Offset arcCenter = Offset(136 * sign.dx, 136 * sign.dy);
      final double baseAngle = math.atan2(sign.dy, sign.dx);
      final Path arcPath = Path()
        ..addArc(
          Rect.fromCircle(center: arcCenter, radius: 18.0),
          baseAngle + math.pi * 0.55,
          math.pi * 0.9,
        );
      canvas.drawPath(arcPath, arrowPaint);

      // Arrowhead tip pointing toward pocket
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

      // Tail fletching circle at inner start
      canvas.drawCircle(start, 3.0, Paint()..color = _secondaryLineColor);
      canvas.drawCircle(
        start,
        5.8,
        Paint()
          ..color = _primaryLineColor.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  /// CRITICAL REQUIREMENT:
  /// Completely REMOVE solid background fills behind center logos.
  /// No colored discs, medallions, badges, or solid colored patches.
  /// Board wood surface is 100% visible inside the thin circular outlines.
  /// Center logos match the approved reference image with authentic shapes, details, and style.
  void _drawCenterMandala(Canvas canvas) {
    // 1. Thin Circular Outline around the emblem
    final Paint outlinePaint = Paint()
      ..color = _emblemStrokeColor.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final Paint accentOutlinePaint = Paint()
      ..color = _emblemAccentColor.withOpacity(0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Outer thin circular outline ring (R = 64.0) matching the approved reference tables
    canvas.drawCircle(Offset.zero, 64.0, outlinePaint);
    canvas.drawCircle(Offset.zero, 60.5, accentOutlinePaint);

    // 2. Draw authentic theme center emblem directly on the natural birch wood surface
    _drawThemeCenterEmblem(canvas);

    // 3. Subtle tournament Queen placement registration dot at center
    canvas.drawCircle(
      Offset.zero,
      2.0,
      Paint()..color = _emblemStrokeColor.withOpacity(0.4),
    );
  }

  void _drawThemeCenterEmblem(Canvas canvas) {
    switch (theme) {
      case BoardThemeType.mahogany:
        // 1. Classic Birch & Rosewood — 8-Point Faceted Compass Star
        const double rMajor = 50.0;
        const double rMinor = 28.0;
        const double rValley = 14.0;
        const double rInner = 12.0;

        final Paint darkRayPaint = Paint()
          ..color = const Color(0xFF8B1D12)
          ..style = PaintingStyle.fill;
        final Paint lightRayPaint = Paint()
          ..color = const Color(0xFFC0392B)
          ..style = PaintingStyle.fill;
        final Paint starStroke = Paint()
          ..color = const Color(0xFF4A1208)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < 8; i++) {
          final double ang = i * math.pi / 4.0;
          final double angLeft = (i - 0.5) * math.pi / 4.0;
          final double angRight = (i + 0.5) * math.pi / 4.0;
          final double rTip = (i % 2 == 0) ? rMajor : rMinor;

          final Offset tip = Offset(math.cos(ang) * rTip, math.sin(ang) * rTip);
          final Offset innerTip = Offset(math.cos(ang) * rInner, math.sin(ang) * rInner);
          final Offset leftVal = Offset(math.cos(angLeft) * rValley, math.sin(angLeft) * rValley);
          final Offset rightVal = Offset(math.cos(angRight) * rValley, math.sin(angRight) * rValley);

          // Left facet (darker side)
          final Path leftFacet = Path()
            ..moveTo(innerTip.dx, innerTip.dy)
            ..lineTo(leftVal.dx, leftVal.dy)
            ..lineTo(tip.dx, tip.dy)
            ..close();
          canvas.drawPath(leftFacet, darkRayPaint);

          // Right facet (lighter side)
          final Path rightFacet = Path()
            ..moveTo(innerTip.dx, innerTip.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(rightVal.dx, rightVal.dy)
            ..close();
          canvas.drawPath(rightFacet, lightRayPaint);

          // Outline and spine crease
          canvas.drawLine(innerTip, tip, starStroke);
          canvas.drawLine(leftVal, tip, starStroke);
          canvas.drawLine(rightVal, tip, starStroke);
        }

        // Inner thin rosewood accent ring encircling open natural birch wood center
        canvas.drawCircle(Offset.zero, rInner, starStroke);
        canvas.drawCircle(
          Offset.zero,
          rInner - 2.5,
          Paint()
            ..color = const Color(0xFFC0392B).withOpacity(0.4)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke,
        );
        break;

      case BoardThemeType.emerald:
        // 2. Heritage Club Teal — 3-Lobe Club & Flanking Laurel Wreath
        final Paint clubPaint = Paint()
          ..color = const Color(0xFF0F5448)
          ..style = PaintingStyle.fill;
        final Paint clubStroke = Paint()
          ..color = const Color(0xFF083830)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        // Laurel wreath flanking the club
        final Paint leafPaint = Paint()
          ..color = const Color(0xFF136E60)
          ..style = PaintingStyle.fill;
        final Paint wreathBranchPaint = Paint()
          ..color = const Color(0xFF0C4D42)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;

        final Path branchL = Path()
          ..moveTo(0, 36)
          ..cubicTo(-42, 30, -48, -10, -20, -36);
        final Path branchR = Path()
          ..moveTo(0, 36)
          ..cubicTo(42, 30, 48, -10, 20, -36);
        canvas.drawPath(branchL, wreathBranchPaint);
        canvas.drawPath(branchR, wreathBranchPaint);

        // Laurel leaves along the branches
        for (int i = 1; i <= 6; i++) {
          final double t = i / 7.0;
          final double angL = math.pi * 0.5 + t * math.pi * 0.82;
          final double angR = math.pi * 0.5 - t * math.pi * 0.82;
          const double rDist = 38.0;
          final Offset pL = Offset(math.cos(angL) * rDist, -math.sin(angL) * rDist);
          final Offset pR = Offset(math.cos(angR) * rDist, -math.sin(angR) * rDist);

          canvas.save();
          canvas.translate(pL.dx, pL.dy);
          canvas.rotate(-angL + math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.5, height: 4.2), leafPaint);
          canvas.restore();

          canvas.save();
          canvas.translate(pR.dx, pR.dy);
          canvas.rotate(-angR + math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.5, height: 4.2), leafPaint);
          canvas.restore();
        }

        // Center Club (♣) silhouette: 3 circular lobes and flaring stem
        // Top lobe
        canvas.drawCircle(const Offset(0, -18), 11.5, clubPaint);
        canvas.drawCircle(const Offset(0, -18), 11.5, clubStroke);
        // Left lobe
        canvas.drawCircle(const Offset(-11.5, -3), 11.5, clubPaint);
        canvas.drawCircle(const Offset(-11.5, -3), 11.5, clubStroke);
        // Right lobe
        canvas.drawCircle(const Offset(11.5, -3), 11.5, clubPaint);
        canvas.drawCircle(const Offset(11.5, -3), 11.5, clubStroke);

        // Club central join filling
        canvas.drawRect(Rect.fromCenter(center: const Offset(0, -6), width: 14, height: 14), clubPaint);

        // Club flaring stem
        final Path stem = Path()
          ..moveTo(-3.5, -4)
          ..quadraticBezierTo(-4, 10, -9, 18)
          ..quadraticBezierTo(0, 19.5, 9, 18)
          ..quadraticBezierTo(4, 10, 3.5, -4)
          ..close();
        canvas.drawPath(stem, clubPaint);
        canvas.drawPath(stem, clubStroke);

        // Highlight sheen on lobes
        final Paint clubSheen = Paint()..color = const Color(0xFF26A69A).withOpacity(0.4);
        canvas.drawCircle(const Offset(-2, -21), 4.0, clubSheen);
        canvas.drawCircle(const Offset(-13, -6), 4.0, clubSheen);
        canvas.drawCircle(const Offset(10, -6), 4.0, clubSheen);
        break;

      case BoardThemeType.midnight:
        // 3. Royal Navy Lounge — Regal 5-Point Royal Crown
        final Paint goldCrownPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDE047), Color(0xFFD4AF37), Color(0xFF9A7B20)],
          ).createShader(const Rect.fromLTWH(-36, -36, 72, 60))
          ..style = PaintingStyle.fill;

        final Paint crownOutline = Paint()
          ..color = const Color(0xFF785E10)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;

        // Arched crown base band
        final Path crownBand = Path()
          ..moveTo(-30, 16)
          ..quadraticBezierTo(0, 20, 30, 16)
          ..lineTo(30, 24)
          ..quadraticBezierTo(0, 28, -30, 24)
          ..close();
        canvas.drawPath(crownBand, goldCrownPaint);
        canvas.drawPath(crownBand, crownOutline);

        // 5 circular jewel insets on band
        final Paint jewelPaint = Paint()..color = const Color(0xFF14243B);
        for (double jx = -20; jx <= 20; jx += 10) {
          final double jy = 20.0 + (1.0 - (jx.abs() / 20.0)) * 2.0;
          canvas.drawCircle(Offset(jx, jy), 2.2, jewelPaint);
          canvas.drawCircle(Offset(jx, jy), 2.2, crownOutline);
        }

        // Crown body with 5 peaks and scalloped arches
        final Path crownBody = Path()
          ..moveTo(-28, 16)
          ..lineTo(-28, -6) // Outer left peak
          ..quadraticBezierTo(-22, 6, -16, -18) // Mid-left peak
          ..quadraticBezierTo(-8, 4, 0, -32) // Tall center peak
          ..quadraticBezierTo(8, 4, 16, -18) // Mid-right peak
          ..quadraticBezierTo(22, 6, 28, -6) // Outer right peak
          ..lineTo(28, 16)
          ..quadraticBezierTo(0, 20, -28, 16)
          ..close();
        canvas.drawPath(crownBody, goldCrownPaint);
        canvas.drawPath(crownBody, crownOutline);

        // Velvet dome cap beneath peaks
        final Paint velvetCap = Paint()
          ..color = const Color(0xFF1B3150).withOpacity(0.65)
          ..style = PaintingStyle.fill;
        final Path capPath = Path()
          ..moveTo(-26, 15)
          ..quadraticBezierTo(-16, -4, 0, -12)
          ..quadraticBezierTo(16, -4, 26, 15)
          ..quadraticBezierTo(0, 19, -26, 15)
          ..close();
        canvas.drawPath(capPath, velvetCap);

        // Pearl finials on the 5 peaks
        final Paint pearlPaint = Paint()..color = const Color(0xFFFFFBEB);
        canvas.drawCircle(const Offset(-28, -6), 2.8, pearlPaint);
        canvas.drawCircle(const Offset(-28, -6), 2.8, crownOutline);
        canvas.drawCircle(const Offset(-16, -18), 3.0, pearlPaint);
        canvas.drawCircle(const Offset(-16, -18), 3.0, crownOutline);
        // Center peak imperial fleur finial
        canvas.drawCircle(const Offset(0, -32), 4.2, pearlPaint);
        canvas.drawCircle(const Offset(0, -32), 4.2, crownOutline);
        canvas.drawCircle(const Offset(16, -18), 3.0, pearlPaint);
        canvas.drawCircle(const Offset(16, -18), 3.0, crownOutline);
        canvas.drawCircle(const Offset(28, -6), 2.8, pearlPaint);
        canvas.drawCircle(const Offset(28, -6), 2.8, crownOutline);
        break;

      case BoardThemeType.walnutClub:
        // 4. Walnut Club — Magnificent Golden Tree of Life
        final Paint woodPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE5C058), Color(0xFFC5993B), Color(0xFF8C581E)],
          ).createShader(const Rect.fromLTWH(-40, -42, 80, 84))
          ..style = PaintingStyle.fill;

        final Paint treeOutline = Paint()
          ..color = const Color(0xFF5A3008)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        // 1. Rooted base and trunk
        final Path trunk = Path()
          ..moveTo(-18, 38) // Left outer root
          ..quadraticBezierTo(-10, 32, -4, 18)
          ..lineTo(-2.5, 6)
          ..lineTo(2.5, 6)
          ..lineTo(4, 18)
          ..quadraticBezierTo(10, 32, 18, 38) // Right outer root
          ..quadraticBezierTo(10, 35, 6, 26)
          ..quadraticBezierTo(2, 36, 0, 38) // Center tap root
          ..quadraticBezierTo(-2, 36, -6, 26)
          ..quadraticBezierTo(-10, 35, -18, 38)
          ..close();
        canvas.drawPath(trunk, woodPaint);
        canvas.drawPath(trunk, treeOutline);

        // 2. Graceful branching limbs
        final Paint branchPaint = Paint()
          ..color = const Color(0xFFC5993B)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final List<Path> branchPaths = [
          // Central ascending limb
          Path()..moveTo(0, 6)..lineTo(0, -22),
          // Lower lateral boughs
          Path()..moveTo(-2.5, 10)..quadraticBezierTo(-16, 8, -26, 4),
          Path()..moveTo(2.5, 10)..quadraticBezierTo(16, 8, 26, 4),
          // Mid boughs
          Path()..moveTo(-2, 4)..quadraticBezierTo(-18, -4, -30, -14),
          Path()..moveTo(2, 4)..quadraticBezierTo(18, -4, 30, -14),
          // Upper canopy boughs
          Path()..moveTo(-1, -6)..quadraticBezierTo(-14, -18, -22, -28),
          Path()..moveTo(1, -6)..quadraticBezierTo(14, -18, 22, -28),
          Path()..moveTo(-1, -12)..quadraticBezierTo(-8, -26, -10, -36),
          Path()..moveTo(1, -12)..quadraticBezierTo(8, -26, 10, -36),
        ];
        for (final bp in branchPaths) {
          canvas.drawPath(bp, branchPaint);
        }

        // 3. Dense, lush foliage: 30+ golden leaves clustered to form a rich circular canopy
        final Paint leafGold = Paint()
          ..color = const Color(0xFFDEAF55)
          ..style = PaintingStyle.fill;
        final Paint leafAccent = Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.fill;

        final List<List<double>> leafCoords = [
          // [x, y, angleDeg, scale]
          // Top center cluster
          [0, -38, 0, 1.1],
          [-7, -35, -20, 1.0],
          [7, -35, 20, 1.0],
          [-14, -34, -35, 1.0],
          [14, -34, 35, 1.0],
          // Upper canopy left & right
          [-22, -28, -50, 1.05],
          [22, -28, 50, 1.05],
          [-28, -22, -60, 1.0],
          [28, -22, 60, 1.0],
          [-32, -14, -75, 1.0],
          [32, -14, 75, 1.0],
          // Mid canopy
          [-34, -6, -85, 1.0],
          [34, -6, 85, 1.0],
          [-30, 2, -95, 0.95],
          [30, 2, 95, 0.95],
          [-24, 8, -105, 0.9],
          [24, 8, 105, 0.9],
          // Inner canopy cluster
          [-8, -24, -15, 0.9],
          [8, -24, 15, 0.9],
          [-16, -16, -40, 0.9],
          [16, -16, 40, 0.9],
          [-22, -8, -60, 0.9],
          [22, -8, 60, 0.9],
          [-14, -6, -30, 0.85],
          [14, -6, 30, 0.85],
          [0, -22, 0, 0.9],
          [0, -12, 0, 0.85],
          [-8, -2, -20, 0.85],
          [8, -2, 20, 0.85],
          [-18, 2, -45, 0.8],
          [18, 2, 45, 0.8],
        ];

        for (final lc in leafCoords) {
          final double lx = lc[0];
          final double ly = lc[1];
          final double rot = lc[2] * math.pi / 180.0;
          final double sc = lc[3];

          canvas.save();
          canvas.translate(lx, ly);
          canvas.rotate(rot);
          canvas.scale(sc, sc);

          // Pointed almond leaf
          final Path leaf = Path()
            ..moveTo(0, -6)
            ..quadraticBezierTo(3.2, 0, 0, 6)
            ..quadraticBezierTo(-3.2, 0, 0, -6)
            ..close();
          canvas.drawPath(leaf, leafGold);
          canvas.drawPath(leaf, treeOutline);
          // Highlight spine
          canvas.drawLine(const Offset(0, -5), const Offset(0, 5), leafAccent);

          canvas.restore();
        }
        break;

      case BoardThemeType.royalIndigo:
        // 5. Royal Indigo — Sacred Blooming Platinum Lotus
        final Paint platinumPetal = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          ).createShader(const Rect.fromLTWH(-40, -40, 80, 80))
          ..style = PaintingStyle.fill;

        final Paint indigoShade = Paint()
          ..color = const Color(0xFF4F46E5).withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        final Paint lotusOutline = Paint()
          ..color = const Color(0xFF24225C)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        // Layered lotus petals
        final List<List<Offset>> petalContours = [
          // Center upright petal
          [const Offset(0, 16), const Offset(-10, -4), const Offset(-8, -26), const Offset(0, -38)],
          // Inner left
          [const Offset(-4, 16), const Offset(-18, 2), const Offset(-24, -18), const Offset(-16, -32)],
          // Inner right
          [const Offset(4, 16), const Offset(18, 2), const Offset(24, -18), const Offset(16, -32)],
          // Mid left
          [const Offset(-8, 18), const Offset(-28, 6), const Offset(-36, -8), const Offset(-28, -22)],
          // Mid right
          [const Offset(8, 18), const Offset(28, 6), const Offset(36, -8), const Offset(28, -22)],
          // Outer left
          [const Offset(-12, 20), const Offset(-34, 16), const Offset(-42, 2), const Offset(-36, -10)],
          // Outer right
          [const Offset(12, 20), const Offset(34, 16), const Offset(42, 2), const Offset(36, -10)],
        ];

        for (int i = petalContours.length - 1; i >= 0; i--) {
          final pts = petalContours[i];
          final Path p = Path()
            ..moveTo(pts[0].dx, pts[0].dy)
            ..cubicTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy, pts[3].dx, pts[3].dy)
            ..cubicTo(-pts[2].dx * 0.4, pts[2].dy, -pts[1].dx * 0.4, pts[1].dy, pts[0].dx, pts[0].dy)
            ..close();
          canvas.drawPath(p, platinumPetal);
          canvas.drawPath(p, lotusOutline);
          canvas.drawLine(pts[0], pts[3], indigoShade);
        }

        // Bottom curved calyx base
        final Path calyx = Path()
          ..moveTo(-26, 22)
          ..quadraticBezierTo(0, 32, 26, 22)
          ..quadraticBezierTo(0, 36, -26, 22)
          ..close();
        canvas.drawPath(calyx, Paint()..color = const Color(0xFF6366F1));
        canvas.drawPath(calyx, lotusOutline);
        break;

      case BoardThemeType.emeraldLounge:
        // 6. Emerald Lounge — French Royal Fleur-de-Lis
        final Paint goldFleurPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE047), Color(0xFFD4AF37), Color(0xFF9A7B20)],
          ).createShader(const Rect.fromLTWH(-36, -42, 72, 84))
          ..style = PaintingStyle.fill;

        final Paint fleurOutline = Paint()
          ..color = const Color(0xFF6B4B0C)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;

        // 1. Center spear blade
        final Path centerSpear = Path()
          ..moveTo(0, 4)
          ..cubicTo(-14, -6, -14, -28, 0, -42)
          ..cubicTo(14, -28, 14, -6, 0, 4)
          ..close();
        canvas.drawPath(centerSpear, goldFleurPaint);
        canvas.drawPath(centerSpear, fleurOutline);
        canvas.drawLine(const Offset(0, 4), const Offset(0, -42), fleurOutline);

        // 2. Left curling petal
        final Path leftPetal = Path()
          ..moveTo(-3, 4)
          ..cubicTo(-24, 2, -38, -10, -36, -26)
          ..cubicTo(-34, -36, -24, -30, -22, -22)
          ..cubicTo(-20, -8, -10, 0, -3, 4)
          ..close();
        canvas.drawPath(leftPetal, goldFleurPaint);
        canvas.drawPath(leftPetal, fleurOutline);

        // 3. Right curling petal
        final Path rightPetal = Path()
          ..moveTo(3, 4)
          ..cubicTo(24, 2, 38, -10, 36, -26)
          ..cubicTo(34, -36, 24, -30, 22, -22)
          ..cubicTo(20, -8, 10, 0, 3, 4)
          ..close();
        canvas.drawPath(rightPetal, goldFleurPaint);
        canvas.drawPath(rightPetal, fleurOutline);

        // 4. Horizontal binding ribbon / clasp
        final RRect clasp = RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 6), width: 32, height: 7),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(clasp, goldFleurPaint);
        canvas.drawRRect(clasp, fleurOutline);
        canvas.drawLine(const Offset(-16, 6), const Offset(16, 6), Paint()..color = const Color(0xFFFDE047));

        // 5. Flared tripartite bottom root
        final Path bottomRoot = Path()
          ..moveTo(-10, 9)
          ..quadraticBezierTo(-22, 26, -16, 34)
          ..quadraticBezierTo(-6, 26, 0, 20)
          ..quadraticBezierTo(6, 26, 16, 34)
          ..quadraticBezierTo(22, 26, 10, 9)
          ..close();
        canvas.drawPath(bottomRoot, goldFleurPaint);
        canvas.drawPath(bottomRoot, fleurOutline);
        break;

      case BoardThemeType.oceanBreeze:
        // 7. Ocean Breeze — Cresting Rolling Ocean Wave
        final Paint aquaWave = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF38BDF8)],
          ).createShader(const Rect.fromLTWH(-42, -40, 84, 80))
          ..style = PaintingStyle.fill;

        final Paint waveOutline = Paint()
          ..color = const Color(0xFF0C4A6E)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;

        // Main sweeping barrel wave
        final Path barrel = Path()
          ..moveTo(-38, 26)
          ..cubicTo(-26, 26, -20, -6, -8, -36)
          ..cubicTo(8, -36, 22, -28, 24, -16)
          ..cubicTo(26, -6, 14, 2, 4, -4)
          ..cubicTo(-4, -10, -2, -20, 6, -20)
          ..cubicTo(-6, -16, -10, 4, -18, 14)
          ..quadraticBezierTo(-28, 26, -38, 26)
          ..close();
        canvas.drawPath(barrel, aquaWave);
        canvas.drawPath(barrel, waveOutline);

        // White sculpted foam crest along top curve
        final Paint foamPaint = Paint()..color = const Color(0xFFF0FDF4)..style = PaintingStyle.fill;
        final Path foam = Path()
          ..moveTo(-16, -30)
          ..cubicTo(-6, -38, 10, -36, 24, -16)
          ..cubicTo(20, -20, 8, -26, -2, -24)
          ..cubicTo(2, -22, 6, -20, 4, -16)
          ..cubicTo(12, -20, 20, -18, 14, -28)
          ..close();
        canvas.drawPath(foam, foamPaint);
        canvas.drawPath(foam, waveOutline);

        // Lower swell ripples
        final Path ripple1 = Path()
          ..moveTo(-34, 32)
          ..quadraticBezierTo(-16, 24, 4, 30)
          ..quadraticBezierTo(20, 24, 36, 32);
        final Path ripple2 = Path()
          ..moveTo(-26, 38)
          ..quadraticBezierTo(-8, 32, 12, 38);
        final Paint ripplePaint = Paint()
          ..color = const Color(0xFF0284C7)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawPath(ripple1, ripplePaint);
        canvas.drawPath(ripple2, ripplePaint);

        // Spray droplets
        canvas.drawCircle(const Offset(28, -26), 2.2, foamPaint);
        canvas.drawCircle(const Offset(34, -18), 1.8, foamPaint);
        canvas.drawCircle(const Offset(30, -8), 2.0, foamPaint);
        break;

      case BoardThemeType.sakuraStudio:
        // 8. Sakura Studio — 5-Petal Cherry Blossom (Sakura)
        final Paint petalPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F2), Color(0xFFFDA4AF), Color(0xFFFB7185)],
          ).createShader(const Rect.fromLTWH(-40, -40, 80, 80))
          ..style = PaintingStyle.fill;

        final Paint petalStroke = Paint()
          ..color = const Color(0xFFBE185D)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;

        const int numPetals = 5;
        const double rOuter = 38.0;

        for (int i = 0; i < numPetals; i++) {
          final double ang = i * 2 * math.pi / numPetals - math.pi / 2;
          final double halfStep = 0.5 * 2 * math.pi / numPetals;

          final Offset tipCenter = Offset(math.cos(ang) * (rOuter - 3), math.sin(ang) * (rOuter - 3));
          final Offset tipL = Offset(math.cos(ang - halfStep * 0.4) * rOuter, math.sin(ang - halfStep * 0.4) * rOuter);
          final Offset tipR = Offset(math.cos(ang + halfStep * 0.4) * rOuter, math.sin(ang + halfStep * 0.4) * rOuter);
          final Offset baseL = Offset(math.cos(ang - halfStep * 0.85) * 8, math.sin(ang - halfStep * 0.85) * 8);
          final Offset baseR = Offset(math.cos(ang + halfStep * 0.85) * 8, math.sin(ang + halfStep * 0.85) * 8);

          // Authentic petal with characteristic notched cleft tip
          final Path petal = Path()
            ..moveTo(0, 0)
            ..lineTo(baseL.dx, baseL.dy)
            ..quadraticBezierTo(
              math.cos(ang - halfStep * 0.7) * (rOuter * 0.75),
              math.sin(ang - halfStep * 0.7) * (rOuter * 0.75),
              tipL.dx,
              tipL.dy,
            )
            ..lineTo(tipCenter.dx, tipCenter.dy) // Center notch
            ..lineTo(tipR.dx, tipR.dy)
            ..quadraticBezierTo(
              math.cos(ang + halfStep * 0.7) * (rOuter * 0.75),
              math.sin(ang + halfStep * 0.7) * (rOuter * 0.75),
              baseR.dx,
              baseR.dy,
            )
            ..close();

          canvas.drawPath(petal, petalPaint);
          canvas.drawPath(petal, petalStroke);
        }

        // Central gold pistil and radiating stamens
        final Paint stamenStroke = Paint()
          ..color = const Color(0xFFD4AF37)
          ..strokeWidth = 1.0;
        final Paint antherPaint = Paint()..color = const Color(0xFFD4AF37);

        for (int j = 0; j < 10; j++) {
          final double a = j * 2 * math.pi / 10;
          final Offset sTip = Offset(math.cos(a) * 16, math.sin(a) * 16);
          canvas.drawLine(Offset.zero, sTip, stamenStroke);
          canvas.drawCircle(sTip, 1.5, antherPaint);
        }
        canvas.drawCircle(Offset.zero, 3.5, Paint()..color = const Color(0xFFFB7185));
        break;

      case BoardThemeType.neonArena:
        // 9. Neon Arena — Concentric Electric Cyan Delta Triangles
        final Paint neonGlow = Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.4)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

        final Paint neonCore = Paint()
          ..color = const Color(0xFFE0FFFF)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final Paint innerGlow = Paint()
          ..color = const Color(0xFF00B4D8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        // Outer inverted delta triangle
        final Path outerTri = Path()
          ..moveTo(-36, -20)
          ..lineTo(36, -20)
          ..lineTo(0, 40)
          ..close();
        canvas.drawPath(outerTri, neonGlow);
        canvas.drawPath(outerTri, neonCore);

        // Inner inverted delta triangle
        final Path innerTri = Path()
          ..moveTo(-22, -12)
          ..lineTo(22, -12)
          ..lineTo(0, 24)
          ..close();
        canvas.drawPath(innerTri, innerGlow);

        // Corner vertex nodes
        final Paint nodePaint = Paint()..color = const Color(0xFFE0FFFF);
        canvas.drawCircle(const Offset(-36, -20), 2.8, nodePaint);
        canvas.drawCircle(const Offset(36, -20), 2.8, nodePaint);
        canvas.drawCircle(const Offset(0, 40), 2.8, nodePaint);

        // Precision tech alignment ticks
        canvas.drawLine(const Offset(-36, -20), const Offset(-22, -12), innerGlow);
        canvas.drawLine(const Offset(36, -20), const Offset(22, -12), innerGlow);
        canvas.drawLine(const Offset(0, 40), const Offset(0, 24), innerGlow);
        break;

      case BoardThemeType.goldenPalace:
        // 10. Golden Palace — Imperial Crown encircled by Laurel Wreath
        final Paint goldPalacePaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF08A), Color(0xFFD4AF37), Color(0xFFB45309)],
          ).createShader(const Rect.fromLTWH(-44, -44, 88, 88))
          ..style = PaintingStyle.fill;

        final Paint goldPalaceOutline = Paint()
          ..color = const Color(0xFF78350F)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;

        // Circular Laurel Wreath (R ~ 40)
        final Path wreathL = Path()
          ..moveTo(0, 40)
          ..cubicTo(-50, 32, -50, -26, 0, -40);
        final Path wreathR = Path()
          ..moveTo(0, 40)
          ..cubicTo(50, 32, 50, -26, 0, -40);
        final Paint branchStroke = Paint()
          ..color = const Color(0xFFB4831B)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        canvas.drawPath(wreathL, branchStroke);
        canvas.drawPath(wreathR, branchStroke);

        // 14 pairs of golden leaves
        for (int i = 1; i <= 6; i++) {
          final double t = i / 7.0;
          final double aL = math.pi * 0.5 + t * math.pi * 0.88;
          final double aR = math.pi * 0.5 - t * math.pi * 0.88;
          const double rW = 40.0;
          final Offset pL = Offset(math.cos(aL) * rW, -math.sin(aL) * rW);
          final Offset pR = Offset(math.cos(aR) * rW, -math.sin(aR) * rW);

          canvas.save();
          canvas.translate(pL.dx, pL.dy);
          canvas.rotate(-aL + math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.0, height: 4.0), goldPalacePaint);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.0, height: 4.0), goldPalaceOutline);
          canvas.restore();

          canvas.save();
          canvas.translate(pR.dx, pR.dy);
          canvas.rotate(-aR + math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.0, height: 4.0), goldPalacePaint);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 8.0, height: 4.0), goldPalaceOutline);
          canvas.restore();
        }

        // Inner Imperial Crown
        final Path impBand = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, 16), width: 34, height: 6),
            const Radius.circular(2.0),
          ));
        canvas.drawPath(impBand, goldPalacePaint);
        canvas.drawPath(impBand, goldPalaceOutline);

        final Path impPeaks = Path()
          ..moveTo(-16, 13)
          ..lineTo(-16, -2) // Left peak
          ..quadraticBezierTo(-10, 4, -8, -10)
          ..quadraticBezierTo(-4, 0, 0, -22) // Central imperial cross
          ..quadraticBezierTo(4, 0, 8, -10)
          ..quadraticBezierTo(10, 4, 16, -2) // Right peak
          ..lineTo(16, 13)
          ..close();
        canvas.drawPath(impPeaks, goldPalacePaint);
        canvas.drawPath(impPeaks, goldPalaceOutline);

        // Pearl and cross finials
        canvas.drawCircle(const Offset(-16, -2), 2.2, goldPalacePaint);
        canvas.drawCircle(const Offset(-16, -2), 2.2, goldPalaceOutline);
        canvas.drawCircle(const Offset(0, -22), 3.4, goldPalacePaint);
        canvas.drawCircle(const Offset(0, -22), 3.4, goldPalaceOutline);
        canvas.drawCircle(const Offset(16, -2), 2.2, goldPalacePaint);
        canvas.drawCircle(const Offset(16, -2), 2.2, goldPalaceOutline);
        break;

      case BoardThemeType.cosmicElite:
        // 11. Cosmic Elite — 8-Point Pulsar Star & Tilted Orbital Ring
        final Paint goldPulsarPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFB45309)],
          ).createShader(const Rect.fromLTWH(-48, -48, 96, 96))
          ..style = PaintingStyle.fill;

        final Paint darkRayPaint = Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.fill;
        final Paint lightRayPaint = Paint()
          ..color = const Color(0xFFFDE68A)
          ..style = PaintingStyle.fill;

        final Paint cosmicOutline = Paint()
          ..color = const Color(0xFF78350F)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;

        // 1. Tilted Elliptical Orbital Ring (behind star)
        canvas.save();
        canvas.rotate(-math.pi * 0.14);
        final Paint orbitPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 92, height: 28), orbitPaint);

        // Planetoid satellite bead on orbit
        canvas.drawCircle(const Offset(46, 0), 3.4, goldPulsarPaint);
        canvas.drawCircle(const Offset(46, 0), 3.4, cosmicOutline);
        canvas.drawCircle(const Offset(46, 0), 1.2, Paint()..color = Colors.white);
        canvas.restore();

        // 2. 8-Pointed Celestial Pulsar Star
        const double rMajor = 44.0;
        const double rMinor = 22.0;
        const double rVal = 9.0;

        for (int i = 0; i < 8; i++) {
          final double ang = i * math.pi / 4.0;
          final double angLeft = (i - 0.5) * math.pi / 4.0;
          final double angRight = (i + 0.5) * math.pi / 4.0;
          final double rTip = (i % 2 == 0) ? rMajor : rMinor;

          final Offset tip = Offset(math.cos(ang) * rTip, math.sin(ang) * rTip);
          final Offset leftV = Offset(math.cos(angLeft) * rVal, math.sin(angLeft) * rVal);
          final Offset rightV = Offset(math.cos(angRight) * rVal, math.sin(angRight) * rVal);

          // Left facet (darker)
          final Path leftF = Path()
            ..moveTo(0, 0)
            ..lineTo(leftV.dx, leftV.dy)
            ..lineTo(tip.dx, tip.dy)
            ..close();
          canvas.drawPath(leftF, darkRayPaint);

          // Right facet (lighter)
          final Path rightF = Path()
            ..moveTo(0, 0)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(rightV.dx, rightV.dy)
            ..close();
          canvas.drawPath(rightF, lightRayPaint);

          canvas.drawLine(Offset.zero, tip, cosmicOutline);
          canvas.drawLine(leftV, tip, cosmicOutline);
          canvas.drawLine(rightV, tip, cosmicOutline);
        }
        // Center spark diamond
        canvas.drawCircle(Offset.zero, 3.5, Paint()..color = const Color(0xFFFFFBEB));
        break;
    }
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
          ..color = _primaryLineColor.withOpacity(0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        pos,
        3.2,
        Paint()..color = _secondaryLineColor,
      );
    }
  }

  /// Decorative side midpoint ornaments along the outer frame edges matching reference art
  void _drawFrameSideOrnaments(Canvas canvas) {
    const double totalHalf = GameConfig.boardSize / 2.0 + GameConfig.frameWidth / 2.0;
    final List<Offset> sideCenters = [
      Offset(0.0, -totalHalf),
      Offset(0.0, totalHalf),
      Offset(-totalHalf, 0.0),
      Offset(totalHalf, 0.0),
    ];

    final Color decorCol = _cushionTrimColor;
    final Paint decorPaint = Paint()
      ..color = decorCol
      ..style = PaintingStyle.fill;
    final Paint decorStroke = Paint()
      ..color = _cushionTrimColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final pos = sideCenters[i];
      final bool isHorizontal = (i < 2);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      if (!isHorizontal) {
        canvas.rotate(math.pi / 2);
      }

      // Elegant diamond tab ornament
      final Path diamond = Path()
        ..moveTo(-12, 0)
        ..lineTo(0, -5)
        ..lineTo(12, 0)
        ..lineTo(0, 5)
        ..close();
      canvas.drawPath(diamond, decorStroke);
      canvas.drawCircle(Offset.zero, 2.0, decorPaint);

      canvas.restore();
    }
  }

  void _drawPockets(Canvas canvas) {
    for (final pocket in GameConfig.pockets) {
      final Offset p = Offset(pocket.x, pocket.y);

      // 1. Outer Metallic Theme Collar
      canvas.drawCircle(
        p,
        GameConfig.pocketRadius + 6.5,
        Paint()..color = _cushionTrimColor.withOpacity(0.78),
      );

      // 2. Dark Hardwood Bezel
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

      // 4. Woven Netting Inside Pocket
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
          ..color = _cushionTrimColor.withOpacity(0.40)
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

    final Color plateCol = _cushionTrimColor;
    final Paint plateStroke = Paint()
      ..color = plateCol.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint rivetPaint = Paint()..color = plateCol;

    for (final corner in corners) {
      canvas.save();
      final Offset pos = corner['pos'] as Offset;
      final double rot = corner['angle'] as double;
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      // Clean geometric metallic L-joint bracket with rivets
      final Path bracket = Path()
        ..moveTo(0, 26)
        ..lineTo(0, 4)
        ..quadraticBezierTo(0, 0, 4, 0)
        ..lineTo(26, 0);
      canvas.drawPath(bracket, plateStroke);

      canvas.drawCircle(const Offset(5, 5), 2.2, rivetPaint);
      canvas.drawCircle(const Offset(20, 3), 1.5, rivetPaint);
      canvas.drawCircle(const Offset(3, 20), 1.5, rivetPaint);

      // Theme-specific corner flourishes
      if (theme == BoardThemeType.midnight ||
          theme == BoardThemeType.emeraldLounge ||
          theme == BoardThemeType.goldenPalace) {
        // Filigree flourish
        final Path filigree = Path()
          ..moveTo(6, 6)
          ..quadraticBezierTo(14, 14, 20, 20);
        canvas.drawPath(filigree, plateStroke);
      } else if (theme == BoardThemeType.sakuraStudio) {
        // Cherry blossom petal in corner
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(12, 12), width: 6, height: 3),
          rivetPaint,
        );
      } else if (theme == BoardThemeType.cosmicElite) {
        // Starburst point in corner
        canvas.drawLine(const Offset(8, 8), const Offset(16, 16), plateStroke);
      } else if (theme == BoardThemeType.neonArena) {
        // High-tech angular notch
        final Path notch = Path()
          ..moveTo(6, 18)
          ..lineTo(18, 18)
          ..lineTo(18, 6);
        canvas.drawPath(notch, plateStroke);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
