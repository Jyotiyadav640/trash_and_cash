import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import 'package:camera/camera.dart';
import 'giver_home_screen.dart';
import '../services/ai_model_services.dart';
import 'camera_service.dart';

class AIScannerScreen extends StatefulWidget {
  const AIScannerScreen({super.key});

  @override
  State<AIScannerScreen> createState() => _AIScannerScreenState();
}
class AIResult {
  final String item;
  final String material;
  final bool recyclable;
  final int points;

  AIResult({
    required this.item,
    required this.material,
    required this.recyclable,
    required this.points,
  });
}


class _AIScannerScreenState extends State<AIScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  bool _isFlashOn = false;
  bool _isDetecting = false;

  @override
void initState() {
  super.initState();

  _scanLineController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat();

  _pulseController = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..repeat(reverse: true);
}

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

void _startDetection() async {
  print("🟢 Scan button clicked");

  if (_isDetecting) return;
  setState(() => _isDetecting = true);

  try {
    print("🟡 Picking image...");

    final image =
        await AIModelService.instance.pickImageFromGallery();

    if (image == null) {
      print("🔴 No image selected");
      throw Exception("No image selected");
    }

    print("🟢 Image selected: ${image.path}");
    print("🟡 Calling Flask AI...");

    if (!mounted) return;

final result =
  await AIModelService.instance.predictFromImage(image);

    print("🟢 AI RESULT RECEIVED: $result");

    if (!mounted) return;

    final aiResult = AIResult(
      item: result["label"],
      material: result["label"],
      recyclable: result["recyclable"],
      points: result["points"],
    );

    if (aiResult.recyclable) {
      _showRecyclablePopup(aiResult);
    } else {
      _showNonRecyclablePopup();
    }
  } catch (e) {
    print("❌ AI ERROR: $e");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isDetecting = false);
    }
  }
}



void _showRecyclablePopup(AIResult result) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Recyclable Item Detected ♻'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item: ${result.item}'),
          Text('Material: ${result.material}'),
          const SizedBox(height: 8),
          Text(
            'You can earn ${result.points} eco points!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // cancel popup
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // close popup
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClassificationResultScreen(),
              ),
            );
          },
          child: const Text('Proceed'),
        ),
      ],
    ),
  );
}

