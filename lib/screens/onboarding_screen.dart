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

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Trash is a problem we all face.',
      subtitle: 'A small step from you brings a big change.',
      illustration: PollutedCityIllustration(),
      backgroundColor: Color(0xFFE3F2FD),
    ),
    const OnboardingPage(
      title: 'Your trash can create value.',
      subtitle: 'Turn everyday waste into points, rewards and impact.',
      illustration: HandoverIllustration(),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    const OnboardingPage(
      title: 'Let\'s make the planet cleaner together.',
      subtitle: 'We\'re here to help you recycle smarter.',
      illustration: PlantingIllustration(),
      backgroundColor: Color(0xFFEFF7FA),
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
              return _pages[index];
            },
          ),
          // Dots indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  width: _currentPage == index ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ),
          ),
          // Get Started Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const UserTypeScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
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
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget illustration;
  final Color backgroundColor;

  const OnboardingPage({super.key, 
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              SizedBox(
                height: 300,
                child: illustration,
              ),
              const Spacer(),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// Illustration Widgets
class PollutedCityIllustration extends StatelessWidget {
  const PollutedCityIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Smoke background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        // Buildings silhouette
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBuilding(80, Colors.grey),
                _buildBuilding(120, Colors.grey.shade400),
                _buildBuilding(90, Colors.grey),
              ],
            ),
          ],
        ),
        // Floating trash particles
        ..._buildTrashParticles(),
      ],
    );
  }

  Widget _buildBuilding(double height, Color color) {
    return Container(
      width: 50,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  List<Widget> _buildTrashParticles() {
    return [
      Positioned(top: 40, left: 30, child: _buildTrashIcon()),
      Positioned(top: 60, right: 40, child: _buildTrashIcon()),
      Positioned(top: 100, left: 20, child: _buildTrashIcon()),
    ];
  }

  Widget _buildTrashIcon() {
    return Opacity(
      opacity: 0.6,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.brown.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }
}

class HandoverIllustration extends StatelessWidget {
  const HandoverIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Person giving trash
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Giver
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BC34A).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 40, color: Color(0xFF8BC34A)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Giver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(width: 20),
              // Arrow
              const Icon(Icons.arrow_forward, size: 32, color: Color(0xFF8BC34A)),
              const SizedBox(width: 20),
              // Collector
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping, size: 40, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Collector', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Reward icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.stars, size: 48, color: Color(0xFFFFD54F)),
          ),
        ],
      ),
    );
  }
}

class PlantingIllustration extends StatelessWidget {
  const PlantingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hand holding plant
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Plant
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 40,
                      color: Colors.brown.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 25,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BC34A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Sun rays
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F).withOpacity(0.2),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.sunny,
                  size: 40,
                  color: Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}