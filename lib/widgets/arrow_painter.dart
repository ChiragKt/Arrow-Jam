import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

/// Paints a thin snake-style arrow (line + arrowhead) inside a cell.
class ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;
  final double opacity;

  ArrowPainter({
    required this.direction,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.width * 0.28; // shaft length from center
    final hw = size.width * 0.14; // arrowhead wing half-width
    final hl = size.width * 0.18; // arrowhead length

    // Shaft + head coordinates per direction
    late Offset tail, tip;
    late Offset wingA, wingB;

    switch (direction) {
      case ArrowDirection.up:
        tail = Offset(cx, cy + len);
        tip  = Offset(cx, cy - len);
        wingA = Offset(cx - hw, cy - len + hl);
        wingB = Offset(cx + hw, cy - len + hl);
        break;
      case ArrowDirection.down:
        tail = Offset(cx, cy - len);
        tip  = Offset(cx, cy + len);
        wingA = Offset(cx - hw, cy + len - hl);
        wingB = Offset(cx + hw, cy + len - hl);
        break;
      case ArrowDirection.left:
        tail = Offset(cx + len, cy);
        tip  = Offset(cx - len, cy);
        wingA = Offset(cx - len + hl, cy - hw);
        wingB = Offset(cx - len + hl, cy + hw);
        break;
      case ArrowDirection.right:
        tail = Offset(cx - len, cy);
        tip  = Offset(cx + len, cy);
        wingA = Offset(cx + len - hl, cy - hw);
        wingB = Offset(cx + len - hl, cy + hw);
        break;
    }

    // Draw shaft
    canvas.drawLine(tail, tip, paint);
    // Draw arrowhead
    canvas.drawLine(tip, wingA, paint);
    canvas.drawLine(tip, wingB, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter old) =>
      old.direction != direction ||
      old.color != color ||
      old.opacity != opacity;
}
