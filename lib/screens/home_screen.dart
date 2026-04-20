import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/settings_state.dart';
import '../themes/app_themes.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

// Which sub-panel is showing on the home screen
enum _Panel { none, difficulty, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Panel _panel = _Panel.none;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final gs       = context.watch<GameState>();
    final theme    = AppThemes.byId(settings.themeId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Settings icon
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
                    color: theme.accent, fontSize: 44,
                    fontWeight: FontWeight.w700, letterSpacing: 8, height: 1.0,
                  ),
                ),
                Text(
                  'JAM',
                  style: GoogleFonts.spaceMono(
                    color: theme.textPrimary.withValues(alpha: 0.35),
                    fontSize: 44, fontWeight: FontWeight.w300,
                    letterSpacing: 16, height: 1.0,
                  ),
                ),

                const SizedBox(height: 20),
                _MiniPreview(theme: theme),

                const Spacer(flex: 2),

                // ── Mode area ──────────────────────────────────────────────
                if (_panel == _Panel.none)
                  _buildModeSelection(theme, gs)
                else if (_panel == _Panel.difficulty)
                  _buildDifficultyPicker(theme, gs)
                else
                  _buildCustomPicker(theme, gs),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mode selection (3 cards) ─────────────────────────────────────────────

  Widget _buildModeSelection(AppTheme theme, GameState gs) {
    return Column(
      children: [
        Text(
          'HOW DO YOU WANT TO PLAY?',
          style: GoogleFonts.spaceMono(
            color: theme.textSecondary, fontSize: 10, letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                emoji: '🎲', label: 'RANDOM', sub: 'Surprise difficulty',
                theme: theme,
                onTap: () {
                  gs.setRandomDifficulty(true);
                  _navigateToGame(gs);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                emoji: '🎯', label: 'SELECT', sub: 'Choose difficulty',
                theme: theme,
                onTap: () {
                  gs.setRandomDifficulty(false);
                  setState(() => _panel = _Panel.difficulty);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeCard(
                emoji: '🔧', label: 'CUSTOM', sub: 'Pick grid size',
                theme: theme,
                onTap: () => setState(() => _panel = _Panel.custom),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Preset difficulty picker ─────────────────────────────────────────────

  Widget _buildDifficultyPicker(AppTheme theme, GameState gs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(theme, 'DIFFICULTY'),
        const SizedBox(height: 12),
        ...List.generate(kDifficulties.length, (i) {
          final d        = kDifficulties[i];
          final selected = gs.difficultyIndex == i && !gs.isCustom;
          return GestureDetector(
            onTap: () => gs.setDifficulty(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin:  const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.accent.withValues(alpha: 0.12)
                    : theme.cardBg,
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
                            fontSize: 12, fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${d.gridSize}×${d.gridSize}  •  ${d.timeSeconds}s  •  ${d.lives} lives',
                          style: GoogleFonts.spaceMono(
                            color: theme.textSecondary, fontSize: 9,
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
        _playButton(
          theme: theme,
          label: gs.difficultyIndex >= 0 && !gs.isCustom
              ? 'PLAY  •  ${kDifficulties[gs.difficultyIndex].label.toUpperCase()}'
              : 'PLAY',
          onTap: () => _navigateToGame(gs),
        ),
      ],
    );
  }

  // ── Custom grid size picker ───────────────────────────────────────────────

  Widget _buildCustomPicker(AppTheme theme, GameState gs) {
    final size = gs.isCustom ? gs.customGridSize : 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(theme, 'CUSTOM GRID'),
        const SizedBox(height: 18),

        // Size display
        Center(
          child: Text(
            '${size} × ${size}',
            style: GoogleFonts.spaceMono(
              color: theme.accent, fontSize: 36, fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ),
        Center(
          child: Text(
            '${size * size} cells  •  ~${(size * size * 2.5).toInt()}s  •  ${(size / 2).ceil().clamp(2, 6)} lives',
            style: GoogleFonts.spaceMono(
              color: theme.textSecondary, fontSize: 10,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor:   theme.accent,
            inactiveTrackColor: theme.gridLine,
            thumbColor:         theme.accent,
            overlayColor:       theme.accent.withValues(alpha: 0.15),
            thumbShape:  const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value:    size.toDouble(),
            min:      3,
            max:      10,
            divisions: 7,
            onChanged: (v) => gs.setCustom(v.round()),
          ),
        ),

        // Size labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [3, 4, 5, 6, 7, 8, 9, 10].map((s) => Text(
              '$s',
              style: GoogleFonts.spaceMono(
                color: s == size ? theme.accent : theme.textSecondary,
                fontSize: 9,
                fontWeight: s == size ? FontWeight.w700 : FontWeight.w400,
              ),
            )).toList(),
          ),
        ),

        const SizedBox(height: 18),
        _playButton(
          theme: theme,
          label: 'PLAY  •  ${size}×${size}',
          onTap: () => _navigateToGame(gs),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _backRow(AppTheme theme, String label) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _panel = _Panel.none),
          child: Icon(Icons.arrow_back_ios, color: theme.textSecondary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            color: theme.textSecondary, fontSize: 10, letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _playButton({
    required AppTheme theme,
    required String   label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          foregroundColor: theme.isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 3,
          ),
        ),
      ),
    );
  }

  void _navigateToGame(GameState gs) {
    gs.startGame();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    ).then((_) => setState(() => _panel = _Panel.none));
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String       emoji, label, sub;
  final AppTheme     theme;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.gridLine),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: theme.textPrimary, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.spaceMono(
                color: theme.textSecondary, fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini preview ──────────────────────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  final AppTheme theme;
  const _MiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    const n = 4;
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
      width: 130, height: 130,
      child: Container(
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.gridLine),
        ),
        child: LayoutBuilder(builder: (ctx, c) {
          final cell = c.maxWidth / n;
          return Stack(
            children: [
              CustomPaint(
                size: Size(c.maxWidth, c.maxWidth),
                painter: _MiniGrid(n: n, color: theme.gridLine),
              ),
              ...arrows.map((a) {
                final (col, row, dir) = a;
                return Positioned(
                  left: col * cell, top: row * cell,
                  child: SizedBox(
                    width: cell, height: cell,
                    child: CustomPaint(
                      painter: _MiniArrow(dir: dir, color: theme.arrowColor(dir)),
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
  final int n; final Color color;
  _MiniGrid({required this.n, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p    = Paint()..color = color..strokeWidth = 0.5;
    final cell = size.width / n;
    for (int i = 0; i <= n; i++) {
      canvas.drawLine(Offset(i*cell, 0), Offset(i*cell, size.height), p);
      canvas.drawLine(Offset(0, i*cell), Offset(size.width, i*cell), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _MiniArrow extends CustomPainter {
  final ArrowDirection dir; final Color color;
  _MiniArrow({required this.dir, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
    final cx = size.width/2; final cy = size.height/2;
    final len = size.width*0.28; final hw = size.width*0.14; final hl = size.width*0.18;
    late Offset tail, tip, wA, wB;
    switch (dir) {
      case ArrowDirection.up:
        tail=Offset(cx,cy+len); tip=Offset(cx,cy-len);
        wA=Offset(cx-hw,cy-len+hl); wB=Offset(cx+hw,cy-len+hl);
      case ArrowDirection.down:
        tail=Offset(cx,cy-len); tip=Offset(cx,cy+len);
        wA=Offset(cx-hw,cy+len-hl); wB=Offset(cx+hw,cy+len-hl);
      case ArrowDirection.left:
        tail=Offset(cx+len,cy); tip=Offset(cx-len,cy);
        wA=Offset(cx-len+hl,cy-hw); wB=Offset(cx-len+hl,cy+hw);
      case ArrowDirection.right:
        tail=Offset(cx-len,cy); tip=Offset(cx+len,cy);
        wA=Offset(cx+len-hl,cy-hw); wB=Offset(cx+len-hl,cy+hw);
    }
    canvas.drawLine(tail, tip, p);
    canvas.drawLine(tip, wA, p);
    canvas.drawLine(tip, wB, p);
  }
  @override bool shouldRepaint(_) => false;
}
