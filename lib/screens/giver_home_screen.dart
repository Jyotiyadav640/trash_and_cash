import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'dart:async'; // 🔥 Added this import
//import 'ai_scanner_screen.dart';
import 'leaderboard_screen.dart';
import '../theme/app_colors.dart';
import 'alerts_screen.dart';
import 'ai_webview_screen.dart';

class GiverHomeScreen extends StatefulWidget {
  const GiverHomeScreen({super.key});

  @override
  State<GiverHomeScreen> createState() => _GiverHomeScreenState();
}

class _GiverHomeScreenState extends State<GiverHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  int userPoints = 0;
  double totalWaste = 0.0;
  String userName = '';
  


String userEmail = '';
String userPhone = '';
String userAddress = '';
bool isUserLoading = true;
bool isFirstLogin = false;
bool isEditingName = false;
bool isEditingPhone = false;
bool isEditingEmail = false;
bool isEditingAddress = false;
final TextEditingController _reportController = TextEditingController();
bool isSubmittingReport = false;
final TextEditingController _nameEditController = TextEditingController();
final TextEditingController _phoneEditController = TextEditingController();
final TextEditingController _emailEditController = TextEditingController();
final TextEditingController _addressEditController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void dispose() {
    _userSubscription?.cancel();
    _reportController.dispose();
    _nameEditController.dispose();
    _phoneEditController.dispose();
    _emailEditController.dispose();
    _addressEditController.dispose();
    super.dispose();
  }


  @override
void initState() {
  super.initState();
  _setupUserListener();
}

void _setupUserListener() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  _userSubscription = FirebaseFirestore.instance
      .collection('giverusers')
      .doc(user.uid)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) {
      if (mounted) setState(() => isUserLoading = false);
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>;

    if (mounted) {
      setState(() {
        userName = data['name'] ?? 'User';
        userEmail = data['email'] ?? '';
        userPhone = data['phone'] ?? '';
        userAddress = data['address'] ?? '';

        // 🔥 IMPORTANT DEFAULTS (Real-time updates)
        // 🔥 IMPORTANT DEFAULTS (Real-time updates)
        // Safely parse as num to handle both int and double from Firestore
        userPoints = (data['points'] as num?)?.toInt() ?? 0;
        totalWaste = (data['totalWaste'] as num?)?.toDouble() ?? 0.0;

        isFirstLogin = data['isFirstLogin'] ?? false;
        isUserLoading = false;
        _isLoading = false; // Stop main loading spinner

        // Sync controllers if not editing to avoid overwriting user input
        if (!isEditingName) _nameEditController.text = userName;
        if (!isEditingEmail) _emailEditController.text = userEmail;
        if (!isEditingPhone) _phoneEditController.text = userPhone;
        if (!isEditingAddress) _addressEditController.text = userAddress;
      });
    }

    // 🔥 first login check
    if (data['isFirstLogin'] == true) {
      FirebaseFirestore.instance
          .collection('giverusers')
          .doc(user.uid)
          .update({'isFirstLogin': false});
    }
  }, onError: (e) {
    debugPrint('User stream error: $e');
    if (mounted) setState(() => isUserLoading = false);
  });
}

