import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_model.dart';
import '../themes/app_themes.dart';

class ArrowWidget extends StatefulWidget {
  final ArrowCell arrow;
  final double cellSize;
  final GameTheme theme;
  final VoidCallback onTap;

  const ArrowWidget({
    super.key,
    required this.arrow,
    required this.cellSize,
    required this.theme,
    required this.onTap,
  });

  @override
  State<ArrowWidget> createState() => _ArrowWidgetState();
}

class _ArrowWidgetState extends State<ArrowWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(ArrowWidget old) {
    super.didUpdateWidget(old);
    if (widget.arrow.blocked && !old.arrow.blocked) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cellSize;
    final t = widget.theme;
    final isBlocked = widget.arrow.blocked;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) => Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: cs * 0.80,
          height: cs * 0.80,
          decoration: BoxDecoration(
            color: isBlocked ? t.blockedColor.withOpacity(0.15) : t.cellBg,
            borderRadius: BorderRadius.circular(cs * 0.16),
            border: Border.all(
              color: isBlocked ? t.blockedColor : t.arrowBorder,
              width: isBlocked ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isBlocked ? t.blockedColor.withOpacity(0.45) : t.arrowColor.withOpacity(0.07),
                blurRadius: isBlocked ? 12 : 3,
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: Size(cs * 0.44, cs * 0.44),
              painter: _ArrowPainter(
                dir: widget.arrow.dir,
                color: isBlocked ? t.blockedColor : t.arrowColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final ArrowDir dir;
  final Color color;
  _ArrowPainter({required this.dir, required this.color});

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
      case ArrowDir.down:  ty = cy + shaft; by = cy - shaft * 0.35; angle =  math.pi / 2; break;
      case ArrowDir.left:  tx = cx - shaft; bx = cx + shaft * 0.35; angle =  math.pi;     break;
      case ArrowDir.right: tx = cx + shaft; bx = cx - shaft * 0.35; angle =  0;           break;
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
  bool shouldRepaint(_ArrowPainter old) => old.dir != dir || old.color != color;
}
