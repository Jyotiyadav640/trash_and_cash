import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_screen.dart';
import 'giver_home_screen.dart';
import 'collector_home_screen.dart';
import 'admin_home_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:trash_cash_fixed1/services/fcm_service.dart';

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

    // Navigate forward after a delay to show splash animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _handleNavigation();
      }
    });
  }

  Future<void> _handleNavigation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final uid = user.uid;

        // 1. Check if user is a Collector or Admin
        final collectorDoc = await FirebaseFirestore.instance
            .collection('collectorusers')
            .doc(uid)
            .get();

        if (collectorDoc.exists) {
          final isAdmin = collectorDoc.data()?['isAdmin'] == true;
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isAdmin ? const AdminHomeScreen() : const CollectorHomeScreen(),
              ),
            );
          }
          return;
        }

        // 2. Check if user is a Giver
        final giverDoc = await FirebaseFirestore.instance
            .collection('giverusers')
            .doc(uid)
            .get();

        if (giverDoc.exists) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GiverHomeScreen()),
            );
          }
          return;
        }

        // If user session exists but no role found in DB, something is wrong
        // Sign out and go to onboarding
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Session check error: $e');
      }
    }

    // Default: Go to Onboarding for new users or if not logged in
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
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
