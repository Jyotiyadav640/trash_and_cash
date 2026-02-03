import 'package:flutter/material.dart';
import 'dart:math' as math;

class TreeGrowingAnimation extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;
  final double size;

  const TreeGrowingAnimation({
    super.key,
    this.duration = const Duration(seconds: 5),
    this.onComplete,
    this.size = 120,
  });

  @override
  State<TreeGrowingAnimation> createState() => _TreeGrowingAnimationState();
}

class _TreeGrowingAnimationState extends State<TreeGrowingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _sproutProgress;
  late Animation<double> _leavesProgress;
  late Animation<double> _treeProgress;
  late Animation<double> _particlesProgress;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Stage 1: Sprout (0.0 - 0.2 of total duration)
    _sproutProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.elasticOut),
      ),
    );

    // Stage 2: Leaves growing (0.15 - 0.5 of total duration, overlaps sprout)
    _leavesProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 3: Full tree form (0.4 - 0.8 of total duration)
    _treeProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuad),
      ),
    );

    // Particles float throughout (0.2 - 1.0)
    _particlesProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.linear),
      ),
    );

    _mainController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return CustomPaint(
              painter: TreeAnimationPainter(
                sproutProgress: _sproutProgress.value,
                leavesProgress: _leavesProgress.value,
                treeProgress: _treeProgress.value,
                particlesProgress: _particlesProgress.value,
                size: widget.size,
              ),
              size: Size(widget.size, widget.size),
            );
          },
        ),
      ),
    );
  }
}

class TreeAnimationPainter extends CustomPainter {
  final double sproutProgress;
  final double leavesProgress;
  final double treeProgress;
  final double particlesProgress;
  final double size;

  TreeAnimationPainter({
    required this.sproutProgress,
    required this.leavesProgress,
    required this.treeProgress,
    required this.particlesProgress,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseY = size.height * 0.75;

    // 🌍 Draw ground line
    _drawGround(canvas, size, baseY);

    // 🌱 Stage 1: Draw sprout
    _drawSprout(canvas, center, baseY, sproutProgress);

    // 🍃 Stage 2: Draw leaves
    _drawLeaves(canvas, center, baseY, leavesProgress);

    // 🌳 Stage 3: Draw tree crown
    _drawTreeCrown(canvas, center, baseY, treeProgress);

    // ✨ Draw floating particles
    _drawFloatingParticles(canvas, size, center, particlesProgress);

    // 💫 Draw glow effect
    if (treeProgress > 0.3) {
      _drawGlowEffect(canvas, center, baseY, treeProgress);
    }
  }

  void _drawGround(Canvas canvas, Size size, double baseY) {
    final paint = Paint()
      ..color = const Color(0xFF8BC34A).withOpacity(0.2)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.2, baseY),
      Offset(size.width * 0.8, baseY),
      paint,
    );

    // Soil dots
    final soilPaint = Paint()
      ..color = const Color(0xFF6B4423).withOpacity(0.3);