Future<void> _submitReport(String userType) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (_reportController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your issue')),
    );
    return;
  }

  setState(() => isSubmittingReport = true);

  await FirebaseFirestore.instance.collection('reports').add({
    'userId': user.uid,
    'userType': userType, // giver / collector
    'message': _reportController.text.trim(),
    'createdAt': FieldValue.serverTimestamp(),
    'status': 'open',
  });

  _reportController.clear();

  setState(() => isSubmittingReport = false);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Report sent to admin')),
  );
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
      backgroundColor: const Color(0xFFF4F9F4), // Premium Off-White
      body: _isLoading ? _buildLoadingScreen() : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
       onTap: (index) {
  if (index == 1) {
    // 🔥 Scan tab
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIWebViewScreen()),
    );
    return;
  }

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
        const SizedBox.shrink(),
        const LeaderboardScreen(userType: 'giver'),
        _buildProfilePage(),
      ],
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Modern Curved Header
          _buildModernHeader(),

          // 2. Stats Section (Overlapping the header slightly)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernStats(),
            ),
          ),

          // 3. Content Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Your Impact'),
                const SizedBox(height: 12),
                _buildMissionsContainer(),
                if (userPoints > 0) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Active Requests'),
                  const SizedBox(height: 12),
                  _buildActiveRequestsContainer(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Recent Activity'),
                  const SizedBox(height: 12),
                  _buildRecentHistoryContainer(),
                  const SizedBox(height: 24),
                  _buildEcoPointsRedemptionContainer(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B5E20),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 80),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"), // Subtle pattern
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFirstLogin ? 'Welcome to TrashCash,' : 'Welcome Back,',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName.isNotEmpty ? userName : 'Eco Warrior',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildModernStatItem('Points', '$userPoints', Icons.stars_rounded, Colors.amber),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildModernStatItem('Waste', '${totalWaste.toStringAsFixed(1)} kg', Icons.recycling_rounded, Colors.green),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('giverusers').orderBy('points', descending: true).snapshots(),
            builder: (context, snapshot) {
              String rank = '--';
              // 🔥 Only calculate rank if user has points
              if (userPoints > 0 && snapshot.hasData) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                for (int i = 0; i < snapshot.data!.docs.length; i++) {
                  if (snapshot.data!.docs[i].id == uid) {
                    rank = '#${i + 1}';
                    break;
                  }
                }
              }
              return _buildModernStatItem('Rank', rank, Icons.emoji_events_rounded, Colors.orange);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMissionsContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
            current: userPoints > 0 ? 3.2 : 0.0,
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
            current: userPoints > 0 ? 1.1 : 0.0,
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
                  status: userPoints > 0 ? 'Completed' : '',
                  isCompleted: userPoints > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDailyMissionCard(
                  icon: Icons.local_shipping,
                  title: 'Request Pickup',
                  status: userPoints > 0 ? 'Pending' : '',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
          const SizedBox(height: 6),
          if (status.isNotEmpty)
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
    if (lowerItem.contains('plastic')) return Icons.shopping_bag_rounded;
    if (lowerItem.contains('glass') || lowerItem.contains('bottle')) return Icons.local_drink_rounded;
    if (lowerItem.contains('aluminum') || lowerItem.contains('can')) return Icons.recycling_rounded;
    if (lowerItem.contains('paper')) return Icons.description_rounded;
    if (lowerItem.contains('metal')) return Icons.hardware_rounded;
    return Icons.delete_outline_rounded;
  }
  Widget _buildEcoPointsRedemptionContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rewards & Redemption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$userPoints',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
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
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1B5E20), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isUserLoading ? 'Loading...' : userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
          
          _buildEditableField(
  label: 'Full Name',
  value: userName,
  controller: _nameEditController,
  isEditing: isEditingName,
  icon: Icons.person_rounded,
  onEdit: () {
    setState(() => isEditingName = true);
  },
  onUpdate: () async {
    await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'name': _nameEditController.text});

    setState(() {
      userName = _nameEditController.text;
      isEditingName = false;
    });
  },
),

_buildEditableField(
  label: 'Mobile Number',
  value: userPhone,
  controller: _phoneEditController,
  isEditing: isEditingPhone,
  icon: Icons.phone_rounded,
  onEdit: () {
    setState(() => isEditingPhone = true);
  },
  onUpdate: () async {
    await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'phone': _phoneEditController.text});

    setState(() {
      userPhone = _phoneEditController.text;
      isEditingPhone = false;
    });
  },
),

