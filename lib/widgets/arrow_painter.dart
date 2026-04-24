import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';

/// Paints one multi-cell snake arrow on a full-grid canvas.
class SnakeArrowPainter extends CustomPainter {
  final Arrow  arrow;
  final Color  color;
  final double opacity;
  final double cellSize;

  const SnakeArrowPainter({
    required this.arrow,
    required this.color,
    required this.opacity,
    required this.cellSize,
  });

  Offset _centre(ArrowCell cell) => Offset(
    cell.col * cellSize + cellSize * 0.5,
    cell.row * cellSize + cellSize * 0.5,
  );

  Offset _dirVec(ArrowDirection d) => switch (d) {
    ArrowDirection.up    => const Offset(0, -1),
    ArrowDirection.down  => const Offset(0,  1),
    ArrowDirection.left  => const Offset(-1, 0),
    ArrowDirection.right => const Offset( 1, 0),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final sw       = (cellSize * 0.12).clamp(2.0, 8.0);
    final wingHalf = sw * 1.8;
    final wingBack = sw * 2.2;
    final tipPush  = cellSize * 0.22;

    final dirVec     = _dirVec(arrow.direction);
    final headCentre = _centre(arrow.cells.last);
    final tip = Offset(
      headCentre.dx + dirVec.dx * tipPush,
      headCentre.dy + dirVec.dy * tipPush,
    );

    final linePaint = Paint()
      ..color       = color.withValues(alpha: opacity)
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final path = Path();
    if (arrow.cells.length == 1) {
      final behind = Offset(
        headCentre.dx - dirVec.dx * cellSize * 0.22,
        headCentre.dy - dirVec.dy * cellSize * 0.22,
      );
      path.moveTo(behind.dx, behind.dy);
    } else {
      final first = _centre(arrow.cells.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < arrow.cells.length; i++) {
        final c = _centre(arrow.cells[i]);
        path.lineTo(c.dx, c.dy);
      }
    }
    path.lineTo(tip.dx, tip.dy);
    canvas.drawPath(path, linePaint);

    final perpX = -dirVec.dy;
    final perpY =  dirVec.dx;
    final wA = Offset(
      tip.dx - dirVec.dx * wingBack + perpX * wingHalf,
      tip.dy - dirVec.dy * wingBack + perpY * wingHalf,
    );
    final wB = Offset(
      tip.dx - dirVec.dx * wingBack - perpX * wingHalf,
      tip.dy - dirVec.dy * wingBack - perpY * wingHalf,
    );

    final headPaint = Paint()
      ..color       = color.withValues(alpha: opacity)
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final vPath = Path()
      ..moveTo(wA.dx, wA.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(wB.dx, wB.dy);
    canvas.drawPath(vPath, headPaint);
  }

  @override
  bool shouldRepaint(SnakeArrowPainter old) =>
      old.arrow.id        != arrow.id        ||
      old.arrow.cleared   != arrow.cleared   ||
      old.arrow.animating != arrow.animating ||
      old.color           != color           ||
      old.opacity         != opacity         ||
      old.cellSize        != cellSize;
}

// Single-cell ArrowPainter for the home-screen mini preview only
class ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color          color;
  final double         opacity;

  const ArrowPainter({
    required this.direction,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.10;
    final paint = Paint()
      ..color       = color.withValues(alpha: opacity)
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final cx       = size.width  / 2;
    final cy       = size.height / 2;
    final len      = size.width  * 0.28;
    final wingHalf = sw * 1.8;
    final wingBack = sw * 2.2;

    late Offset tail, tip;
    late double dirX, dirY;
    switch (direction) {
      case ArrowDirection.up:
        tail = Offset(cx, cy + len); tip = Offset(cx, cy - len);
        dirX = 0; dirY = -1;
      case ArrowDirection.down:
        tail = Offset(cx, cy - len); tip = Offset(cx, cy + len);
        dirX = 0; dirY = 1;
      case ArrowDirection.left:
        tail = Offset(cx + len, cy); tip = Offset(cx - len, cy);
        dirX = -1; dirY = 0;
      case ArrowDirection.right:
        tail = Offset(cx - len, cy); tip = Offset(cx + len, cy);
        dirX = 1; dirY = 0;
    }

    final perpX = -dirY;
    final perpY =  dirX;
    final wingA = Offset(
      tip.dx - dirX * wingBack + perpX * wingHalf,
      tip.dy - dirY * wingBack + perpY * wingHalf,
    );
    final wingB = Offset(
      tip.dx - dirX * wingBack - perpX * wingHalf,
      tip.dy - dirY * wingBack - perpY * wingHalf,
    );

    canvas.drawLine(tail, tip, paint);
    final vPath = Path()
      ..moveTo(wingA.dx, wingA.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(wingB.dx, wingB.dy);
    canvas.drawPath(vPath, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter old) =>
      old.direction != direction || old.color != color || old.opacity != opacity;
}
