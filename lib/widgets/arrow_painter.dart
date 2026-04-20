import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';

/// Paints one multi-cell snake arrow.
///
/// The canvas covers the ENTIRE grid (totalSize × totalSize).
/// All drawing coordinates are computed from [cellSize] and the arrow's
/// [cells] list, so the snake correctly spans multiple cells.
///
/// Drawing:
///  • A translucent rounded-rect "pill" behind every cell the snake occupies
///  • A polyline through the centre of each cell (tail → head)
///  • An arrowhead at the head, offset slightly outward in [direction]
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

  Offset _dirOffset(ArrowDirection d, double len) => switch (d) {
    ArrowDirection.up    => Offset(0, -len),
    ArrowDirection.down  => Offset(0,  len),
    ArrowDirection.left  => Offset(-len, 0),
    ArrowDirection.right => Offset( len, 0),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final sw = (cellSize * 0.12).clamp(2.0, 8.0);
    final hw = cellSize * 0.17;
    final hl = cellSize * 0.22;

    // ── Background pill per cell ──────────────────────────────────────────
    final bgPaint = Paint()
      ..color = color.withValues(alpha: (opacity * 0.20).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    final pad = cellSize * 0.08;
    final rr  = Radius.circular(cellSize * 0.20);
    for (final cell in arrow.cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cell.col * cellSize + pad,
            cell.row * cellSize + pad,
            cellSize - pad * 2,
            cellSize - pad * 2,
          ),
          rr,
        ),
        bgPaint,
      );
    }

    // ── Shaft polyline ────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color      = color.withValues(alpha: opacity)
      ..strokeWidth = sw
      ..strokeCap  = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style      = PaintingStyle.stroke;

    if (arrow.cells.length == 1) {
      // Single-cell: stub from centre toward tail side
      final centre  = _centre(arrow.cells.first);
      final tailOff = _dirOffset(arrow.direction, -cellSize * 0.22); // opposite dir
      canvas.drawLine(centre + tailOff, centre, linePaint);
    } else {
      final path = Path();
      final first = _centre(arrow.cells.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < arrow.cells.length; i++) {
        final pt = _centre(arrow.cells[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // ── Arrowhead ─────────────────────────────────────────────────────────
    final headPaint = Paint()
      ..color      = color.withValues(alpha: opacity)
      ..strokeWidth = sw
      ..strokeCap  = StrokeCap.round
      ..style      = PaintingStyle.stroke;

    final headCentre = _centre(arrow.cells.last);
    // Push tip slightly outside the cell so it reads clearly
    final tip = headCentre + _dirOffset(arrow.direction, cellSize * 0.30);

    // Wing directions: perpendicular + back
    final Offset wA, wB;
    switch (arrow.direction) {
      case ArrowDirection.up:
        wA = tip + Offset(-hw,  hl);
        wB = tip + Offset( hw,  hl);
        break;
      case ArrowDirection.down:
        wA = tip + Offset(-hw, -hl);
        wB = tip + Offset( hw, -hl);
        break;
      case ArrowDirection.left:
        wA = tip + Offset( hl, -hw);
        wB = tip + Offset( hl,  hw);
        break;
      case ArrowDirection.right:
        wA = tip + Offset(-hl, -hw);
        wB = tip + Offset(-hl,  hw);
        break;
    }

    canvas.drawLine(tip, wA, headPaint);
    canvas.drawLine(tip, wB, headPaint);
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

// Keep single-cell ArrowPainter for the home-screen mini preview only
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
    final paint = Paint()
      ..color      = color.withValues(alpha: opacity)
      ..strokeWidth = size.width * 0.10
      ..strokeCap  = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style      = PaintingStyle.stroke;

    final cx  = size.width  / 2;
    final cy  = size.height / 2;
    final len = size.width  * 0.28;
    final hw  = size.width  * 0.14;
    final hl  = size.width  * 0.18;

    late Offset tail, tip, wingA, wingB;
    switch (direction) {
      case ArrowDirection.up:
        tail = Offset(cx, cy+len); tip = Offset(cx, cy-len);
        wingA = Offset(cx-hw, cy-len+hl); wingB = Offset(cx+hw, cy-len+hl);
      case ArrowDirection.down:
        tail = Offset(cx, cy-len); tip = Offset(cx, cy+len);
        wingA = Offset(cx-hw, cy+len-hl); wingB = Offset(cx+hw, cy+len-hl);
      case ArrowDirection.left:
        tail = Offset(cx+len, cy); tip = Offset(cx-len, cy);
        wingA = Offset(cx-len+hl, cy-hw); wingB = Offset(cx-len+hl, cy+hw);
      case ArrowDirection.right:
        tail = Offset(cx-len, cy); tip = Offset(cx+len, cy);
        wingA = Offset(cx+len-hl, cy-hw); wingB = Offset(cx+len-hl, cy+hw);
    }
    canvas.drawLine(tail, tip, paint);
    canvas.drawLine(tip, wingA, paint);
    canvas.drawLine(tip, wingB, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter old) =>
      old.direction != direction || old.color != color || old.opacity != opacity;
}
