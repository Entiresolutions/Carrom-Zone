import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/game_config.dart';
import '../core/theme_piece_style.dart';
import '../core/vector2.dart';
import '../models/piece_model.dart';

/// Renders carrom pieces, queen, and striker with dedicated, theme-adaptive
/// materials, lathe grooves, metallic bezels, specular highlights, and animations.
class PiecePainter extends CustomPainter {
  final BoardThemeType theme;
  final List<PieceModel> pieces;
  final PieceModel striker;
  final double strikerGlowPhase; // 0.0 to 1.0 for subtle breathing glow / idle gleam
  final bool isAiming;
  final double aimPower; // 0.0 to 1.0
  final double aimAngle; // Radians
  final List<Vector2> strikerTrail; // Historical positions for motion trails

  PiecePainter({
    this.theme = BoardThemeType.mahogany,
    required this.pieces,
    required this.striker,
    this.strikerGlowPhase = 0.0,
    this.isAiming = false,
    this.aimPower = 0.0,
    this.aimAngle = 0.0,
    this.strikerTrail = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale =
        size.width / (GameConfig.boardSize + GameConfig.frameWidth * 2);
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    final ThemePieceStyle style = ThemePieceStyle.of(theme);

    // 0. Draw striker motion trail (behind moving pieces)
    if (strikerTrail.isNotEmpty && (!striker.isPocketed || striker.pocketProgress < 1.0)) {
      _drawStrikerMotionTrail(canvas, strikerTrail, striker.radius, style);
    }

    // 1. Draw carrom pieces
    for (final p in pieces) {
      if (p.isPocketed && p.pocketProgress >= 1.0) continue;
      _drawPiece(canvas, p, style);
    }

    // 2. Draw striker
    if (!striker.isPocketed || striker.pocketProgress < 1.0) {
      _drawStriker(canvas, striker, style);
    }

    canvas.restore();
  }

  void _drawStrikerMotionTrail(
    Canvas canvas,
    List<Vector2> trail,
    double radius,
    ThemePieceStyle style,
  ) {
    if (trail.length < 2) return;
    for (int i = 0; i < trail.length - 1; i++) {
      final double progress = (i + 1) / trail.length; // 0.0 at oldest, 1.0 at newest
      final Vector2 p1 = trail[i];
      final Vector2 p2 = trail[i + 1];
      final double alpha = (progress * 0.45).clamp(0.0, 1.0);
      final double width = radius * (0.35 + progress * 0.55);

      canvas.drawLine(
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
        Paint()
          ..color = style.trailColor.withOpacity(alpha)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
    }
  }

  void _drawPiece(Canvas canvas, PieceModel piece, ThemePieceStyle style) {
    final double shrink = (1.0 - piece.pocketProgress).clamp(0.0, 1.0);
    if (shrink <= 0.001) return;

    final Offset pos = Offset(piece.position.x, piece.position.y);
    final double r = piece.radius * shrink;

    // Dual-layer tabletop contact shadow for enhanced piece separation & depth
    // 1. Ambient contact shadow (tight and grounding)
    canvas.drawCircle(
      Offset(pos.dx + 1.2 * shrink, pos.dy + 1.6 * shrink),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.52 * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    // 2. Soft tabletop elevation shadow
    canvas.drawCircle(
      Offset(pos.dx + 2.4 * shrink, pos.dy + 3.2 * shrink),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.30 * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8),
    );

    switch (piece.type) {
      case PieceType.queen:
        _drawQueenPiece(canvas, pos, r, shrink, style);
        break;
      case PieceType.white:
        _drawWhitePiece(canvas, pos, r, shrink, style);
        break;
      case PieceType.black:
        _drawBlackPiece(canvas, pos, r, shrink, style);
        break;
      default:
        break;
    }
  }

  void _drawWhitePiece(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    // Subtle dark under-boundary to prevent blending into white board circles/markings
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * shrink,
    );

    // Theme-specific White Piece Body
    final Paint bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.32),
        radius: 0.9,
        colors: style.whiteGradient,
        stops: const [0.0, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, bodyPaint);

    // Defined dark outer contour rim for crisp board & marking contrast
    canvas.drawCircle(
      pos,
      r - 0.5 * shrink,
      Paint()
        ..color = style.whiteRim.withOpacity(0.92 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * shrink,
    );

    // Inner bevel ring for tactile coin depth
    canvas.drawCircle(
      pos,
      r * 0.86,
      Paint()
        ..color = style.whiteGroove.withOpacity(0.40 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * shrink,
    );

    // Concentric lathe grooves
    final Paint groovePaint = Paint()
      ..color = style.whiteGroove.withOpacity(0.85 * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * shrink;
    canvas.drawCircle(pos, r * 0.62, groovePaint);

    groovePaint.strokeWidth = 0.8 * shrink;
    canvas.drawCircle(pos, r * 0.35, groovePaint);

    // Center lathe dimple
    canvas.drawCircle(
      pos,
      r * 0.15,
      Paint()..color = style.whiteCenter.withOpacity(0.95 * shrink),
    );

    // Specular highlight sheen
    canvas.drawCircle(
      Offset(pos.dx - r * 0.32, pos.dy - r * 0.32),
      r * 0.18,
      Paint()..color = style.whiteHighlight.withOpacity(
          (style.whiteHighlight.opacity * shrink).clamp(0.0, 1.0)),
    );
  }

  void _drawBlackPiece(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    // 1. Dark substrate disk for crisp edge definition
    canvas.drawCircle(
      pos,
      r,
      Paint()..color = const Color(0xFF0D0C10),
    );

    // 2. Theme-specific Charcoal/Graphite Body
    final Paint bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.32),
        radius: 0.9,
        colors: style.blackGradient,
        stops: const [0.0, 0.48, 0.82, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, bodyPaint);

    // 3. High-Contrast Outer Edge Rim (Crucial for dark board visibility!)
    canvas.drawCircle(
      pos,
      r - 0.7 * shrink,
      Paint()
        ..color = style.blackRim.withOpacity(0.95 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * shrink,
    );

    // 4. Subtle Inner Bevel Ring for beveled ceramic depth
    canvas.drawCircle(
      pos,
      r * 0.84,
      Paint()
        ..color = style.blackGroove.withOpacity(0.45 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * shrink,
    );

    // 5. Concentric lathe grooves
    final Paint groovePaint = Paint()
      ..color = style.blackGroove.withOpacity(0.85 * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * shrink;
    canvas.drawCircle(pos, r * 0.58, groovePaint);

    groovePaint.strokeWidth = 0.7 * shrink;
    canvas.drawCircle(pos, r * 0.32, groovePaint);

    // 6. Center dimple pip
    canvas.drawCircle(
      pos,
      r * 0.14,
      Paint()..color = style.blackCenter.withOpacity(0.95 * shrink),
    );

    // 7. Specular highlight catching top light
    canvas.drawCircle(
      Offset(pos.dx - r * 0.32, pos.dy - r * 0.32),
      r * 0.16,
      Paint()..color = style.blackHighlight.withOpacity(
          (style.blackHighlight.opacity * shrink).clamp(0.0, 1.0)),
    );
  }

  void _drawQueenPiece(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    // 1. Ruby / Gem Body
    final Paint bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.32),
        radius: 0.9,
        colors: style.queenGradient,
        stops: const [0.0, 0.5, 0.82, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, bodyPaint);

    // 2. Outer Ruby Boundary Rim
    canvas.drawCircle(
      pos,
      r - 0.5 * shrink,
      Paint()
        ..color = const Color(0xFF6B0014).withOpacity(0.85 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * shrink,
    );

    // 3. Royal Golden Medallion Ring
    canvas.drawCircle(
      pos,
      r * 0.76,
      Paint()
        ..color = style.queenOuterRing.withOpacity(0.96 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * shrink,
    );

    // 4. Center 8-point Gold Star Emblem
    _drawCompassStar(
      canvas,
      pos,
      style.queenStarPoints,
      r * 0.44,
      r * 0.20,
      style.queenStarColor,
      shrink,
    );

    // 5. Center Royal Pip & gold collar
    canvas.drawCircle(
      pos,
      2.4 * shrink,
      Paint()..color = style.queenCenterPip.withOpacity(0.95 * shrink),
    );
    canvas.drawCircle(
      pos,
      2.4 * shrink,
      Paint()
        ..color = style.queenCenterRing.withOpacity(0.95 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * shrink,
    );

    // 6. Specular gloss highlight
    canvas.drawCircle(
      Offset(pos.dx - r * 0.32, pos.dy - r * 0.32),
      r * 0.18,
      Paint()..color = Colors.white.withOpacity(0.70 * shrink),
    );
  }

  void _drawStriker(Canvas canvas, PieceModel striker, ThemePieceStyle style) {
    final double shrink = (1.0 - striker.pocketProgress).clamp(0.0, 1.0);
    if (shrink <= 0.001) return;

    final Offset pos = Offset(striker.position.x, striker.position.y);
    final double r = striker.radius * shrink;

    // 1. Aiming / Power Charging Ring (Rendered beneath/around striker)
    if (isAiming && aimPower > 0.02) {
      _drawStrikerAimPowerRing(canvas, pos, r, shrink, style);
    }

    // 2. Idle / Ready breathing aura halo (subtle and tight)
    final double glowAlpha =
        (0.12 + 0.08 * math.sin(strikerGlowPhase * math.pi * 2)).clamp(0.04, 0.20);
    canvas.drawCircle(
      pos,
      r + 2.5 * shrink,
      Paint()
        ..color = style.strikerGlow.withOpacity(glowAlpha * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 3. Tabletop contact shadow
    canvas.drawCircle(
      Offset(pos.dx + 2.2 * shrink, pos.dy + 2.8 * shrink),
      r,
      Paint()
        ..color = Colors.black.withOpacity(0.50 * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // 4. Striker Main Body Radial Gradient
    final Paint bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.92,
        colors: style.strikerGradient,
        stops: const [0.0, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, bodyPaint);

    // 5. Theme-specific surface texture & micro-details
    _drawStrikerThemeTexture(canvas, pos, r, shrink);

    // 6. Outer dark definition bumper rim
    canvas.drawCircle(
      pos,
      r - 0.5 * shrink,
      Paint()
        ..color = style.strikerOuterRim.withOpacity(0.70 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * shrink,
    );

    // 7. Outer metallic bezel ring
    canvas.drawCircle(
      pos,
      r - 2.0 * shrink,
      Paint()
        ..color = style.strikerBezelRing.withOpacity(0.92 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * shrink,
    );

    // 8. Inner decorative accent ring
    canvas.drawCircle(
      pos,
      r * 0.66,
      Paint()
        ..color = style.strikerAccentRing.withOpacity(0.85 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * shrink,
    );

    // 9. Center theme-specific medallion emblem
    _drawStrikerEmblem(canvas, pos, r, shrink, style);

    // 10. Center jewel core pip & metal collar
    canvas.drawCircle(
      pos,
      2.8 * shrink,
      Paint()..color = style.strikerGemCore.withOpacity(0.95 * shrink),
    );
    canvas.drawCircle(
      pos,
      2.8 * shrink,
      Paint()
        ..color = style.strikerGemRim.withOpacity(0.95 * shrink)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9 * shrink,
    );

    // 11. Idle specular glint sweep around bezel
    _drawStrikerIdleGleam(canvas, pos, r, shrink, style);

    // 12. Top-left curved gloss sheen
    canvas.drawCircle(
      Offset(pos.dx - r * 0.34, pos.dy - r * 0.34),
      r * 0.20,
      Paint()..color = Colors.white.withOpacity(0.65 * shrink),
    );
  }

  void _drawStrikerThemeTexture(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
  ) {
    switch (theme) {
      case BoardThemeType.walnutClub:
        // Concentric wood lathe rings
        final Paint woodGrainPaint = Paint()
          ..color = const Color(0xFF6B4226).withOpacity(0.20 * shrink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * shrink;
        canvas.drawCircle(pos, r * 0.82, woodGrainPaint);
        canvas.drawCircle(pos, r * 0.50, woodGrainPaint);
        break;

      case BoardThemeType.neonArena:
        // High-tech cyber optic grid ticks
        final Paint cyberPaint = Paint()
          ..color = const Color(0xFF00F0FF).withOpacity(0.35 * shrink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * shrink;
        canvas.drawCircle(pos, r * 0.82, cyberPaint);
        for (int i = 0; i < 4; i++) {
          final double angle = i * math.pi / 2;
          canvas.drawLine(
            Offset(pos.dx + r * 0.70 * math.cos(angle), pos.dy + r * 0.70 * math.sin(angle)),
            Offset(pos.dx + r * 0.85 * math.cos(angle), pos.dy + r * 0.85 * math.sin(angle)),
            cyberPaint,
          );
        }
        break;

      case BoardThemeType.goldenPalace:
        // Imperial marble veining
        final Paint goldVeinPaint = Paint()
          ..color = const Color(0xFFD97706).withOpacity(0.25 * shrink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 * shrink;
        canvas.drawCircle(pos, r * 0.80, goldVeinPaint);
        canvas.drawCircle(pos, r * 0.48, goldVeinPaint);
        break;

      case BoardThemeType.cosmicElite:
        // Micro starlight constellation points
        final Paint starDotPaint = Paint()
          ..color = const Color(0xFFDDD6FE).withOpacity(0.60 * shrink)
          ..style = PaintingStyle.fill;
        for (int i = 0; i < 6; i++) {
          final double angle = i * (math.pi / 3);
          canvas.drawCircle(
            Offset(pos.dx + r * 0.52 * math.cos(angle), pos.dy + r * 0.52 * math.sin(angle)),
            1.2 * shrink,
            starDotPaint,
          );
        }
        break;

      case BoardThemeType.oceanBreeze:
        // Subtle water ripple ring
        final Paint ripplePaint = Paint()
          ..color = const Color(0xFF22D3EE).withOpacity(0.30 * shrink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * shrink;
        canvas.drawCircle(pos, r * 0.78, ripplePaint);
        break;

      case BoardThemeType.sakuraStudio:
        // Soft blush accent ring
        final Paint blushPaint = Paint()
          ..color = const Color(0xFFFDA4AF).withOpacity(0.35 * shrink)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * shrink;
        canvas.drawCircle(pos, r * 0.78, blushPaint);
        break;

      default:
        break;
    }
  }

  void _drawStrikerIdleGleam(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    // Rotating specular glint sweep around bezel
    final double sweepAngle = strikerGlowPhase * 2 * math.pi;
    final double glintR = r - 2.0 * shrink;
    final Offset glintPos = Offset(
      pos.dx + glintR * math.cos(sweepAngle),
      pos.dy + glintR * math.sin(sweepAngle),
    );
    canvas.drawCircle(
      glintPos,
      3.2 * shrink,
      Paint()
        ..color = Colors.white.withOpacity(0.55 * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
  }

  void _drawStrikerAimPowerRing(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    final double ringR = r + 4.5 * shrink;
    final double sweep = math.pi * 2 * aimPower;
    final double startAngle = aimAngle - math.pi / 2 - sweep / 2;

    // Outer charging glow arc
    final Paint glowArcPaint = Paint()
      ..color = style.powerRingColor.withOpacity((0.35 + 0.45 * aimPower) * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.0 + 2.0 * aimPower) * shrink
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: ringR),
      startAngle,
      sweep,
      false,
      glowArcPaint,
    );

    // Crisp inner core power line
    final Paint coreArcPaint = Paint()
      ..color = Colors.white.withOpacity((0.60 + 0.40 * aimPower) * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * shrink
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: ringR),
      startAngle,
      sweep,
      false,
      coreArcPaint,
    );

    // 4 Power notched ticks (25%, 50%, 75%, 100%)
    for (int i = 1; i <= 4; i++) {
      final double notchPower = i * 0.25;
      final bool isCharged = aimPower >= notchPower;
      final double notchAngle =
          aimAngle - math.pi / 2 - math.pi + (notchPower * 2 * math.pi);
      final double innerTick = ringR - 2.0 * shrink;
      final double outerTick = ringR + 3.0 * shrink;
      final Offset pStart = Offset(
        pos.dx + innerTick * math.cos(notchAngle),
        pos.dy + innerTick * math.sin(notchAngle),
      );
      final Offset pEnd = Offset(
        pos.dx + outerTick * math.cos(notchAngle),
        pos.dy + outerTick * math.sin(notchAngle),
      );
      canvas.drawLine(
        pStart,
        pEnd,
        Paint()
          ..color = (isCharged
              ? style.powerRingColor
              : Colors.white.withOpacity(0.25))
          ..strokeWidth = (isCharged ? 1.8 : 1.0) * shrink,
      );
    }
  }

  void _drawStrikerEmblem(
    Canvas canvas,
    Offset pos,
    double r,
    double shrink,
    ThemePieceStyle style,
  ) {
    switch (style.strikerEmblemType) {
      case StrikerEmblemType.compass:
        _drawCompassStar(
          canvas,
          pos,
          style.strikerStarPoints,
          r * 0.44,
          r * 0.19,
          style.strikerEmblemColor,
          shrink,
        );
        break;
      case StrikerEmblemType.rosette:
        _drawRosette(
          canvas,
          pos,
          r * 0.44,
          r * 0.22,
          style.strikerEmblemColor,
          shrink,
        );
        break;
      case StrikerEmblemType.wave:
        _drawWaveEmblem(
          canvas,
          pos,
          r * 0.44,
          style.strikerEmblemColor,
          shrink,
        );
        break;
      case StrikerEmblemType.cyber:
        _drawCyberReticle(
          canvas,
          pos,
          r * 0.44,
          style.strikerEmblemColor,
          shrink,
        );
        break;
      case StrikerEmblemType.celestial:
        _drawCelestialPulsar(
          canvas,
          pos,
          r * 0.44,
          r * 0.20,
          style.strikerEmblemColor,
          shrink,
        );
        break;
    }
  }

  void _drawCompassStar(
    Canvas canvas,
    Offset center,
    int points,
    double outerR,
    double innerR,
    Color color,
    double shrink,
  ) {
    final Path star = Path();
    final double step = math.pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final double r = (i % 2 == 0 ? outerR : innerR) * shrink;
      final double angle = i * step - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();

    canvas.drawPath(star, Paint()..color = color.withOpacity(0.92 * shrink));
  }

  void _drawRosette(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Color color,
    double shrink,
  ) {
    final Path path = Path();
    const int lobes = 12;
    const double step = math.pi / lobes;
    for (int i = 0; i < 2 * lobes; i++) {
      final double r = (i % 2 == 0 ? outerR : innerR) * shrink;
      final double angle = i * step - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.92 * shrink));
  }

  void _drawWaveEmblem(
    Canvas canvas,
    Offset center,
    double outerR,
    Color color,
    double shrink,
  ) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.92 * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * shrink;

    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final Path wavePath = Path()
        ..moveTo(-outerR * 0.45 * shrink, 0)
        ..quadraticBezierTo(
          0,
          -outerR * 0.35 * shrink,
          outerR * 0.45 * shrink,
          -outerR * 0.15 * shrink,
        );
      canvas.drawPath(wavePath, paint);
      canvas.restore();
    }
    canvas.drawCircle(center, outerR * 0.3 * shrink, paint);
  }

  void _drawCyberReticle(
    Canvas canvas,
    Offset center,
    double outerR,
    Color color,
    double shrink,
  ) {
    final Paint linePaint = Paint()
      ..color = color.withOpacity(0.95 * shrink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * shrink;

    final double r1 = outerR * 0.75 * shrink;
    final double r2 = outerR * 0.45 * shrink;
    canvas.drawCircle(center, r1, linePaint);
    canvas.drawCircle(center, r2, linePaint);

    final double tickLen = outerR * 0.3 * shrink;
    canvas.drawLine(
      Offset(center.dx, center.dy - outerR * 0.9 * shrink),
      Offset(center.dx, center.dy - outerR * 0.9 * shrink + tickLen),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + outerR * 0.9 * shrink),
      Offset(center.dx, center.dy + outerR * 0.9 * shrink - tickLen),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - outerR * 0.9 * shrink, center.dy),
      Offset(center.dx - outerR * 0.9 * shrink + tickLen, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + outerR * 0.9 * shrink, center.dy),
      Offset(center.dx + outerR * 0.9 * shrink - tickLen, center.dy),
      linePaint,
    );
  }

  void _drawCelestialPulsar(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Color color,
    double shrink,
  ) {
    final Path star = Path();
    for (int i = 0; i < 8; i++) {
      final bool isCardinal = i % 2 == 0;
      final double r = (isCardinal ? outerR : innerR * 0.6) * shrink;
      final double angle = i * (math.pi / 4) - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color.withOpacity(0.92 * shrink));
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) => true;
}
