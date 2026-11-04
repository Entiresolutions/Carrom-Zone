import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/game_config.dart';
import '../core/vector2.dart';

enum SparkShape { circle, star, petal, diamond }

class PocketParticle {
  final Vector2 origin;
  final double angle;
  final double speed;
  final Color color;
  double life; // 0.0 to 1.0 (1.0 = fresh, 0.0 = dead)

  PocketParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.color,
    this.life = 1.0,
  });
}

class StrikerSparkParticle {
  final Vector2 origin;
  final double angle;
  final double speed;
  final Color color;
  final SparkShape shape;
  double life; // 0.0 to 1.0 (1.0 = fresh, 0.0 = dead)
  final double size;

  StrikerSparkParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.color,
    this.shape = SparkShape.circle,
    this.life = 1.0,
    this.size = 3.6,
  });
}

class PocketRingEffect {
  final Vector2 origin;
  final Color color;
  double progress; // 0.0 to 1.0
  final double maxRadius;
  final double strokeWidth;

  PocketRingEffect({
    required this.origin,
    required this.color,
    this.progress = 0.0,
    this.maxRadius = 46.0,
    this.strokeWidth = 3.6,
  });
}

class FloatingScoreEffect {
  final Vector2 origin;
  final String text;
  final Color color;
  double progress; // 0.0 to 1.0 (0.0 = start, 1.0 = disappeared)
  final TextPainter textPainter;

  FloatingScoreEffect({
    required this.origin,
    required this.text,
    required this.color,
    this.progress = 0.0,
  }) : textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 4,
                  offset: Offset(1, 2),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
}

class ParticlePainter extends CustomPainter {
  final List<PocketParticle> particles;
  final List<PocketRingEffect> rings;
  final List<FloatingScoreEffect> floatingScores;
  final List<StrikerSparkParticle> strikerSparks;

  ParticlePainter({
    required this.particles,
    required this.rings,
    this.floatingScores = const [],
    this.strikerSparks = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty &&
        rings.isEmpty &&
        floatingScores.isEmpty &&
        strikerSparks.isEmpty) {
      return;
    }

    final double scale =
        size.width / (GameConfig.boardSize + GameConfig.frameWidth * 2);
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    // 1. Draw expanding shockwave / ripple rings
    for (final ring in rings) {
      final double r = 8.0 + ring.progress * ring.maxRadius;
      final double alpha = (1.0 - ring.progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(ring.origin.x, ring.origin.y),
        r,
        Paint()
          ..color = ring.color.withOpacity(alpha * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.strokeWidth * (1.0 - ring.progress * 0.5),
      );
    }

    // 2. Draw pocket sparkle particles
    final Paint pPaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final double dist = (1.0 - p.life) * p.speed * 48.0;
      final Offset pt = Offset(
        p.origin.x + math.cos(p.angle) * dist,
        p.origin.y + math.sin(p.angle) * dist,
      );
      final double pRadius = 4.0 * p.life;
      canvas.drawCircle(
        pt,
        pRadius,
        pPaint..color = p.color.withOpacity(p.life.clamp(0.0, 1.0)),
      );
    }

    // 3. Draw theme-specific striker sparks / launch / collision particles
    for (final s in strikerSparks) {
      final double dist = (1.0 - s.life) * s.speed * 42.0;
      final Offset pt = Offset(
        s.origin.x + math.cos(s.angle) * dist,
        s.origin.y + math.sin(s.angle) * dist,
      );
      final double currentSize = s.size * s.life;
      final double alpha = s.life.clamp(0.0, 1.0);
      final Paint sPaint = Paint()..color = s.color.withOpacity(alpha);

      switch (s.shape) {
        case SparkShape.circle:
          canvas.drawCircle(pt, currentSize, sPaint);
          break;
        case SparkShape.star:
          _drawMiniStar(canvas, pt, currentSize * 1.5, currentSize * 0.5, sPaint);
          break;
        case SparkShape.petal:
          _drawPetal(canvas, pt, currentSize * 1.6, s.angle, sPaint);
          break;
        case SparkShape.diamond:
          _drawDiamond(canvas, pt, currentSize * 1.3, sPaint);
          break;
      }
    }

    // 4. Draw floating score badges
    for (final fs in floatingScores) {
      final double rise = fs.progress * 30.0;
      final double alpha = (1.0 - fs.progress).clamp(0.0, 1.0);
      final Offset pos = Offset(fs.origin.x, fs.origin.y - rise);

      canvas.saveLayer(
        Rect.fromCenter(
          center: pos,
          width: fs.textPainter.width + 20,
          height: fs.textPainter.height + 20,
        ),
        Paint()..color = Colors.white.withOpacity(alpha),
      );
      fs.textPainter.paint(
        canvas,
        Offset(pos.dx - fs.textPainter.width / 2,
            pos.dy - fs.textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawMiniStar(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Paint paint,
  ) {
    final Path star = Path();
    for (int i = 0; i < 8; i++) {
      final double r = (i % 2 == 0) ? outerR : innerR;
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
    canvas.drawPath(star, paint);
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final Path petal = Path()
      ..moveTo(0, -length)
      ..quadraticBezierTo(length * 0.6, 0, 0, length * 0.6)
      ..quadraticBezierTo(-length * 0.6, 0, 0, -length);
    petal.close();
    canvas.drawPath(petal, paint);
    canvas.restore();
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final Path diamond = Path()
      ..moveTo(center.dx, center.dy - size * 1.3)
      ..lineTo(center.dx + size * 0.8, center.dy)
      ..lineTo(center.dx, center.dy + size * 1.3)
      ..lineTo(center.dx - size * 0.8, center.dy);
    diamond.close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
