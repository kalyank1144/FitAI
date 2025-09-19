import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fitai/core/theme/tokens.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({super.key, required this.progress, this.size = 64});
  final double progress; // 0..1
  final double size;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppTokens.normal)..forward();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(progress: widget.progress * _a.value),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..color = AppTokens.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final fg = Paint()
      ..shader = AppTokens.perfGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawArc(rect.deflate(6), -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(rect.deflate(6), -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}