import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'onboarding_screen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _treeController;
  late AnimationController _ringController;
  late AnimationController _textFade;

  int _quoteIndex = 0;

  final List<String> _quotes = [
    'Growing a cleaner planet…',
    'Sorting your waste…',
    'Planting seeds for a greener future…',
  ];

  @override
  void initState() {
    super.initState();

    // Tree animation (plays once — not looping)
    _treeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Smooth progress ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Text fade animation
    _textFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    // Quote rotation (lightweight)
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return false;

      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      });

      _textFade.forward(from: 0);
      return true;
    });

    // Navigate forward
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _treeController.dispose();
    _ringController.dispose();
    _textFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      body: Stack(
        children: [
          // LIGHTER, more premium leaf background
          Positioned.fill(
            child: CustomPaint(
              painter: SoftLeafBackground(),
            ),
          ),

          // MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tree + ring
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft animated ring
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(180, 180),
                            painter: SmoothRingPainter(
                              progress: _ringController.value,
                            ),
                          );
                        },
                      ),

                      // Tree Lottie (no looping → lightweight)
                      Lottie.asset(
                        "assets/animations/tree_grow.json",
                        controller: _treeController,
                        width: 130,
                        height: 130,
                        onLoaded: (comp) {
                          _treeController.duration = comp.duration;
                        },
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                const Text(
                  "Trash & Cash",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF2E7D32),
                  ),
                ),

                const SizedBox(height: 40),

                // Clean fade quotes
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    _quotes[_quoteIndex],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A3A3A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 10),

                // Micro text
                const Text(
                  "Preparing your experience...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ★★★★★ IMPROVED RING PAINTER
//
class SmoothRingPainter extends CustomPainter {
  final double progress;

  SmoothRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;

    final ringPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SmoothRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

//
// ★★★★★ SOFTER BACKGROUND LEAFS
//
class SoftLeafBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Paint()..color = const Color(0xFF4CAF50).withOpacity(0.06);

    _drawLeaf(canvas, size, const Offset(30, 40), 40, leaf);
    _drawLeaf(canvas, size, Offset(size.width - 60, size.height - 50), 45, leaf);
  }

  void _drawLeaf(Canvas canvas, Size size, Offset offset, double scale, Paint p) {
    final path = Path()
      ..moveTo(offset.dx, offset.dy)
      ..quadraticBezierTo(
          offset.dx + scale, offset.dy - scale, offset.dx + (scale * 1.4), offset.dy)
      ..quadraticBezierTo(offset.dx + scale, offset.dy + scale, offset.dx, offset.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