    for (int i = 0; i < 8; i++) {
      final x = size.width * 0.2 + (i * size.width * 0.075);
      canvas.drawCircle(Offset(x, baseY + 4), 1.5, soilPaint);
    }
  }

  void _drawSprout(Canvas canvas, Offset center, double baseY, double progress) {
    if (progress == 0) return;

    final sproutHeight = size * 0.12 * progress;
    final trunkWidth = size * 0.02;

    // Trunk
    final trunkPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF8B7355),
        const Color(0xFF6B5344),
        progress,
      )!
      ..strokeWidth = trunkWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, baseY),
      Offset(center.dx, baseY - sproutHeight),
      trunkPaint,
    );

    // Small leaf
    if (progress > 0.5) {
      final leafScale = (progress - 0.5) * 2;
      _drawLeafShape(
        canvas,
        Offset(center.dx - size * 0.03 * leafScale, baseY - sproutHeight * 0.8),
        size * 0.015 * leafScale,
        -30,
        const Color(0xFF8BC34A),
      );
    }
  }

  void _drawLeaves(Canvas canvas, Offset center, double baseY, double progress) {
    if (progress == 0) return;

    final trunkHeight = size * 0.12;
    const leafCount = 5;

    for (int i = 0; i < leafCount; i++) {
      final angle = (i * 360 / leafCount) + (progress * 15);
      final leafScale = math.sin(progress * math.pi) * 1.1;
      final distance = size * 0.05 * progress;

      final radiusX = distance * math.cos((angle * math.pi) / 180);
      final radiusY = distance * math.sin((angle * math.pi) / 180) * 0.5;

      final leafPos = Offset(
        center.dx + radiusX,
        baseY - trunkHeight * 0.6 + radiusY,
      );

      final leafColor = Color.lerp(
        const Color(0xFF9CCC65),
        const Color(0xFF7CB342),
        progress,
      )!;

      _drawLeafShape(
        canvas,
        leafPos,
        size * 0.02 * leafScale,
        angle,
        leafColor,
      );
    }
  }

  void _drawTreeCrown(Canvas canvas, Offset center, double baseY, double progress) {
    if (progress == 0) return;

    final trunkHeight = size * 0.12;
    final crowHeight = size * 0.25 * progress;
    final crowWidth = size * 0.20 * progress;

    final trunkPaint = Paint()
      ..color = const Color(0xFF6B4423)
      ..strokeWidth = size * 0.025
      ..strokeCap = StrokeCap.round;

    // Main trunk
    canvas.drawLine(
      Offset(center.dx, baseY),
      Offset(center.dx, baseY - trunkHeight),
      trunkPaint,
    );

    // Tree crown - rounded shape
    final crownPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF9CCC65),
        const Color(0xFF558B2F),
        progress * 0.5,
      )!
      ..style = PaintingStyle.fill;

    // Main circle (top)
    canvas.drawCircle(
      Offset(center.dx, baseY - trunkHeight - crowHeight * 0.3),
      crowWidth * 0.6 * progress,
      crownPaint,
    );

    // Left side
    canvas.drawCircle(
      Offset(center.dx - crowWidth * 0.3, baseY - trunkHeight + crowHeight * 0.1),
      crowWidth * 0.5 * progress,
      crownPaint,
    );

    // Right side
    canvas.drawCircle(
      Offset(center.dx + crowWidth * 0.3, baseY - trunkHeight + crowHeight * 0.1),
      crowWidth * 0.5 * progress,
      crownPaint,
    );

    // Bottom fill
    canvas.drawCircle(
      Offset(center.dx, baseY - trunkHeight + crowHeight * 0.25),
      crowWidth * 0.45 * progress,
      crownPaint,
    );
  }

  void _drawLeafShape(
    Canvas canvas,
    Offset position,
    double size,
    double rotation,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate((rotation * math.pi) / 180);

    // Leaf shape - oval with pointed end
    final path = Path();
    path.moveTo(0, -size);
    path.quadraticBezierTo(-size * 0.6, -size * 0.4, -size * 0.5, size * 0.5);
    path.quadraticBezierTo(0, size * 0.8, size * 0.5, size * 0.5);
    path.quadraticBezierTo(size * 0.6, -size * 0.4, 0, -size);
    path.close();

    canvas.drawPath(path, paint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = size * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, -size),
      Offset(0, size * 0.7),
      veinPaint,
    );

    canvas.restore();
  }

  void _drawFloatingParticles(
    Canvas canvas,
    Size size,
    Offset center,
    double progress,
  ) {
    if (progress < 0.1) return;

    const particleCount = 12;
    final particlePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 360 / particleCount) * (math.pi / 180);
      final speed = 0.3 + (i * 0.05);
      final adjustedProgress = (progress - 0.1) * speed;

      if (adjustedProgress < 0) continue;

      final distance = size.width * 0.15 * adjustedProgress;
      final upwardMotion = size.height * 0.2 * adjustedProgress;

      final particleX = center.dx + distance * math.cos(angle);
      final particleY = center.dy - upwardMotion + distance * math.sin(angle);

      final opacity = math.sin(adjustedProgress * math.pi).clamp(0.0, 1.0);
      final particleRadiusValue = size.width * 0.01 * opacity;

      particlePaint.color =
          const Color(0xFF8BC34A).withOpacity(opacity * 0.6);

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleRadiusValue,
        particlePaint,
      );
    }
  }

  void _drawGlowEffect(
    Canvas canvas,
    Offset center,
    double baseY,
    double progress,
  ) {
    final glowPaint = Paint()
      ..color = const Color(0xFF8BC34A).withOpacity(0.15 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    final trunkHeight = size * 0.12;
    canvas.drawCircle(
      Offset(center.dx, baseY - trunkHeight - size * 0.05),
      size * 0.2 * progress,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(TreeAnimationPainter oldDelegate) {
    return oldDelegate.sproutProgress != sproutProgress ||
        oldDelegate.leavesProgress != leavesProgress ||
        oldDelegate.treeProgress != treeProgress ||
        oldDelegate.particlesProgress != particlesProgress;
  }
}
