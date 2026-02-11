import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'leaderboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'alerts_screen.dart'; // 🚫 Removed
// import 'admin_reports_screen.dart'; // 🚫 Kept for reference but logic moved here


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
      backgroundColor: const Color(0xFFF4F9F4), // Light greenish-white
      body: _buildContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.report_problem_rounded), label: 'Complaints'), // 👈 CHANGED
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
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
        return _buildReportsPage(); // 👈 DIRECT PAGE, NO NAVIGATION
      case 3:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  Future<Map<String, int>> fetchAnalytics() async {
    final giverSnap = await FirebaseFirestore.instance.collection('giverusers').get();
    final collectorSnap = await FirebaseFirestore.instance.collection('collectorusers').get();
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

  // ================= HOME DASHBOARD =================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    'Overview & Controls',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1B5E20)),
              )
            ],
          ),
          
          const SizedBox(height: 30),

          // Quick Actions Grid
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildActionCard(
                'Approve Claims',
                Icons.verified_user_rounded,
                 const Color(0xFFE8F5E9),
                 const Color(0xFF2E7D32),
                () => _showSection('Approve Claims'), // Keeps logic
              ),
              _buildActionCard(
                'Leaderboard',
                Icons.emoji_events_rounded,
                 const Color(0xFFFFF8E1),
                 const Color(0xFFFBC02D),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(userType: 'admin'),
                    ),
                  );
                },
              ),
              _buildActionCard(
                'Announcements',
                Icons.campaign_rounded,
                 const Color(0xFFE3F2FD),
                 const Color(0xFF1565C0),
                 () => _showSection('Announcements'),
              ),
               _buildActionCard(
                'Manage Content',
                Icons.edit_document,
                 const Color(0xFFFCE4EC),
                 const Color(0xFFC2185B),
                 () => _showSection('Content'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color bg, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ANALYTICS =================
  Widget _buildAnalyticsPage() {
    return FutureBuilder<Map<String, int>>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
         // Logic preserved
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No analytics data found'));
        }

        final data = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 24),
              
              _buildModernStatCard('Total Users', data['totalUsers'].toString(), Icons.people_alt_rounded, Colors.blue),
              const SizedBox(height: 16),
              _buildModernStatCard('Total Pickups', data['totalPickups'].toString(), Icons.local_shipping_rounded, Colors.green),
              const SizedBox(height: 16),
              _buildModernStatCard('Active Collectors', data['activeCollectors'].toString(), Icons.engineering_rounded, Colors.orange),
              const SizedBox(height: 16),
              _buildModernStatCard('Rewards Issued', '₹${data['totalRewards']}', Icons.card_giftcard_rounded, Colors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= REPORTS (REPLACES ALERTS) =================
  Widget _buildReportsPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Row(
            children: const [
              Text('Complaints & Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No pending reports', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isGiver = (data['userType'] ?? '').toString().toLowerCase() == 'giver';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isGiver ? Colors.green[50] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isGiver ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                (data['userType'] ?? 'User').toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: isGiver ? Colors.green[800] : Colors.blue[800]
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['status'] ?? 'Open',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['message'] ?? 'No Description',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333), height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey[100]),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _showSection('Resolve Report (ID: ${doc.id})');
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Mark Resolved'),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1B5E20)),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= SETTINGS =================
  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 24),
          
          _buildModernSettingTile('System Configuration', Icons.settings_suggest_rounded, 
             () => _showSection('System Config')),
          
          _buildModernSettingTile('Roles & Permissions', Icons.security_rounded, 
             () => _showSection('Roles')),
          
          _buildModernSettingTile('Backup & Restore', Icons.cloud_sync_rounded, 
             () => _showSection('Backups')),
          
          _buildModernSettingTile('Audit Logs', Icons.history_edu_rounded, 
             () => _showSection('Logs')),
             
          _buildModernSettingTile('Help & Support', Icons.help_outline_rounded, 
             () => _showSection('Help')),
        ],
      ),
    );
  }

  Widget _buildModernSettingTile(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF1B5E20), size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
      ),
    );
  }

  void _showSection(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $section'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }
}