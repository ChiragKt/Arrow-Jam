import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/arrow_model.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';
import '../widgets/arrow_widget.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;
  final int startLives;
  final int startScore;
  const GameScreen({super.key, this.startLevel = 1, this.startLives = 3, this.startScore = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gs;
  final Map<int, AnimationController> _slideCtrl = {};
  final Map<int, Animation<Offset>> _slideAnim = {};
  final Set<int> _slidingIds = {};

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initGameState(widget.startLevel, widget.startLives, widget.startScore);
  }

  void _initGameState(int level, int lives, int score) {
    final size = GameState.gridSizeForLevel(level);
    final count = GameState.arrowCountForLevel(level);
    final puzzle = generatePuzzle(size, count, seed: level * 37 + 13);
    _gs = GameState(lives: lives, level: level, score: score, puzzle: puzzle);
  }

  void _loadLevel(int level, {int? lives, int? score}) {
    _slideCtrl.forEach((_, c) => c.dispose());
    _slideCtrl.clear();
    _slideAnim.clear();
    _slidingIds.clear();

    final l = lives ?? _gs.lives;
    final s = score ?? _gs.score;
    final size = GameState.gridSizeForLevel(level);
    final count = GameState.arrowCountForLevel(level);
    final puzzle = generatePuzzle(size, count, seed: level * 37 + 13);

    setState(() {
      _gs = GameState(lives: l, level: level, score: s, puzzle: puzzle);
    });
  }

  GameTheme get _theme => AppThemes.forLevel(_gs.level);

  double _cellSize(BuildContext context) {
    final available = MediaQuery.of(context).size.width - 48;
    return (available / _gs.puzzle.size).clamp(32.0, 80.0);
  }

  void _onTapArrow(BuildContext context, ArrowCell arrow) {
    if (_gs.isGameOver || _gs.isLevelWon) return;
    if (_slidingIds.contains(arrow.id)) return;

    if (_gs.puzzle.canFree(arrow)) {
      HapticFeedback.lightImpact();
      _startSlide(context, arrow);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        arrow.blocked = true;
        _gs.lives--;
        if (_gs.lives <= 0) _gs.isGameOver = true;
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() => arrow.blocked = false);
      });
    }
  }

  void _startSlide(BuildContext context, ArrowCell arrow) {
    final cs = _cellSize(context);
    final size = _gs.puzzle.size;

    int steps = 0;
    int r = arrow.row + arrow.dir.dr;
    int c = arrow.col + arrow.dir.dc;
    while (r >= 0 && r < size && c >= 0 && c < size) {
      steps++;
      r += arrow.dir.dr;
      c += arrow.dir.dc;
    }
    steps++;

    final totalDx = arrow.dir.dc * (steps * cs);
    final totalDy = arrow.dir.dr * (steps * cs);

    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 160 + steps * 55),
    );
    final anim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(totalDx, totalDy),
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));

    _slideCtrl[arrow.id] = ctrl;
    _slideAnim[arrow.id] = anim;

    setState(() {
      _slidingIds.add(arrow.id);
      arrow.sliding = true;
    });

    ctrl.forward().then((_) {
      if (!mounted) return;
      setState(() {
        arrow.freed = true;
        arrow.sliding = false;
        _slidingIds.remove(arrow.id);
        _gs.score += 10;
        if (_gs.puzzle.isSolved) {
          _gs.isLevelWon = true;
          HapticFeedback.heavyImpact();
        }
      });
      ctrl.dispose();
      _slideCtrl.remove(arrow.id);
      _slideAnim.remove(arrow.id);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.background,
      body: SafeArea(
        child: _gs.isGameOver
            ? _buildGameOver()
            : _gs.isLevelWon
                ? _buildLevelWon()
                : _buildGame(context),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final cs = _cellSize(context);
    final puzzle = _gs.puzzle;
    final t = _theme;

    return Column(
      children: [
        _buildTopBar(t),
        const SizedBox(height: 10),
        Text(
          'Tap an arrow to release it — blocked path = lost life!',
          style: GoogleFonts.dmMono(color: t.textSecondary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: ClipRect(
              child: SizedBox(
                width: cs * puzzle.size,
                height: cs * puzzle.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Grid
                    CustomPaint(
                      size: Size(cs * puzzle.size, cs * puzzle.size),
                      painter: _GridPainter(size: puzzle.size, cellSize: cs, theme: t),
                    ),
                    // Static arrows
                    for (final arrow in puzzle.arrows)
                      if (!arrow.freed && !_slidingIds.contains(arrow.id))
                        Positioned(
                          left: arrow.col * cs + cs * 0.10,
                          top: arrow.row * cs + cs * 0.10,
                          child: ArrowWidget(
                            key: ValueKey(arrow.id),
                            arrow: arrow,
                            cellSize: cs,
                            theme: t,
                            onTap: () => _onTapArrow(context, arrow),
                          ),
                        ),
                    // Sliding arrows
                    for (final arrow in puzzle.arrows)
                      if (_slidingIds.contains(arrow.id) && _slideAnim.containsKey(arrow.id))
                        AnimatedBuilder(
                          animation: _slideAnim[arrow.id]!,
                          builder: (_, __) => Positioned(
                            left: arrow.col * cs + cs * 0.10 + _slideAnim[arrow.id]!.value.dx,
                            top: arrow.row * cs + cs * 0.10 + _slideAnim[arrow.id]!.value.dy,
                            child: _SlidingArrow(
                              dir: arrow.dir,
                              cellSize: cs,
                              theme: t,
                              progress: _slideCtrl[arrow.id]!.value,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildBottomBar(context, t),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopBar(GameTheme t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: t.cellBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.gridLine, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCol(t, 'LEVEL', '${_gs.level}'),
          _statCol(t, 'SCORE', '${_gs.score}'),
          _livesRow(t),
          _statCol(t, 'LEFT', '${_gs.puzzle.active.length}'),
        ],
      ),
    );
  }

  Widget _statCol(GameTheme t, String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: GoogleFonts.dmMono(fontSize: 9, color: t.textSecondary, letterSpacing: 1.5)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.dmMono(fontSize: 20, color: t.textPrimary, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _livesRow(GameTheme t) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('LIVES', style: GoogleFonts.dmMono(fontSize: 9, color: t.textSecondary, letterSpacing: 1.5)),
      const SizedBox(height: 4),
      Row(children: List.generate(3, (i) => AnimatedScale(
        scale: i < _gs.lives ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 250),
        child: Text(i < _gs.lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 15)),
      ))),
    ],
  );

  Widget _buildBottomBar(BuildContext context, GameTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionBtn(t, Icons.refresh_rounded, 'Restart', () => _loadLevel(_gs.level, lives: _gs.lives, score: _gs.score)),
          _actionBtn(t, Icons.skip_next_rounded, 'Skip (-1❤️)', () {
            if (_gs.lives <= 1) {
              setState(() { _gs.lives = 0; _gs.isGameOver = true; });
            } else {
              _loadLevel(_gs.level, lives: _gs.lives - 1, score: _gs.score);
            }
          }),
          _actionBtn(t, Icons.home_rounded, 'Menu', () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _actionBtn(GameTheme t, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.cellBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.gridLine),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: t.textSecondary, size: 20),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmMono(fontSize: 9, color: t.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildOverlay({
    required String emoji, required String title, required String sub,
    required String btnLabel, required VoidCallback onBtn,
  }) {
    final t = _theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _pulseAnim, child: Text(emoji, style: const TextStyle(fontSize: 72))),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.dmMono(fontSize: 28, fontWeight: FontWeight.bold, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text(sub, style: GoogleFonts.dmMono(fontSize: 14, color: t.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onBtn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              decoration: BoxDecoration(
                color: t.uiAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: t.uiAccent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Text(btnLabel, style: GoogleFonts.dmMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLevelWon() => _buildOverlay(
    emoji: '🎉', title: 'Cleared!',
    sub: 'Level ${_gs.level} done!\nScore: ${_gs.score}',
    btnLabel: 'Next Level →',
    onBtn: () => _loadLevel(_gs.level + 1, lives: _gs.lives, score: _gs.score),
  );

  Widget _buildGameOver() => _buildOverlay(
    emoji: '💀', title: 'Jammed!',
    sub: 'Traffic got the best of you.\nFinal score: ${_gs.score}',
    btnLabel: 'Try Again',
    onBtn: () => _loadLevel(_gs.level, lives: 3, score: 0),
  );
}

class _GridPainter extends CustomPainter {
  final int size;
  final double cellSize;
  final GameTheme theme;
  _GridPainter({required this.size, required this.cellSize, required this.theme});

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..color = theme.background);
    final lp = Paint()..color = theme.gridLine..strokeWidth = 0.8;
    for (int i = 0; i <= size; i++) {
      final v = i * cellSize;
      canvas.drawLine(Offset(v, 0), Offset(v, s.height), lp);
      canvas.drawLine(Offset(0, v), Offset(s.width, v), lp);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _SlidingArrow extends StatelessWidget {
  final ArrowDir dir;
  final double cellSize;
  final GameTheme theme;
  final double progress;
  const _SlidingArrow({required this.dir, required this.cellSize, required this.theme, required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = cellSize;
    final t = theme;
    final opacity = (1.0 - progress * 0.9).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: cs * 0.80,
        height: cs * 0.80,
        decoration: BoxDecoration(
          color: t.freedColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(cs * 0.16),
          border: Border.all(color: t.freedColor.withOpacity(0.7), width: 1.5),
          boxShadow: [BoxShadow(color: t.freedColor.withOpacity(0.35), blurRadius: 14, spreadRadius: 1)],
        ),
        child: Center(
          child: CustomPaint(
            size: Size(cs * 0.44, cs * 0.44),
            painter: _ArrowBodyPainter(dir: dir, color: t.freedColor),
          ),
        ),
      ),
    );
  }
}

class _ArrowBodyPainter extends CustomPainter {
  final ArrowDir dir;
  final Color color;
  _ArrowBodyPainter({required this.dir, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = sw / 2, cy = size.height / 2;
    final shaft = sw * 0.36;
    final headLen = sw * 0.30;
    const headAngle = 0.44;

    double tx = cx, ty = cy, bx = cx, by = cy, angle = 0.0;
    switch (dir) {
      case ArrowDir.up:    ty = cy - shaft; by = cy + shaft * 0.35; angle = -math.pi / 2; break;
      case ArrowDir.down:  ty = cy + shaft; by = cy - shaft * 0.35; angle = math.pi / 2; break;
      case ArrowDir.left:  tx = cx - shaft; bx = cx + shaft * 0.35; angle = math.pi; break;
      case ArrowDir.right: tx = cx + shaft; bx = cx - shaft * 0.35; angle = 0; break;
    }

    canvas.drawLine(Offset(bx, by), Offset(tx, ty), paint);
    final path = Path()
      ..moveTo(tx + math.cos(angle + math.pi - headAngle) * headLen,
               ty + math.sin(angle + math.pi - headAngle) * headLen)
      ..lineTo(tx, ty)
      ..lineTo(tx + math.cos(angle + math.pi + headAngle) * headLen,
               ty + math.sin(angle + math.pi + headAngle) * headLen);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowBodyPainter old) => old.dir != dir || old.color != color;
}