void _showNonRecyclablePopup() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Item Not Recyclable'),
      content: const Text(
        'This item is not recyclable.\nPlease try another item.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const GiverHomeScreen()),
              (route) => false,
            );
          },
          child: const Text('Go Back to Home'),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View Placeholder with Vignette
          Stack(
            children: [
              // Fake camera feed
              // REAL Camera Preview
// REAL camera preview
Container(
  width: double.infinity,
  height: double.infinity,
  color: Colors.black,
),

              // Vignette effect
              

              // Central Scanning Area
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),

                    // Scanning lines animation
                    AnimatedBuilder(
                      animation: _scanLineController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(280, 280),
                          painter: ScanningLinePainter(
                            progress: _scanLineController.value,
                          ),
                        );
                      },
                    ),

                    // Green pulsing glow (when detecting)
                    if (_isDetecting)
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.15)
                            .animate(_pulseController),
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Inner detection ring
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                    ),

                    // Corner markers
                    ..._buildCornerMarkers(),
                  ],
                ),
              ),
            ],
          ),

          // Top Overlay Text
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Align the item inside the circle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Instructions & Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  Column(
                    children: [
                      const Text(
                        'Point your camera at any waste item.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI will identify it in seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash Toggle
                      _buildIconButton(
                        icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        onPressed: () {
                          setState(() {
                            _isFlashOn = !_isFlashOn;

                          });
                        },
                      ),

                      // Capture / Auto-detect Button
                      GestureDetector(
                        
                        onTap: _isDetecting ? null : _startDetection,

                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.1),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4CAF50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50)
                                          .withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Switch Camera
                      _buildIconButton(
                        icon: Icons.flip_camera_android,
                        onPressed: () {
                          // Toggle camera
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const markerSize = 30.0;
    const markerColor = Color(0xFF4CAF50);

    return [
      // Top-left
      Positioned(
        top: 50,
        left: 50,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: markerColor, width: 3),
              left: BorderSide(color: markerColor, width: 3),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 50,
        right: 50,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: markerColor, width: 3),
              right: BorderSide(color: markerColor, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 50,
        left: 50,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: markerColor, width: 3),
              left: BorderSide(color: markerColor, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 50,
        right: 50,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: markerColor, width: 3),
              right: BorderSide(color: markerColor, width: 3),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class ScanningLinePainter extends CustomPainter {
  final double progress;

  ScanningLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 140.0;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal scanning line
    final lineY = center.dy - radius + (progress * radius * 2);
    canvas.drawLine(
      Offset(center.dx - radius, lineY),
      Offset(center.dx + radius, lineY),
      paint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawLine(
      Offset(center.dx - radius, lineY),
      Offset(center.dx + radius, lineY),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(ScanningLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ClassificationResultScreen extends StatelessWidget {
  const ClassificationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'name': 'Plastic Bottle',
        'icon': Icons.water_drop,
        'badge': 'Recyclable',
        'badgeColor': const Color(0xFF8BC34A),
        'points': 20,
      },
      {
        'name': 'Paper Cup',
        'icon': Icons.coffee,
        'badge': 'Recyclable',
        'badgeColor': const Color(0xFF8BC34A),
        'points': 10,
      },
      {
        'name': 'Food Waste',
        'icon': Icons.lunch_dining,
        'badge': 'Compostable',
        'badgeColor': const Color(0xFFFFA726),
        'points': 0,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Detected Items',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Image Preview
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.image,
                  size: 70,
                  color: Colors.grey[400],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Detected Items Title
            const Text(
              'Items Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            // Items List
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFF4CAF50),
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Name & Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (item['badgeColor'] as Color)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item['badgeColor'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Points
                      Text(
                        '+${item['points']} pts',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Request Pickup Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PickupRequestFlow(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Request Pickup',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class PickupRequestFlow extends StatefulWidget {
  const PickupRequestFlow({super.key});

  @override
  State<PickupRequestFlow> createState() => _PickupRequestFlowState();
}

class _PickupRequestFlowState extends State<PickupRequestFlow> {
  int _currentStep = 0;
  late TextEditingController _weightController;
  


  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '3.5');
  }
@override
void dispose() {
  _weightController.dispose();   // ✅ mandatory
  super.dispose();
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Step ${_currentStep + 1} of 3',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? const Color(0xFF4CAF50)
                          : AppColors.border.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PickupConfirmationScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Confirm' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1ConfirmItem();
      case 1:
        return _buildStep2PickupTime();
      case 2:
        return _buildStep3Summary();
      default:
        return Container();
    }
  }

  Widget _buildStep1ConfirmItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Image
        Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.image,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Item Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Item Name', 'Plastic Bottle'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              _buildDetailRow('Estimated Points', '20 pts', isPoints: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              const Text(
                'Weight (kg)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter weight',
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.border.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.border.withOpacity(0.2),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2PickupTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Pickup Times',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),

        const SizedBox(height: 12),

        // Time slots
        ...['2:00 PM - 4:00 PM', '4:00 PM - 6:00 PM', '6:00 PM - 8:00 PM']
            .map((time) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Color(0xFF4CAF50),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  Radio(
                    value: time,
                    groupValue: null,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Truck illustration
        Center(
          child: Container(
            width: 200,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping,
              size: 70,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              _buildDetailRow('Pickup Time', '2:00 PM - 4:00 PM'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              _buildDetailRow('Address', '123 Main Street'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              _buildDetailRow('Items', '1 Plastic Bottle'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),
              ),
              _buildDetailRow('Points Earned', '20 pts', isPoints: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPoints = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isPoints ? AppColors.accent : AppColors.text,
          ),
        ),
      ],
    );
  }
}

class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState
    extends State<PickupConfirmationScreen>
    with TickerProviderStateMixin {

  late AnimationController _confetti;

  // 🔥🔥🔥 YAHI PAR FUNCTION PASTE KARO 🔥🔥🔥
  Future<void> _savePickupRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final giverDoc = await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(user.uid)
        .get();

    if (!giverDoc.exists) return;

    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .add({
      'giverId': user.uid,
      'giverName': giverDoc.data()?['name'] ?? 'Unknown',
      'giverPhone': giverDoc.data()?['phone'] ?? '',
      'address': giverDoc.data()?['address'] ?? '',

      'material': 'Plastic Bottle',
      'weight': 3.5,
      'imageUrl': 'https://via.placeholder.com/300x300.png?text=Test+Image',

      'status': 'open', // 🔥 MOST IMPORTANT
      'createdAt': FieldValue.serverTimestamp(),
      
    });
    
    print('Pickup request saved successfully.');
  }

  @override
  void initState() {
    super.initState();

    _confetti = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _confetti.forward();

    _savePickupRequest(); // ✅ YAHI CALL KARNA HAI
  }


 

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const Spacer(),
          Center(
            child: Column(
              children: [
                // Success icon
                ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1)
                      .animate(CurvedAnimation(parent: _confetti, curve: Curves.elasticOut)),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4CAF50).withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Success message
                const Text(
                  'Pickup Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'A collector will arrive at your location within the selected time window.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Request details
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      _buildConfirmationRow('Request ID', '#REQ001'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      _buildConfirmationRow('Status', 'Confirmed'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.border.withOpacity(0.3),
                        ),
                      ),
                      _buildConfirmationRow('Points Earned', '+20', isPoints: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Back Home Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const GiverHomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, {bool isPoints = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isPoints ? AppColors.accent : AppColors.text,
          ),
        ),
      ],
    );
  }
}
