import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alerts_screen.dart';

import 'package:trash_cash_fixed1/services/notifications_service.dart';

import 'leaderboard_screen.dart';
import '../theme/app_colors.dart';

class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen> {
  int _selectedIndex = 0;

  // 🔹 Firebase user data
  String name = '';
  String email = '';
  String phone = '';
  int totalPickups = 0;
  double totalWaste = 0.0;
  bool isLoading = true;

  // Dummy pickup lists (later Firestore se aayenge)
  final List<Map<String, dynamic>> _openPickups = [];
  final List<Map<String, dynamic>> _yourPickups = [];

  @override
  void initState() {
    super.initState();
    _fetchCollectorData();
  }

  // ================= FETCH DATA =================
  Future<void> _fetchCollectorData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('collectorusers')
          .doc(user.uid)
          .get();
      final snapshot = await FirebaseFirestore.instance
    .collection('collectorusers')
    .orderBy('totalPickups', descending: true)
    .limit(50)
    .get();

      if (doc.exists) {
        setState(() {
          name = doc['name'] ?? 'Collector';
          email = doc['email'] ?? '';
          phone = doc['phone'] ?? '';
          totalPickups = doc.data()?.containsKey('totalPickups') == true
    ? doc['totalPickups']
    : 0;

totalWaste = doc.data()?.containsKey('totalWaste') == true
    ? (doc['totalWaste'] as num).toDouble()
    : 0.0;



          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Collector fetch error: $e');
      setState(() => isLoading = false);
    }
  }
  Stream<int?> _collectorRankStream() async* {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await for (final snapshot in FirebaseFirestore.instance
      .collection('collectorusers')
      .orderBy('totalPickups', descending: true)
      .snapshots()) {
    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == uid) {
        yield i + 1; // 🔥 SAME POSITION = SAME RANK
        break;
      }
    }
  }
}



  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Pickups'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomePage(),
        _buildPickupsPage(),
        const LeaderboardScreen(userType: 'collector'),
        _buildProfilePage(),
      ],
    );
  }

  // ================= HOME =================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildStatsCard(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          _buildPendingRequests(),
        ],
      ),
    );
  }
  Widget _buildPendingRequests() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const SizedBox();
      }

      final docs = snapshot.data!.docs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Requests'),

          ...docs.map((doc) {
            
            final data = doc.data() as Map<String, dynamic>;

final name = data['name'] ?? 'Unknown';
final pickups = (data['totalPickups'] ?? 0) as int;
final waste = (data['totalWaste'] ?? 0).toDouble();


            return Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['giverName']),
                        Text(data['material']),
                        Text('${data['weight']} kg'),
                        const Text('Status: Pending',
                            style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),

                  // ✅ Complete
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green),
                    onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final batch = FirebaseFirestore.instance.batch();

  // 1️⃣ Mark pickup completed
  batch.update(doc.reference, {'status': 'completed'});

  // 2️⃣ Update collector leaderboard data
  final collectorRef = FirebaseFirestore.instance
      .collection('collectorusers')
      .doc(user.uid);

  batch.update(collectorRef, {
    'totalPickups': FieldValue.increment(1),
    'totalWaste': FieldValue.increment(
      (doc['weight'] as num).toDouble(),
    ),
    'points': FieldValue.increment(10), // 🔥 reward points
  });

  await batch.commit();
  await NotificationService.sendNotification(
  userId: doc['giverId'],
  userType: 'giver',
  title: 'Pickup Completed',
  body: 'Your pickup has been completed successfully',
);

},

                  ),
                ],
              ),
            );
          }),
        ],
      );
    },
  );
}


  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome back,',
              style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Row(
      children: [
        _statTile('Pickups', '$totalPickups', Icons.local_shipping),
        const SizedBox(width: 12),
        _statTile('Waste', '${totalWaste.toStringAsFixed(1)} kg', Icons.delete),
        const SizedBox(width: 12),
        StreamBuilder<int?>(
  stream: _collectorRankStream(),
  builder: (context, snapshot) {
    final rankText =
        snapshot.hasData ? '#${snapshot.data}' : '--';

    return _statTile(
      'Rank',
      rankText,
      Icons.emoji_events,
    );
  },
),

      ],
    );
  }

  Widget _statTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(title,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
Widget _buildRecentActivity() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('status', isEqualTo: 'completed')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Text('No recent activity');
      }

      final docs = snapshot.data!.docs;

      return Column(
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return ListTile(
            leading: const Icon(Icons.done, color: Colors.green),
            title: const Text('Pickup completed'),
            subtitle: Text('${data['material']} • ${data['weight']} kg'),
          );
        }).toList(),
      );
    },
  );
}

  // ================= PICKUPS =================
Widget _buildPickupsPage() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('status', isEqualTo: 'open')
       
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No pickup requests available'));
      }

      final pickups = snapshot.data!.docs;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pickups.length,
        itemBuilder: (context, index) {
          final doc = pickups[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['giverName'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('Address: ${doc['address']}'),
                  Text('Material: ${doc['material']}'),
                  Text('Weight: ${doc['weight']} kg'),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('pickup_requests')
                              .doc(doc.id)
                              .update({'status': 'rejected'});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.green),
                       onPressed: () async {
  await FirebaseFirestore.instance
      .collection('pickup_requests')
      .doc(doc.id)
      .update({'status': 'pending'});

  await NotificationService.sendNotification(
    userId: doc['giverId'], // 🔥 VERY IMPORTANT
    userType: 'giver',
    title: 'Pickup Accepted',
    body: 'Collector has accepted your pickup request',
  );
},

                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  // ================= PROFILE =================
  Widget _buildProfilePage() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ===== Profile Header =====
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
                child: const Icon(Icons.person,
                    size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text),
              ),
              Text(
                email,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ===== Personal Info =====
        const Text(
          'Personal Information',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text),
        ),
        const SizedBox(height: 12),

        _profileInfoTile('Full Name', name, Icons.person),
        _profileInfoTile('Mobile Number', phone, Icons.phone),
        _profileInfoTile('Email Address', email, Icons.email),

        const SizedBox(height: 30),

        // ===== Stats =====
        const Text(
          'Your Statistics',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text),
        ),
        const SizedBox(height: 12),

        _profileStatTile('Total Pickups', '$totalPickups'),
        _profileStatTile(
            'Total Waste Collected', '${totalWaste.toStringAsFixed(1)} kg'),
        StreamBuilder<int?>(
  stream: _collectorRankStream(),
  builder: (context, snapshot) {
    return _profileStatTile(
      'Leaderboard Rank',
      snapshot.hasData ? '#${snapshot.data}' : '--',
    );
  },
),


        const SizedBox(height: 30),

        // ===== Settings =====
        const Text(
          'Settings',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text),
        ),
        const SizedBox(height: 12),

        _buildSettingItem('Notifications', Icons.notifications, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AlertsScreen(userType: 'Collector'),
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

        // ===== Logout =====
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child:
                const Text('Logout', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    ),
  );
}
Widget _profileInfoTile(String label, String value, IconData icon) {
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
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _profileStatTile(String label, String value) {
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
        Text(label),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent)),
      ],
    ),
  );
}


Widget _infoTile(String label, String value, IconData icon) {
  return ListTile(
    leading: Icon(icon, color: AppColors.accent),
    title: Text(label),
      subtitle: Text(value),
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
