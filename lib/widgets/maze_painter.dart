import 'package:flutter/material.dart';
import '../models/maze_model.dart';
import '../themes/game_themes.dart';

class MazePainter extends CustomPainter {
  final MazeModel maze;
  final int playerCol;
  final int playerRow;
  final int goalCol;
  final int goalRow;
  final GameTheme theme;
  final double glowIntensity; // 0..1 animation value

  MazePainter({
    required this.maze,
    required this.playerCol,
    required this.playerRow,
    required this.goalCol,
    required this.goalRow,
    required this.theme,
    this.glowIntensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / maze.cols;
    final cellH = size.height / maze.rows;

    // ── Background fill ──────────────────────────────────────────
    final bgPaint = Paint()..color = theme.pathColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Walls ────────────────────────────────────────────────────
    final wallPaint = Paint()
      ..color = theme.wallColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

    // Glow effect on walls for dark themes
    if (theme.isDark) {
      final glowPaint = Paint()
        ..color = theme.wallColor.withOpacity(0.25)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      _drawWalls(canvas, glowPaint, cellW, cellH);
    }
    _drawWalls(canvas, wallPaint, cellW, cellH);

    // ── Goal ─────────────────────────────────────────────────────
    final goalX = goalCol * cellW + cellW / 2;
    final goalY = goalRow * cellH + cellH / 2;
    final goalRadius = (cellW * 0.32).clamp(4.0, 14.0);

    if (theme.isDark) {
      canvas.drawCircle(
        Offset(goalX, goalY),
        goalRadius * 1.8,
        Paint()
          ..color = theme.goalColor.withOpacity(0.3 * glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(
      Offset(goalX, goalY),
      goalRadius,
      Paint()..color = theme.goalColor,
    );
    // Inner star shape
    canvas.drawCircle(
      Offset(goalX, goalY),
      goalRadius * 0.4,
      Paint()..color = Colors.white.withOpacity(0.8),
    );

    // ── Player ───────────────────────────────────────────────────
    final px = playerCol * cellW + cellW / 2;
    final py = playerRow * cellH + cellH / 2;
    final pr = (cellW * 0.28).clamp(4.0, 12.0);

    if (theme.isDark) {
      canvas.drawCircle(
        Offset(px, py),
        pr * 2.2,
        Paint()
          ..color = theme.playerColor.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(Offset(px, py), pr, Paint()..color = theme.playerColor);
    canvas.drawCircle(
      Offset(px - pr * 0.25, py - pr * 0.25),
      pr * 0.3,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }

  void _drawWalls(Canvas canvas, Paint paint, double cw, double ch) {
    for (int row = 0; row < maze.rows; row++) {
      for (int col = 0; col < maze.cols; col++) {
        final cell = maze.cell(col, row);
        final x = col * cw;
        final y = row * ch;
        if (cell.top)    canvas.drawLine(Offset(x, y), Offset(x + cw, y), paint);
        if (cell.right)  canvas.drawLine(Offset(x + cw, y), Offset(x + cw, y + ch), paint);
        if (cell.bottom) canvas.drawLine(Offset(x, y + ch), Offset(x + cw, y + ch), paint);
        if (cell.left)   canvas.drawLine(Offset(x, y), Offset(x, y + ch), paint);
      }
    }
  }

  @override
  bool shouldRepaint(MazePainter old) =>
      old.playerCol != playerCol ||
      old.playerRow != playerRow ||
      old.glowIntensity != glowIntensity ||
      old.theme.id != theme.id;
}
