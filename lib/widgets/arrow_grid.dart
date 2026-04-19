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
  // Per-arrow animation controllers keyed by arrow id
  final Map<int, AnimationController> _flyCtrl = {};
  final Map<int, Animation<Offset>> _flyAnim = {};
  final Map<int, AnimationController> _collCtrl = {};

  @override
  void dispose() {
    for (final c in _flyCtrl.values) { c.dispose(); }
    for (final c in _collCtrl.values) { c.dispose(); }
    super.dispose();
  }

  /// Call when an arrow is tapped and cleared — starts fly-out animation
  void _startFly(int id, ArrowDirection dir) {
    _flyCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Fly offset: move 2 full "grid units" in arrow direction
    const dist = 2.5;
    Offset begin = Offset.zero;
    Offset end;
    switch (dir) {
      case ArrowDirection.up:    end = const Offset(0, -dist); break;
      case ArrowDirection.down:  end = const Offset(0,  dist); break;
      case ArrowDirection.left:  end = const Offset(-dist, 0); break;
      case ArrowDirection.right: end = const Offset( dist, 0); break;
    }
    final anim = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: ctrl, curve: Curves.easeIn),
    );
    _flyCtrl[id] = ctrl;
    _flyAnim[id] = anim;
    ctrl.forward();
    ctrl.addListener(() => setState(() {}));
  }

  /// Call on collision — shake animation
  void _startShake(int id) {
    _collCtrl[id]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _collCtrl[id] = ctrl;
    ctrl.repeat(reverse: true);
    ctrl.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 360), () {
      ctrl.stop();
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
          children: [
            // Grid background
            CustomPaint(
              size: Size(totalSize, totalSize),
              painter: _GridPainter(n: n, lineColor: theme.gridLine),
            ),

            // Arrows
            ...gs.arrows.map((arrow) {
              if (arrow.cleared) {
                // Still render briefly during fly-out
                final flyCtrl = _flyCtrl[arrow.id];
                final flyAnim = _flyAnim[arrow.id];
                if (flyCtrl == null || !flyCtrl.isAnimating) return const SizedBox.shrink();
                return _buildArrowTile(arrow, cellSize, theme, flyAnim);
              }

              final flyAnim = arrow.animating ? _flyAnim[arrow.id] : null;
              return _buildArrowTile(arrow, cellSize, theme, flyAnim);
            }),
          ],
        );
      }),
    );
  }

  Widget _buildArrowTile(Arrow arrow, double cellSize, AppTheme theme, Animation<Offset>? flyAnim) {
    final x = arrow.col * cellSize;
    final y = arrow.row * cellSize;
    final isShaking = _collCtrl[arrow.id]?.isAnimating ?? false;
    final shakeVal = isShaking ? (_collCtrl[arrow.id]!.value - 0.5) * 6.0 : 0.0;
    final opacity = arrow.cleared ? 0.0 : 1.0;

    Widget arrowWidget = GestureDetector(
      onTap: arrow.cleared || arrow.animating
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
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: CustomPaint(
          painter: ArrowPainter(
            direction: arrow.direction,
            color: widget.theme.arrowColor(arrow.direction),
            opacity: opacity,
          ),
        ),
      ),
    );

    if (flyAnim != null) {
      arrowWidget = SlideTransition(
        position: flyAnim,
        child: FadeTransition(
          opacity: flyAnim.drive(
            Tween<double>(begin: 1.0, end: 0.0).chain(
              CurveTween(curve: const Interval(0.5, 1.0)),
            ),
          ),
          child: arrowWidget,
        ),
      );
    }

    return AnimatedPositioned(
      key: ValueKey(arrow.id),
      duration: Duration.zero,
      left: x + shakeVal,
      top: y,
      child: arrowWidget,
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
  bool shouldRepaint(_GridPainter old) => old.n != n || old.lineColor != lineColor;
}
