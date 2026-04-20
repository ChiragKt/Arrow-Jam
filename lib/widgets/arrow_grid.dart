import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';
import 'arrow_painter.dart';

class ArrowGrid extends StatefulWidget {
  final GameState gs;
  final AppTheme  theme;
  final void Function(int arrowId) onTap;

  const ArrowGrid({
    super.key,
    required this.gs,
    required this.theme,
    required this.onTap,
  });

  @override
  State<ArrowGrid> createState() => _ArrowGridState();
}

class _ArrowGridState extends State<ArrowGrid> with TickerProviderStateMixin {
  final Map<int, AnimationController> _flyCtrl   = {};
  final Map<int, Animation<Offset>>   _flySlide  = {};
  final Map<int, Animation<double>>   _flyFade   = {};
  final Map<int, AnimationController> _shakeCtrl = {};
  final Set<int>                      _flyDone   = {};

  int? _lastLevel;
  int? _lastGeneration;

  @override
  void initState() {
    super.initState();
    _lastLevel      = widget.gs.level;
    _lastGeneration = widget.gs.generation;
  }

  @override
  void didUpdateWidget(ArrowGrid old) {
    super.didUpdateWidget(old);
    final lvl = widget.gs.level;
    final gen = widget.gs.generation;
    if (lvl != _lastLevel || gen != _lastGeneration) {
      _clearAll();
      _lastLevel      = lvl;
      _lastGeneration = gen;
    }
  }

  void _clearAll() {
    for (final c in _flyCtrl.values)   c.dispose();
    for (final c in _shakeCtrl.values) c.dispose();
    _flyCtrl.clear();
    _flySlide.clear();
    _flyFade.clear();
    _shakeCtrl.clear();
    _flyDone.clear();
  }

  @override
  void dispose() {
    _clearAll();
    super.dispose();
  }

  // ── Fly animation ────────────────────────────────────────────────────────

  void _startFly(int id, ArrowDirection dir) {
    _flyCtrl[id]?.dispose();
    _flyDone.remove(id);

    final ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 420),
    );

    const dist = 2.5;
    final Offset end = switch (dir) {
      ArrowDirection.up    => const Offset(0, -dist),
      ArrowDirection.down  => const Offset(0,  dist),
      ArrowDirection.left  => const Offset(-dist, 0),
      ArrowDirection.right => const Offset( dist, 0),
    };

    _flySlide[id] = Tween<Offset>(begin: Offset.zero, end: end)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));
    _flyFade[id]  = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _flyCtrl[id]  = ctrl;

    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _flyDone.add(id);
        _flyCtrl[id]?.dispose();
        _flyCtrl.remove(id);
        _flySlide.remove(id);
        _flyFade.remove(id);
        if (mounted) setState(() {});
      }
    });
    ctrl.forward();
  }

  // ── Shake animation ──────────────────────────────────────────────────────

  void _startShake(int id) {
    _shakeCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 60),
    );
    _shakeCtrl[id] = ctrl;
    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      ctrl.stop();
      ctrl.reset();
      _shakeCtrl.remove(id);
      setState(() {});
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gs    = widget.gs;
    final theme = widget.theme;
    final n     = gs.gridSize;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final totalSize = constraints.maxWidth;
        final cellSize  = totalSize / n;

        // Visible arrows (not yet fully done)
        final visible = gs.arrows.where((a) =>
          !_flyDone.contains(a.id) &&
          !(a.cleared && _flyCtrl[a.id] == null)
        ).toList();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Grid lines ─────────────────────────────────────────────────
            CustomPaint(
              size: Size(totalSize, totalSize),
              painter: _GridPainter(n: n, lineColor: theme.gridLine),
            ),

            // ── Snake bodies (drawn on full-grid canvas, behind hit areas) ─
            // One CustomPaint per arrow, each covering the entire grid so
            // the snake polyline can span multiple cells without clipping.
            ...visible.map((arrow) {
              final isFlying  = _flyCtrl[arrow.id]?.isAnimating == true;
              final flySlide  = _flySlide[arrow.id];
              final flyFade   = _flyFade[arrow.id];
              final shakeCtrl = _shakeCtrl[arrow.id];

              Offset slideOffset = Offset.zero;
              if (isFlying && flySlide != null) {
                final frac = flySlide.value;
                slideOffset = Offset(frac.dx * cellSize, frac.dy * cellSize);
              }

              final double shakeOffset = (shakeCtrl != null && shakeCtrl.isAnimating)
                  ? (shakeCtrl.value - 0.5) * 8.0
                  : 0.0;

              final double opacity;
              if (isFlying && flyFade != null) {
                opacity = flyFade.value.clamp(0.0, 1.0);
              } else if (_flyDone.contains(arrow.id)) {
                opacity = 0.0;
              } else {
                opacity = 1.0;
              }

              return Positioned(
                key:    ValueKey('body_${arrow.id}'),
                left:   slideOffset.dx + shakeOffset,
                top:    slideOffset.dy,
                width:  totalSize,
                height: totalSize,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: opacity,
                    child: CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: SnakeArrowPainter(
                        arrow:    arrow,
                        color:    theme.arrowColor(arrow.direction),
                        opacity:  1.0,
                        cellSize: cellSize,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ── Per-cell hit targets ────────────────────────────────────────
            // One GestureDetector per cell of each visible snake.
            // All cells of the same arrow route taps to the same handler.
            ...visible.expand((arrow) {
              final isFlying = _flyCtrl[arrow.id]?.isAnimating == true;
              return arrow.cells.map((cell) => Positioned(
                key:    ValueKey('hit_${arrow.id}_${cell.col}_${cell.row}'),
                left:   cell.col * cellSize,
                top:    cell.row * cellSize,
                width:  cellSize,
                height: cellSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: (arrow.cleared || arrow.animating || isFlying)
                      ? null
                      : () {
                          final result = widget.gs.tapArrow(arrow.id, () {
                            if (mounted) setState(() {});
                          });
                          if (result == TapResult.cleared) {
                            _startFly(arrow.id, arrow.direction);
                          } else if (result == TapResult.collision) {
                            _startShake(arrow.id);
                          }
                        },
                ),
              ));
            }),
          ],
        );
      }),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final int   n;
  final Color lineColor;
  _GridPainter({required this.n, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = lineColor
      ..strokeWidth = 0.8;
    final cell = size.width / n;
    for (int i = 0; i <= n; i++) {
      final pos = i * cell;
      canvas.drawLine(Offset(pos, 0),     Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0,   pos),   Offset(size.width, pos),  paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.n != n || old.lineColor != lineColor;
}
