import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

/// Paints a multi-cell arrow spanning [length] cells.
/// The canvas size passed in is [length] cells wide (in the arrow's axis)
/// and 1 cell tall (in the perpendicular axis).
///
/// The arrow is drawn as:
///   • A straight shaft running the full length of the canvas
///   • An arrowhead at the TIP end (the head cell side)
///
/// The arrowhead always has the same fixed size regardless of length,
/// so short and long arrows feel visually consistent.
class ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color          color;
  final double         opacity;
  final int            length;      // number of cells spanned
  final double         cellSize;    // size of one cell in pixels

  const ArrowPainter({
    required this.direction,
    required this.color,
    required this.opacity,
    required this.length,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color       = color.withValues(alpha: opacity)
      ..strokeWidth = cellSize * 0.10
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    // Fixed arrowhead dimensions (relative to one cell, not the whole length)
    final hw = cellSize * 0.18;   // half-width of arrowhead wings
    final hl = cellSize * 0.22;   // depth of arrowhead

    // Padding from each edge so the arrow doesn't touch the cell border
    final pad = cellSize * 0.18;

    // We draw in a normalised coordinate system where the arrow always points →
    // then rotate via canvas transform.
    //
    // Canvas width  = full pixel span of the arrow (length × cellSize)
    // Canvas height = cellSize
    //
    // Shaft: from (pad, cellSize/2) to (width - pad, cellSize/2)
    // Head:  at the RIGHT end (tip)

    final w   = size.width;
    final mid = size.height / 2;

    final tail = Offset(pad, mid);
    final tip  = Offset(w - pad, mid);
    final wA   = Offset(w - pad - hl, mid - hw);
    final wB   = Offset(w - pad - hl, mid + hw);

    // Rotate the canvas based on direction so the arrow always draws correctly
    canvas.save();
    final cx = size.width  / 2;
    final cy = size.height / 2;

    double angle = 0;
    switch (direction) {
      case ArrowDirection.right: angle = 0;           break;
      case ArrowDirection.left:  angle = 3.14159265;  break;
      case ArrowDirection.down:  angle = 3.14159265 / 2; break;
      case ArrowDirection.up:    angle = -3.14159265 / 2; break;
    }

    // For vertical arrows the canvas is rotated, so width/height are swapped.
    // We need to pivot around the canvas centre.
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);

    canvas.drawLine(tail, tip, paint);
    canvas.drawLine(tip,  wA,  paint);
    canvas.drawLine(tip,  wB,  paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter old) =>
      old.direction != direction ||
      old.color     != color     ||
      old.opacity   != opacity   ||
      old.length    != length    ||
      old.cellSize  != cellSize;
}
