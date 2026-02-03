import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'ai_scanner_screen.dart';
import 'leaderboard_screen.dart';
import '../theme/app_colors.dart';
import 'alerts_screen.dart';

class GiverHomeScreen extends StatefulWidget {
  const GiverHomeScreen({super.key});

  @override
  State<GiverHomeScreen> createState() => _GiverHomeScreenState();
}

class _GiverHomeScreenState extends State<GiverHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  int userPoints = 0;
  String userName = '';
String userEmail = '';
String userPhone = '';
String userAddress = '';
bool isUserLoading = true;


  @override
void initState() {
  super.initState();
  _fetchUserData();

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  });
}
Future<void> _fetchUserData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? 'User';
        userEmail = doc['email'] ?? '';
        userPhone = doc['phone'] ?? '';
        userAddress = doc['address'] ?? '';
        userPoints = doc['points'] ?? 0;
        isUserLoading = false;
      });
    }
  } catch (e) {
    debugPrint('User fetch error: $e');
    setState(() => isUserLoading = false);
  }
}

Stream<int?> _giverRankStream() async* {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await for (final snapshot in FirebaseFirestore.instance
      .collection('giverusers')
      .orderBy('points', descending: true)
      .snapshots()) {

    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == uid) {
        yield i + 1; // 🔥 rank = position
        break;
      }
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading ? _buildLoadingScreen() : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/tree_grow.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Growing your eco impact...',
            style: TextStyle(fontSize: 16, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomePage(),
        _buildScanPage(),
        const LeaderboardScreen(userType: 'giver'),
        _buildProfilePage(),
      ],
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Container
          _buildWelcomeContainer(),
          
          const SizedBox(height: 20),
          
          // Missions Container
          _buildMissionsContainer(),
          
          const SizedBox(height: 20),
          
          // Active Requests Container
          _buildActiveRequestsContainer(),
          
          const SizedBox(height: 20),
          
          // Recent History Container
          _buildRecentHistoryContainer(),
          
          const SizedBox(height: 20),
          
          // Eco Points & Redemption Container
          _buildEcoPointsRedemptionContainer(),
        ],
      ),
    );
  }

  Widget _buildWelcomeContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Message
          Row(
            children: [
              Text(
  isUserLoading ? 'Loading...' : userName,
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  ),
),

            ],
          ),
          

          
          const SizedBox(height: 16),
          
          // Stats Row
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
  'Eco Points',
  userPoints.toString(),
  Icons.star,
),

              _buildStatCard('Waste (kg)', '45.3', Icons.scale),
              StreamBuilder<int?>(
  stream: _giverRankStream(),
  builder: (context, snapshot) {
    final rankText =
        snapshot.hasData ? '#${snapshot.data}' : '--';

    return _buildStatCard(
      'Rank',
      rankText,
      Icons.emoji_events,
    );
  },
),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Missions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          
          // Monthly Mission
          _buildMissionCard(
            title: 'Monthly Mission',
            icon: Icons.calendar_month,
            description: 'Recycle 5kg waste this month',
            current: 3.2,
            target: 5.0,
            unit: 'kg',
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 12),
          
          // Weekly Mission
          _buildMissionCard(
            title: 'Weekly Mission',
            icon: Icons.date_range,
            description: 'Collect 2kg waste this week',
            current: 1.1,
            target: 2.0,
            unit: 'kg',
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 12),
          
          // Daily Mission Row
          Row(
            children: [
              Expanded(
                child: _buildDailyMissionCard(
                  icon: Icons.delete_outline,
                  title: 'Separate Waste',
                  status: 'Completed',
                  isCompleted: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDailyMissionCard(
                  icon: Icons.local_shipping,
                  title: 'Request Pickup',
                  status: 'Pending',
                  isCompleted: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required String title,
    required IconData icon,
    required String description,
    required double current,
    required double target,
    required String unit,
    required Color color,
  }) {
    double progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $target $unit',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMissionCard({
    required IconData icon,
    required String title,
    required String status,
    required bool isCompleted,
  }) {
    Color statusColor = isCompleted ? AppColors.success : AppColors.warning;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequestsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Pickup Request',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          // Request Detail Container
          _buildRequestDetailCard(
            'Plastic Bottles & Cans',
            'Dec 3, 2025 - 2:00 PM',
            '3.5 kg',
            50,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailCard(String item, String pickupDate, String weight, int points) {
    IconData itemIcon = _getItemIcon(item);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(itemIcon, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickupDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$points pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Weight: $weight',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistoryContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildHistoryItem('Plastic Waste', 'Dec 2, 2025', '2.3 kg', '35 pts'),
          _buildHistoryItem('Glass Bottles', 'Dec 1, 2025', '1.8 kg', '25 pts'),
          _buildHistoryItem('Aluminum Cans', 'Nov 30, 2025', '0.9 kg', '15 pts'),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String item, String date, String weight, String points) {
    IconData itemIcon = _getItemIcon(item);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(itemIcon, color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '$date • $weight',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                points,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(String itemName) {
    final lowerItem = itemName.toLowerCase();
    if (lowerItem.contains('plastic')) return Icons.shopping_bag;
    if (lowerItem.contains('glass') || lowerItem.contains('bottle')) return Icons.local_drink;
    if (lowerItem.contains('aluminum') || lowerItem.contains('can')) return Icons.recycling;
    if (lowerItem.contains('paper')) return Icons.description;
    if (lowerItem.contains('metal')) return Icons.hardware;
    return Icons.delete_outline;
  }
  Widget _buildEcoPointsRedemptionContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eco Points & Redemption',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
           Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row( // ❌ const REMOVED (THIS IS THE FIX)
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Total Points Available',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
                Text(
                  userPoints.toString(), // ✅ Firebase value
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionCard(String title, String points, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                points,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Redeem',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanPage() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIScannerScreen()),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Lottie.asset(
                'assets/animations/tree_grow.json',
                fit: BoxFit.contain,
                repeat: false,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to Scan Trash',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at your trash to identify and earn eco points',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 4),
          Text(
  isUserLoading ? 'Loading...' : userName,
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  ),
),
Text(
  userEmail,
  style: const TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  ),
),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // User Information Section
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildUserInfoItem('Full Name', userName, Icons.person),
_buildUserInfoItem('Mobile Number', userPhone, Icons.phone),
_buildUserInfoItem('Email Address', userEmail, Icons.email),
_buildUserInfoItem('Address', userAddress, Icons.location_on),

          
          const SizedBox(height: 30),
          
          // Stats Section
          const Text(
            'Your Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildProfileStatItem('Total Waste Recycled', '45.3 kg'),
          _buildProfileStatItem(
  'Total Eco Points',
  userPoints.toString(),
),

         StreamBuilder<int?>(
  stream: _giverRankStream(),
  builder: (context, snapshot) {
    return _buildProfileStatItem(
      'Leaderboard Rank',
      snapshot.hasData ? '#${snapshot.data}' : '--',
    );
  },
),

          _buildProfileStatItem('Current League', 'Gold League 🏆'),
          _buildProfileStatItem('Member Since', 'Jan 15, 2025'),
          
          const SizedBox(height: 30),
          
          // Grievance Section
          const Text(
            'Report Issues',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildSettingItem('Pickup Issue', Icons.local_shipping, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pickup Issue Report Form Opened')),
            );
          }),
          _buildSettingItem('Eco Points Issue', Icons.trending_up, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Eco Points Issue Report Form Opened')),
            );
          }),
          _buildSettingItem('Application Issue', Icons.bug_report, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Application Issue Report Form Opened')),
            );
          }),
          
          const SizedBox(height: 30),
          
          // Settings Section
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildSettingItem('Notifications', Icons.notifications, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AlertsScreen(userType: 'giver'),
    ),
  );
}),

          _buildSettingItem('Privacy & Security', Icons.lock, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('''Privacy & Security

We respect your privacy and are committed to protecting your personal data.

All user information such as name, email, phone number, and activity data is securely stored using Firebase Authentication and Firestore.

Your login credentials are encrypted and never shared with third parties.

Only authorized access is allowed to your account through secure authentication.

We do not sell or misuse your personal data under any circumstances.

You have full control over your account and can request data updates or account removal anytime.''')),
            );
          }),
          _buildSettingItem('Help & Support', Icons.help, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('''Help & Support

If you face any issues related to pickups, eco points, or account access, we are here to help.

You can reach our support team via email or in-app support options.

Our team will assist you with technical issues, feedback, and general queries.

We continuously work to improve the app based on user feedback.''')),
            );
          }),
          _buildSettingItem('About', Icons.info, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('''🌱 About App 


Eco-Reward is a digital recycling platform designed to promote sustainable living.

Users can give waste materials like plastic, paper, glass, and metal for recycling.

The app connects users (Givers) with waste collectors in an easy and transparent way.

For every successful recycling activity, users earn eco points or rewards.

This initiative helps reduce pollution, encourages recycling, and supports a cleaner environment.

By using this app, you are contributing to a greener and more sustainable future.''')),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                          },
                          child: const Text('Logout', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accent),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
