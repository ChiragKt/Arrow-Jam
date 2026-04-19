import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final gs = context.watch<GameState>();
    final theme = AppThemes.byId(settings.themeId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Settings icon top-right
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      child: Icon(Icons.tune, color: theme.textSecondary, size: 24),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Title
                Text(
                  'ARROW',
                  style: GoogleFonts.spaceMono(
                    color: theme.accent,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    height: 1.0,
                  ),
                ),
                Text(
                  'JAM',
                  style: GoogleFonts.spaceMono(
                    color: theme.textPrimary.withValues(alpha: 0.4),
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 16,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 16),

                // Mini preview grid
                _MiniPreview(theme: theme),

                const Spacer(flex: 2),

                // Difficulty pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(gs.difficulty.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        gs.difficulty.label.toUpperCase(),
                        style: GoogleFonts.spaceMono(
                          color: theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ' · ${gs.difficulty.gridSize}×${gs.difficulty.gridSize}',
                        style: GoogleFonts.spaceMono(
                          color: theme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Play button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      gs.startGame();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    child: Text(
                      'PLAY',
                      style: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny static arrow-grid preview for the home screen
class _MiniPreview extends StatelessWidget {
  final AppTheme theme;
  const _MiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final n = 4;
    final arrows = [
      (0, 0, ArrowDirection.right),
      (1, 0, ArrowDirection.down),
      (2, 1, ArrowDirection.left),
      (3, 1, ArrowDirection.up),
      (0, 2, ArrowDirection.right),
      (2, 2, ArrowDirection.down),
      (1, 3, ArrowDirection.up),
      (3, 3, ArrowDirection.left),
    ];

    return SizedBox(
      width: 140,
      height: 140,
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.gridLine, width: 1),
        ),
        child: LayoutBuilder(builder: (ctx, c) {
          final cell = c.maxWidth / n;
          return Stack(
            children: [
              CustomPaint(
                size: Size(c.maxWidth, c.maxWidth),
                painter: _MiniGridPainter(n: n, lineColor: theme.gridLine),
              ),
              ...arrows.map((a) {
                final (col, row, dir) = a;
                return Positioned(
                  left: col * cell,
                  top: row * cell,
                  child: SizedBox(
                    width: cell,
                    height: cell,
                    child: CustomPaint(
                      painter: _MiniArrowPainter(
                        dir: dir,
                        color: theme.arrowColor(dir),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final int n;
  final Color lineColor;
  _MiniGridPainter({required this.n, required this.lineColor});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = lineColor..strokeWidth = 0.5;
    final cell = size.width / n;
    for (int i = 0; i <= n; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), p);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _MiniArrowPainter extends CustomPainter {
  final ArrowDirection dir;
  final Color color;
  _MiniArrowPainter({required this.dir, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.width * 0.28;
    final hw = size.width * 0.14;
    final hl = size.width * 0.18;
    late Offset tail, tip, wA, wB;
    switch (dir) {
      case ArrowDirection.up:
        tail = Offset(cx, cy+len); tip = Offset(cx, cy-len);
        wA = Offset(cx-hw, cy-len+hl); wB = Offset(cx+hw, cy-len+hl);
      case ArrowDirection.down:
        tail = Offset(cx, cy-len); tip = Offset(cx, cy+len);
        wA = Offset(cx-hw, cy+len-hl); wB = Offset(cx+hw, cy+len-hl);
      case ArrowDirection.left:
        tail = Offset(cx+len, cy); tip = Offset(cx-len, cy);
        wA = Offset(cx-len+hl, cy-hw); wB = Offset(cx-len+hl, cy+hw);
      case ArrowDirection.right:
        tail = Offset(cx-len, cy); tip = Offset(cx+len, cy);
        wA = Offset(cx+len-hl, cy-hw); wB = Offset(cx+len-hl, cy+hw);
    }
    canvas.drawLine(tail, tip, p);
    canvas.drawLine(tip, wA, p);
    canvas.drawLine(tip, wB, p);
  }
  @override bool shouldRepaint(_) => false;
}
