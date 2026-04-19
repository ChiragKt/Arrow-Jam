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

  @override
  void dispose() {
    for (final c in _flyCtrl.values)   c.dispose();
    for (final c in _shakeCtrl.values) c.dispose();
    super.dispose();
  }

  // ── Animation launchers ──────────────────────────────────────────────────

  void _startFly(int id, ArrowDirection dir) {
    _flyCtrl[id]?.dispose();
    _flyDone.remove(id);

    final ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 380),
    );

    // Fly distance: 2 full cells in the arrow's direction
    const dist = 2.0;
    final Offset end;
    switch (dir) {
      case ArrowDirection.up:    end = const Offset(0, -dist); break;
      case ArrowDirection.down:  end = const Offset(0,  dist); break;
      case ArrowDirection.left:  end = const Offset(-dist, 0); break;
      case ArrowDirection.right: end = const Offset( dist, 0); break;
    }

    _flySlide[id] = Tween<Offset>(begin: Offset.zero, end: end)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));

    _flyFade[id] = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(
          parent: ctrl,
          curve: const Interval(0.25, 0.88, curve: Curves.easeOut),
        ));

    _flyCtrl[id] = ctrl;
    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _flyDone.add(id);
        if (mounted) setState(() {});
      }
    });
    ctrl.forward();
  }

  void _startShake(int id) {
    _shakeCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 55),
    );
    _shakeCtrl[id] = ctrl;
    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 330), () {
      ctrl.stop();
      ctrl.reset();
      if (mounted) setState(() {});
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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Grid lines
            CustomPaint(
              size: Size(totalSize, totalSize),
              painter: _GridPainter(n: n, lineColor: theme.gridLine),
            ),
            // Arrows
            ...gs.arrows.map((arrow) {
              // Fully done — hide immediately
              if (arrow.cleared && _flyDone.contains(arrow.id)) {
                return const SizedBox.shrink();
              }
              if (arrow.cleared && _flyCtrl[arrow.id] == null) {
                return const SizedBox.shrink();
              }
              return _buildArrowTile(arrow, cellSize, n, theme);
            }),
          ],
        );
      }),
    );
  }

  Widget _buildArrowTile(Arrow arrow, double cellSize, int n, AppTheme theme) {
    // ── Geometry ────────────────────────────────────────────────────────────
    //
    // The arrow's body extends from the HEAD backwards (opposite to direction).
    // We need the top-left corner of the bounding rectangle, plus its pixel size.
    //
    // For a horizontal arrow (left/right): width = length×cell, height = cell
    // For a vertical   arrow (up/down):    width = cell,         height = length×cell

    final isHorizontal = arrow.direction == ArrowDirection.left ||
                         arrow.direction == ArrowDirection.right;

    // Find the top-left cell of the bounding box
    final headC = arrow.col;
    final headR = arrow.row;

    int minC = headC, minR = headR;
    // Body extends backward: step opposite to direction (length-1) times
    int bc = headC, br = headR;
    for (int i = 1; i < arrow.length; i++) {
      switch (arrow.direction) {
        case ArrowDirection.up:    br++; break;
        case ArrowDirection.down:  br--; break;
        case ArrowDirection.left:  bc++; break;
        case ArrowDirection.right: bc--; break;
      }
    }
    minC = headC < bc ? headC : bc;
    minR = headR < br ? headR : br;

    final double left = minC * cellSize;
    final double top  = minR * cellSize;
    final double w    = isHorizontal ? arrow.length * cellSize : cellSize;
    final double h    = isHorizontal ? cellSize : arrow.length * cellSize;

    // ── Animations ──────────────────────────────────────────────────────────
    final shakeCtrl   = _shakeCtrl[arrow.id];
    final shakeOffset = (shakeCtrl != null && shakeCtrl.isAnimating)
        ? (shakeCtrl.value - 0.5) * 6.0
        : 0.0;

    final flyCtrl  = _flyCtrl[arrow.id];
    final flySlide = _flySlide[arrow.id];
    final flyFade  = _flyFade[arrow.id];
    final isFlying = flyCtrl != null && flyCtrl.isAnimating;

    Offset slideOffset = Offset.zero;
    if (isFlying && flySlide != null) {
      final frac = flySlide.value;
      slideOffset = Offset(frac.dx * cellSize, frac.dy * cellSize);
    }

    double opacity = 1.0;
    if (isFlying && flyFade != null) {
      opacity = flyFade.value.clamp(0.0, 1.0);
    } else if (_flyDone.contains(arrow.id)) {
      opacity = 0.0;
    }

    return Positioned(
      key:  ValueKey(arrow.id),
      left: left + slideOffset.dx + shakeOffset,
      top:  top  + slideOffset.dy,
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
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width:  w,
            height: h,
            child: CustomPaint(
              painter: ArrowPainter(
                direction: arrow.direction,
                color:     widget.theme.arrowColor(arrow.direction),
                opacity:   1.0,
                length:    arrow.length,
                cellSize:  cellSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid painter ─────────────────────────────────────────────────────────────

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
      canvas.drawLine(Offset(pos, 0),           Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos),           Offset(size.width, pos),  paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.n != n || old.lineColor != lineColor;
}
