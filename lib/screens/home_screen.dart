import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDifficultyPicker = false;

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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Top bar: Theme cycle + Settings
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Theme cycle button
                      GestureDetector(
                        onTap: () {
                          final themes = AppThemes.all;
                          final currentIdx = themes.indexWhere((t) => t.id == settings.themeId);
                          final nextIdx = (currentIdx + 1) % themes.length;
                          settings.setTheme(themes[nextIdx].id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.gridLine, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(theme.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                theme.name.toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                  color: theme.textSecondary,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.chevron_right, color: theme.textSecondary, size: 14),
                            ],
                          ),
                        ),
                      ),
                      // Settings icon
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.gridLine, width: 1),
                          ),
                          child: Icon(Icons.tune, color: theme.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Title
                Text(
                  'ARROW',
                  style: GoogleFonts.spaceMono(
                    color: theme.accent,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    height: 1.0,
                  ),
                ),
                Text(
                  'JAM',
                  style: GoogleFonts.spaceMono(
                    color: theme.textPrimary.withValues(alpha: 0.35),
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 16,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 24),
                _MiniPreview(theme: theme),
                const Spacer(flex: 2),

                if (!_showDifficultyPicker)
                  _buildMainButtons(theme, gs)
                else
                  _buildDifficultyPicker(theme, gs),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButtons(AppTheme theme, GameState gs) {
    return Column(
      children: [
        // Big PLAY button (random difficulty)
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              gs.setRandomDifficulty(true);
              gs.startGame();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('▶', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  'PLAY',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Choose difficulty button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textSecondary,
              side: BorderSide(color: theme.gridLine, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => setState(() => _showDifficultyPicker = true),
            child: Text(
              'SELECT DIFFICULTY',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyPicker(AppTheme theme, GameState gs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showDifficultyPicker = false),
              child: Icon(Icons.arrow_back_ios, color: theme.textSecondary, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'DIFFICULTY',
              style: GoogleFonts.spaceMono(
                color: theme.textSecondary,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(kDifficulties.length, (i) {
          final d = kDifficulties[i];
          final selected = gs.difficultyIndex == i;
          return GestureDetector(
            onTap: () => gs.setDifficulty(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? theme.accent.withValues(alpha: 0.12) : theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? theme.accent : theme.gridLine,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.label.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            color: selected ? theme.accent : theme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${d.gridSize}×${d.gridSize}  •  ${d.timeSeconds}s  •  ${d.lives} lives',
                          style: GoogleFonts.spaceMono(
                            color: theme.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check, color: theme.accent, size: 16),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: gs.difficultyIndex < 0
                ? null
                : () {
                    gs.startGame();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    ).then((_) => setState(() => _showDifficultyPicker = false));
                  },
            child: Text(
              gs.difficultyIndex >= 0
                  ? 'PLAY  •  ${kDifficulties[gs.difficultyIndex].label.toUpperCase()}'
                  : 'SELECT A DIFFICULTY',
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mini Preview (full 4×4 grid) ────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  final AppTheme theme;
  const _MiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    // Multi-cell arrows spanning a 4×4 grid preview.
    // Each entry: (headCol, headRow, direction, length)
    // These partition the 4×4 = 16 cells exactly.
    const n = 4;
    const previewArrows = [
      // Row 0: →→→ (len 3, head at col 2), ↓ (len 1, head row 0)
      (2, 0, ArrowDirection.right, 3),
      (3, 0, ArrowDirection.down,  1),
      // Col 0: ↓↓ (len 2, head at row 1)
      (0, 1, ArrowDirection.down,  2),
      // Row 1: →→ (len 2, head at col 2), ↓ (len 1)
      (2, 1, ArrowDirection.right, 2),
      (3, 1, ArrowDirection.down,  1),
      // Row 2: ←←← (len 3, head at col 0)
      (0, 2, ArrowDirection.left,  3),
      (3, 2, ArrowDirection.down,  1),
      // Row 3: →→→→ (len 4, head at col 3)
      (3, 3, ArrowDirection.left,  4),
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
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(c.maxWidth, c.maxWidth),
                painter: _MiniGrid(n: n, color: theme.gridLine),
              ),
              ...previewArrows.map((a) {
                final (hc, hr, dir, len) = a;
                final isH = dir == ArrowDirection.left || dir == ArrowDirection.right;
                // Compute top-left of bounding box
                int minC = hc, minR = hr;
                int bc = hc, br = hr;
                for (int i = 1; i < len; i++) {
                  switch (dir) {
                    case ArrowDirection.up:    br++; break;
                    case ArrowDirection.down:  br--; break;
                    case ArrowDirection.left:  bc++; break;
                    case ArrowDirection.right: bc--; break;
                  }
                }
                minC = hc < bc ? hc : bc;
                minR = hr < br ? hr : br;
                return Positioned(
                  left: minC * cell,
                  top:  minR * cell,
                  child: SizedBox(
                    width:  isH ? len * cell : cell,
                    height: isH ? cell       : len * cell,
                    child: CustomPaint(
                      painter: _MiniArrow(
                        dir:      dir,
                        color:    theme.arrowColor(dir),
                        length:   len,
                        cellSize: cell,
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

class _MiniGrid extends CustomPainter {
  final int n;
  final Color color;
  _MiniGrid({required this.n, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 0.5;
    final cell = size.width / n;
    for (int i = 0; i <= n; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), p);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _MiniArrow extends CustomPainter {
  final ArrowDirection dir;
  final Color color;
  final int   length;
  final double cellSize;
  _MiniArrow({required this.dir, required this.color, required this.length, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color      = color
      ..strokeWidth = cellSize * 0.10
      ..strokeCap  = StrokeCap.round
      ..style      = PaintingStyle.stroke;

    final pad = cellSize * 0.18;
    final hw  = cellSize * 0.18;
    final hl  = cellSize * 0.22;
    final mid = size.height / 2;
    final w   = size.width;

    final tail = Offset(pad, mid);
    final tip  = Offset(w - pad, mid);
    final wA   = Offset(w - pad - hl, mid - hw);
    final wB   = Offset(w - pad - hl, mid + hw);

    canvas.save();
    final cx = size.width / 2;
    final cy = size.height / 2;
    double angle = 0;
    switch (dir) {
      case ArrowDirection.right: angle = 0; break;
      case ArrowDirection.left:  angle = 3.14159265; break;
      case ArrowDirection.down:  angle = 3.14159265 / 2; break;
      case ArrowDirection.up:    angle = -3.14159265 / 2; break;
    }
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);

    canvas.drawLine(tail, tip, p);
    canvas.drawLine(tip, wA, p);
    canvas.drawLine(tip, wB, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
