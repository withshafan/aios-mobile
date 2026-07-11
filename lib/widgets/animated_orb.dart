import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/nova_theme.dart';

class AnimatedOrb extends StatefulWidget {
  final double size;
  final bool isActive;

  const AnimatedOrb({super.key, this.size = 120, this.isActive = false});

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _OrbPainter(
            animationValue: _controller.value,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double animationValue;
  final bool isActive;

  _OrbPainter({required this.animationValue, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          NovaColors.accent.withOpacity(isActive ? 0.3 : 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // Main orb
    final orbPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          NovaColors.accentGradientStart,
          NovaColors.accentGradientEnd,
          NovaColors.accentGradientStart,
        ],
        transform: GradientRotation(animationValue * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.7, orbPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
        radius: radius * 0.3,
      ));
    canvas.drawCircle(center, radius * 0.7, highlightPaint);

    // Pulsing ring
    final ringPaint = Paint()
      ..color = NovaColors.accent.withOpacity(0.2 + sin(animationValue * 2 * pi) * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * (0.85 + sin(animationValue * 4 * pi) * 0.05), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
