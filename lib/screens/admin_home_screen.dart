import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'leaderboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alerts_screen.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  late Future<Map<String, int>> _analyticsFuture;

@override
void initState() {
  super.initState();
  _analyticsFuture = fetchAnalytics();
}



Stream<QuerySnapshot> giverLeaderboardStream() {
  return FirebaseFirestore.instance
      .collection('giverusers')
      .orderBy('points', descending: true)
      .limit(10)
      .snapshots();
}

Stream<QuerySnapshot> collectorLeaderboardStream() {
  return FirebaseFirestore.instance
      .collection('collectorusers')
      .orderBy('totalPickups', descending: true)
      .limit(10)
      .snapshots();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildContent(),
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
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildAnalyticsPage();
      case 2:
  Future.microtask(() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlertsScreen(userType: 'admin'),
      ),
    );
  });
  return _buildHomePage(); // temporary return

      case 3:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }


  Future<Map<String, int>> fetchAnalytics() async {
  final giverSnap =
      await FirebaseFirestore.instance.collection('giverusers').get();

  final collectorSnap =
      await FirebaseFirestore.instance.collection('collectorusers').get();

  final pickupSnap = await FirebaseFirestore.instance
      .collection('pickup_requests')
      .where('status', isEqualTo: 'completed')
      .get();

  int activeCollectors = collectorSnap.docs.where((doc) {
  final data = doc.data();
  return (data['totalPickups'] ?? 0) > 0;
}).length;

  int totalRewards = 0;
  for (var doc in giverSnap.docs) {
    totalRewards += (doc['points'] ?? 0) as int;
  }

  return {
    'totalUsers': giverSnap.size + collectorSnap.size,
    'totalPickups': pickupSnap.size,
    'activeCollectors': activeCollectors,
    'totalRewards': totalRewards,
  };
}


Widget _buildHomePage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ================= HEADER =================
        const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Welcome back! Here\'s what\'s happening today.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),

        // ================= DASHBOARD SECTIONS =================
        _buildSectionGroup(
          title: 'Rewards & Redemptions',
          sections: [
            _buildSectionTile(
              title: 'Approve Claims',
              subtitle: 'Review reward claims',
              icon: Icons.check_circle,
              onTap: () => _showSection('Approve Claims'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildSectionGroup(
          title: 'Monitoring & Insights',
          sections: [
            _buildSectionTile(
              title: 'Leaderboard',
              subtitle: 'Monitor rankings',
              icon: Icons.emoji_events,
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LeaderboardScreen(userType: 'admin'),
    ),
  );
},
            ),
          ],
        ),
        const SizedBox(height: 24),


// ================= CONTENT & COMMUNICATION =================
_buildSectionGroup(
  title: 'Content & Communication',
  sections: [
    _buildSectionTile(
      title: 'Announcements',
      subtitle: 'Send messages',
      icon: Icons.campaign,
      onTap: () => _showSection('Announcements'),
    ),
    _buildSectionTile(
      title: 'Content (CMS)',
      subtitle: 'Update app content',
      icon: Icons.edit,
      onTap: () => _showSection('Content'),
    ),
  ],
),

const SizedBox(height: 16),

// ================= SUPPORT & COMPLIANCE =================
_buildSectionGroup(
  title: 'Support & Compliance',
  sections: [
    _buildSectionTile(
      title: 'Complaints & Reports',
      subtitle: 'Handle support tickets',
      icon: Icons.error_outline,
      onTap: () => _showSection('Complaints'),
    ),
  ],
),






      ],
    ),
  );
}

  Widget _buildQuickStatsBar() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard('Open Pickups', '24', AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard('Pending Claims', '8', AppColors.warning),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard('New Complaints', '3', AppColors.success),
        ),
      ],
      
    );
  }

  Widget _buildQuickStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGroup({
    required String title,
    required List<Widget> sections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...sections,
      ],
    );
  }

  Widget _buildSectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
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
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsPage() {
  return FutureBuilder<Map<String, int>>(
    future: _analyticsFuture,

    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      }

      if (!snapshot.hasData) {
        return const Center(child: Text('No analytics data found'));
      }


      final data = snapshot.data!;
      return SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),
            _buildAnalyticsCard(
                'Total Users', data['totalUsers'].toString(), '', AppColors.accent),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
                'Total Pickups', data['totalPickups'].toString(), '', AppColors.success),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
                'Active Collectors', data['activeCollectors'].toString(), '', AppColors.warning),
            const SizedBox(height: 12),
            _buildAnalyticsCard(
                'Rewards Issued', '₹${data['totalRewards']}', '', AppColors.accent),
          ],
        ),
      );
    },
  );
}


  Widget _buildAnalyticsCard(String title, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            title: 'System Configuration',
            icon: Icons.settings,
            onTap: () => _showSection('''Here admin can configure core application settings such as pickup limits,
reward rules, user restrictions, and system-level preferences.
These settings control how the entire Trash & Cash platform behaves.
'''),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            title: 'Admin Roles & Permissions',
            icon: Icons.security,
            onTap: () => _showSection('''This section allows the admin to manage roles and permissions.
Admin can decide who can access analytics, approve pickups,
manage rewards, or handle complaints.
Different access levels can be assigned to different admins.
'''),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            title: 'Backup & Restore',
            icon: Icons.cloud_download,
            onTap: () => _showSection('''Admin can create backups of application data such as users,
pickups, rewards, and reports.
In case of data loss or system failure, data can be restored
to ensure smooth platform recovery.
'''),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            title: 'Audit Logs',
            icon: Icons.history,
            onTap: () => _showSection('''This section keeps a record of all important admin activities
such as approvals, role changes, and system updates.
Audit logs help in tracking actions for security and transparency.
'''),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            title: 'Help & Support',
            icon: Icons.help,
            onTap: () => _showSection('''Admin can access help documentation, FAQs, and support options.
This section helps admins resolve issues related to users,
collectors, pickups, or system errors.
'''),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  void _showSection(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $section')),
    );
  }
}