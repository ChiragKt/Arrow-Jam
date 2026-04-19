import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../themes/app_themes.dart';
import 'arrow_painter.dart';

class ArrowGrid extends StatefulWidget {
  final GameState gs;
  final AppTheme theme;
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
  final Map<int, AnimationController> _flyCtrl = {};
  final Map<int, Animation<Offset>> _flySlide = {};
  final Map<int, Animation<double>> _flyFade = {};
  final Map<int, AnimationController> _shakeCtrl = {};

  @override
  void dispose() {
    for (final c in _flyCtrl.values) { c.dispose(); }
    for (final c in _shakeCtrl.values) { c.dispose(); }
    super.dispose();
  }

  void _startFly(int id, ArrowDirection dir) {
    _flyCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    const dist = 2.5;
    Offset end;
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
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ));
    _flyCtrl[id] = ctrl;
    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.forward();
  }

  void _startShake(int id) {
    _shakeCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    _shakeCtrl[id] = ctrl;
    ctrl.addListener(() { if (mounted) setState(() {}); });
    ctrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 360), () {
      ctrl.stop();
      ctrl.reset();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final theme = widget.theme;
    final n = gs.gridSize;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (ctx, constraints) {
        final totalSize = constraints.maxWidth;
        final cellSize = totalSize / n;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(totalSize, totalSize),
              painter: _GridPainter(n: n, lineColor: theme.gridLine),
            ),
            ...gs.arrows.map((arrow) {
              if (arrow.cleared) {
                final ctrl = _flyCtrl[arrow.id];
                if (ctrl == null || !ctrl.isAnimating) {
                  return const SizedBox.shrink();
                }
              }
              return _buildArrowTile(arrow, cellSize, theme);
            }),
          ],
        );
      }),
    );
  }

  Widget _buildArrowTile(Arrow arrow, double cellSize, AppTheme theme) {
    final x = arrow.col * cellSize;
    final y = arrow.row * cellSize;

    final shakeCtrl = _shakeCtrl[arrow.id];
    final shakeOffset = (shakeCtrl != null && shakeCtrl.isAnimating)
        ? (shakeCtrl.value - 0.5) * 8.0
        : 0.0;

    final flySlide = _flySlide[arrow.id];
    final flyFade  = _flyFade[arrow.id];
    final flyCtrl  = _flyCtrl[arrow.id];
    final isFlying = flyCtrl != null && flyCtrl.isAnimating;

    Offset slideOffset = Offset.zero;
    if (isFlying && flySlide != null) {
      final frac = flySlide.value;
      slideOffset = Offset(frac.dx * cellSize, frac.dy * cellSize);
    }
    final opacity = (isFlying && flyFade != null) ? flyFade.value.clamp(0.0, 1.0) : 1.0;

    return Positioned(
      key: ValueKey(arrow.id),
      left: x + slideOffset.dx + shakeOffset,
      top:  y + slideOffset.dy,
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
            width: cellSize,
            height: cellSize,
            child: CustomPaint(
              painter: ArrowPainter(
                direction: arrow.direction,
                color: widget.theme.arrowColor(arrow.direction),
                opacity: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int n;
  final Color lineColor;
  _GridPainter({required this.n, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;
    final cell = size.width / n;
    for (int i = 0; i <= n; i++) {
      final pos = i * cell;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.n != n || old.lineColor != lineColor;
}