_buildEditableField(
  label: 'Email Address',
  value: userEmail,
  controller: _emailEditController,
  isEditing: isEditingEmail,
  icon: Icons.email_rounded,
  onEdit: () {
    setState(() => isEditingEmail = true);
  },
  onUpdate: () async {
    await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'email': _emailEditController.text});

    setState(() {
      userEmail = _emailEditController.text;
      isEditingEmail = false;
    });
  },
),

_buildEditableField(
  label: 'Address',
  value: userAddress,
  controller: _addressEditController,
  isEditing: isEditingAddress,
  icon: Icons.location_on_rounded,
  onEdit: () {
    setState(() => isEditingAddress = true);
  },
  onUpdate: () async {
    await FirebaseFirestore.instance
        .collection('giverusers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'address': _addressEditController.text});

    setState(() {
      userAddress = _addressEditController.text;
      isEditingAddress = false;
    });
  },
),


          
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
          
          _buildProfileStatItem(
  'Total Waste Recycled',
  '${totalWaste.toStringAsFixed(1)} kg',
),

          _buildProfileStatItem(
  'Total Eco Points',
  userPoints.toString(),
),

        StreamBuilder<int?>(
  stream: _giverRankStream(),
  builder: (context, snapshot) {
    String rankText = '--';

    // ✅ SAME RULE AS HOME PAGE
    if (userPoints > 0 &&
        snapshot.connectionState == ConnectionState.active &&
        snapshot.data != null) {
      rankText = '#${snapshot.data}';
    }

    return _buildProfileStatItem(
      'Rank',
      rankText,
    );
  },
),

  
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe your issue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reportController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write your complaint or issue here...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmittingReport
                        ? null
                        : () => _submitReport('giver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSubmittingReport
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),

        
          
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
          
          _buildSettingItem('Notifications', Icons.notifications_rounded, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AlertsScreen(userType: 'giver'),
    ),
  );
}),

          _buildSettingItem('Privacy & Security', Icons.lock_rounded, () {
            _showInfoScreen(
              context,
              'Privacy & Security',
              '''We respect your privacy and are committed to protecting your personal data.

All user information such as name, email, phone number, and activity data is securely stored using Firebase Authentication and Firestore.

Your login credentials are encrypted and never shared with third parties.

Only authorized access is allowed to your account through secure authentication.

We do not sell or misuse your personal data under any circumstances.

You have full control over your account and can request data updates or account removal anytime.''',
            );
          }),
          _buildSettingItem('Help & Support', Icons.help_rounded, () {
            _showInfoScreen(
              context,
              'Help & Support',
              '''If you face any issues related to pickups, eco points, or account access, we are here to help.

You can reach our support team via email or in-app support options.

Our team will assist you with technical issues, feedback, and general queries.

We continuously work to improve the app based on user feedback.''',
            );
          }),
          _buildSettingItem('About', Icons.info_rounded, () {
            _showInfoScreen(
              context,
              'About App',
              '''Trash Cash is a mobile app designed to help users manage their waste disposal and earn eco points for their efforts.

Key Features:

Pickup Requests: Users can request pickups for their waste.
Eco Points: Users earn points for their waste disposal activities.
Leaderboard: Users can track their progress and compare with others.
Notifications: Users receive updates about their pickups and eco points.
Support: Users can contact support for assistance.
Privacy Policy: Users can view the app's privacy policy.
Terms of Service: Users can view the app's terms of service.

Version: 1.0.0
Developer: Trash Cash Team
Contact: support@trashcash.com''',
            );
          }),
          
          const SizedBox(height: 20),
          
          // Logout Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            child: ElevatedButton(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBEE),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onUpdate,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isEditing)
                      const SizedBox(height: 4),
                    if (!isEditing)
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey),
                  onPressed: onEdit,
                )
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Update'),
              ),
            )
          ],
        ],
      ),
    );
  }


  Widget _buildProfileStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showInfoScreen(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFF4F9F4),
          appBar: AppBar(
            title: Text(title, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF333333)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
