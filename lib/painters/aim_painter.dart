import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/game_config.dart';
import '../core/vector2.dart';

class AimPainter extends CustomPainter {
  final Vector2 strikerPos;
  final Vector2? dragVector; // Drag vector (dx, dy)
  final double power; // 0.0 to 1.0

  AimPainter({
    required this.strikerPos,
    this.dragVector,
    required this.power,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragVector == null || dragVector!.lengthSquared < 16.0) return;

    final double scale =
        size.width / (GameConfig.boardSize + GameConfig.frameWidth * 2);
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);

    final Offset sPos = Offset(strikerPos.x, strikerPos.y);

    // Aim direction is opposite to drag
    final Vector2 shotDir = -dragVector!.normalized();
    final double maxAimDist = 92.0 + power * 155.0;

    // Smooth color transition: Teal/Green (Control) -> Amber Gold (Medium) -> Coral Red (Power)
    Color aimColor;
    if (power < 0.38) {
      aimColor = AppColors.accentGreen;
    } else if (power < 0.76) {
      aimColor = AppColors.accentAmber;
    } else {
      aimColor = AppColors.accentRed;
    }

    // 1. Pull-back tension line behind striker
    final Offset dragEnd = Offset(
      sPos.dx + dragVector!.x * 0.42,
      sPos.dy + dragVector!.y * 0.42,
    );
    canvas.drawLine(
      sPos,
      dragEnd,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      sPos,
      dragEnd,
      Paint()
        ..color = aimColor.withOpacity(0.75)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      dragEnd,
      4.2,
      Paint()..color = aimColor,
    );
    canvas.drawCircle(
      dragEnd,
      4.2,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. High-contrast trajectory guide dots (shadow-backed for visibility on all surfaces)
    const double step = 9.5;
    for (double d = 22.0; d < maxAimDist; d += step) {
      final double progress = d / maxAimDist;
      final double alpha = (1.0 - progress * 0.65).clamp(0.25, 1.0);
      final double dotRadius = 3.0 * (1.0 - progress * 0.40);

      final Offset pt = Offset(
        sPos.dx + shotDir.x * d,
        sPos.dy + shotDir.y * d,
      );

      // Dark halo ring for contrast on light birchwood
      canvas.drawCircle(
        pt,
        dotRadius + 0.9,
        Paint()..color = Colors.black.withOpacity(alpha * 0.45),
      );
      canvas.drawCircle(
        pt,
        dotRadius,
        Paint()..color = aimColor.withOpacity(alpha),
      );
    }

    // 3. Impact Ghost Striker Reticle at trajectory tip
    final Offset tipPos = Offset(
      sPos.dx + shotDir.x * maxAimDist,
      sPos.dy + shotDir.y * maxAimDist,
    );
    canvas.drawCircle(
      tipPos,
      GameConfig.strikerRadius,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      tipPos,
      GameConfig.strikerRadius,
      Paint()
        ..color = aimColor.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Precision crosshair inside ghost striker
    canvas.drawLine(
      Offset(tipPos.dx - 4.5, tipPos.dy),
      Offset(tipPos.dx + 4.5, tipPos.dy),
      Paint()
        ..color = aimColor.withOpacity(0.85)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(tipPos.dx, tipPos.dy - 4.5),
      Offset(tipPos.dx, tipPos.dy + 4.5),
      Paint()
        ..color = aimColor.withOpacity(0.85)
        ..strokeWidth = 1.2,
    );

    // 4. Radial Power Meter Ring around Striker
    final double ringR = GameConfig.strikerRadius + 5.0 + power * 11.0;
    canvas.drawCircle(
      sPos,
      ringR,
      Paint()
        ..color = Colors.black.withOpacity(0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2,
    );
    canvas.drawCircle(
      sPos,
      ringR,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 5. Active Power Sweep Arc
    final double sweep = power * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: sPos, radius: ringR),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = aimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // 6. Pill-backed Power Percentage Label (reusing cached TextPainter for 0..100)
    final int percent = (power * 100).round().clamp(0, 100);
    final textPainter = _getPercentPainter(percent);

    final Offset badgeCenter = Offset(sPos.dx, sPos.dy + ringR + 11.0);
    final RRect pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: badgeCenter,
        width: textPainter.width + 10,
        height: textPainter.height + 4,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      pillRect,
      Paint()..color = const Color(0xD90D1624),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = aimColor.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );

    canvas.restore();
  }

  static final Map<int, TextPainter> _percentPainterCache = {};

  static TextPainter _getPercentPainter(int percent) {
    var tp = _percentPainterCache[percent];
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(
          text: '$percent%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _percentPainterCache[percent] = tp;
    }
    return tp;
  }

  @override
  bool shouldRepaint(covariant AimPainter oldDelegate) {
    return oldDelegate.dragVector != dragVector ||
        oldDelegate.power != power ||
        oldDelegate.strikerPos != strikerPos;
  }
}
