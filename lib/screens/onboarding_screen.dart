import 'package:flutter/material.dart';
import 'user_type_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'Trash is a problem\nwe all face.',
      subtitle: 'A small step from you brings a big change to our environment.',
      illustration: const PollutedCityIllustration(),
      backgroundColor: Colors.white,
    ),
    OnboardingPageModel(
      title: 'Your trash can\ncreate value.',
      subtitle: 'Turn everyday waste into points, rewards and real-world impact.',
      illustration: const HandoverIllustration(),
      backgroundColor: Colors.white,
    ),
    OnboardingPageModel(
      title: 'Let\'s make the\nplanet cleaner.',
      subtitle: 'Join our community to recycle smarter and earn while you do it.',
      illustration: const PlantingIllustration(),
      backgroundColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingContent(page: _pages[index]);
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == index ? 32 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: _currentPage == index
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const UserTypeScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}

class OnboardingPageModel {
  final String title;
  final String subtitle;
  final Widget illustration;
  final Color backgroundColor;

  OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.backgroundColor,
  });
}

class OnboardingContent extends StatelessWidget {
  final OnboardingPageModel page;

  const OnboardingContent({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: page.illustration,
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// Reusable Floating Icon Widget for Better UI
class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;

  const FloatingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 50,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(widget.icon, color: widget.color, size: widget.size * 0.6),
          ),
        );
      },
    );
  }
}

// Illustration Screen 1
class PollutedCityIllustration extends StatelessWidget {
  const PollutedCityIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(color: const Color(0xFFF1F8E9), shape: BoxShape.circle),
        ),
        const Positioned(top: 40, left: 20, child: FloatingIcon(icon: Icons.energy_savings_leaf, color: Colors.green, size: 55)), // Leaf/Nature
        const Positioned(top: 20, right: 30, child: FloatingIcon(icon: Icons.compost, color: Colors.teal, size: 60)), // Compost/Recycle
        const Positioned(bottom: 80, right: 10, child: FloatingIcon(icon: Icons.nature, color: Colors.lightGreen, size: 50)), // Nature
        const Center(
          child: Icon(
            Icons.recycling, // Main: Recycling Symbol
            size: 160,
            color: Color(0xFF2E7D32), // Dark Green
          ),
        ),
      ],
    );
  }
}

// Illustration Screen 2
class HandoverIllustration extends StatelessWidget {
  const HandoverIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
        ),
        const Positioned(top: 30, left: 40, child: FloatingIcon(icon: Icons.attach_money, color: Colors.amber, size: 60)), // Money/Coins
        const Positioned(bottom: 60, left: 20, child: FloatingIcon(icon: Icons.emoji_events, color: Colors.orangeAccent, size: 50)), // Trophy/Points
        const Center(
          child: Icon(
            Icons.card_giftcard, // Rewards/Gift box
            size: 180,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }
}

// Illustration Screen 3
class PlantingIllustration extends StatelessWidget {
  const PlantingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(color: const Color(0xFFE1F5FE), shape: BoxShape.circle),
        ),
        const Positioned(top: 20, child: FloatingIcon(icon: Icons.wb_sunny, color: Colors.orange, size: 60)), // Sun
        const Positioned(bottom: 100, left: 10, child: FloatingIcon(icon: Icons.water_drop, color: Colors.blue, size: 50)), // Water
        const Center(
          child: Icon(
            Icons.forest, // Main: Forest/Nature
            size: 180,
            color: Color(0xFF1B5E20), // Deep Forest Green
          ),
        ),
      ],
    );
  }
}