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
  bool isFirstLogin = false;
  // ---- EDIT MODE FLAGS ----
bool isEditingName = false;
bool isEditingPhone = false;
bool isEditingEmail = false;
final TextEditingController _reportController = TextEditingController();
bool isSubmittingReport = false;


// ---- CONTROLLERS ----
final TextEditingController _nameEditController = TextEditingController();
final TextEditingController _phoneEditController = TextEditingController();
final TextEditingController _emailEditController = TextEditingController();

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

      if (doc.exists) {
        final firstLoginFromDb = doc['isFirstLogin'] ?? false;

        if (firstLoginFromDb == true) {
          await FirebaseFirestore.instance
              .collection('collectorusers')
              .doc(user.uid)
              .update({'isFirstLogin': false});
        }

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
          isFirstLogin = firstLoginFromDb;
          
          _nameEditController.text = name;
          _phoneEditController.text = phone;
          _emailEditController.text = email;
          
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    final uid = user.uid;

    await for (final snapshot in FirebaseFirestore.instance
        .collection('collectorusers')
        .orderBy('totalPickups', descending: true)
        .snapshots()) {

      int rank = 1;
      int? previousPickups;

      for (var doc in snapshot.docs) {
        final pickups = doc['totalPickups'] ?? 0;

        if (previousPickups != null && pickups < previousPickups) {
          rank++;
        }

        if (doc.id == uid) {
          yield rank;
          break;
        }

        previousPickups = pickups;
      }
    }
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    _phoneEditController.dispose();
    _emailEditController.dispose();
    _reportController.dispose();
    super.dispose();
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

  if (mounted) {
    setState(() => isSubmittingReport = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report sent to admin')),
    );
  }
}


  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4), // Premium Off-White
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Modern Header
          _buildModernHeader(),

          // 2. Stats (Overlapping)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernStats(),
            ),
          ),

          // 3. Pickups List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHomePickups(),
          ),
        ],
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
          image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
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
                isFirstLogin ? 'Welcome,' : 'Welcome Back,',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.isNotEmpty ? name : 'Collector',
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
          _buildModernStatItem('Pickups', '$totalPickups', Icons.local_shipping_rounded, Colors.blue),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildModernStatItem('Waste', '${totalWaste.toStringAsFixed(1)} kg', Icons.recycling_rounded, Colors.green),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StreamBuilder<int?>(
            stream: _collectorRankStream(),
            builder: (context, snapshot) {
              final rankText = snapshot.hasData ? '#${snapshot.data}' : '--';
              return _buildModernStatItem('Rank', rankText, Icons.emoji_events_rounded, Colors.orange);
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
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
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
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
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








  Widget _buildHomePickups() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('collectorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        final pendingDocs = docs.where((d) {
          final status = (d['status'] ?? '').toString().toLowerCase();
          return status == 'pending';
        }).toList();

        final completedDocs = docs.where((d) {
          final status = (d['status'] ?? '').toString().toLowerCase();
          return status == 'completed';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headers
            if (pendingDocs.isNotEmpty) 
              _buildSectionTitle('Pending Pickups', pendingDocs.length.toString()),
            if (pendingDocs.isNotEmpty) const SizedBox(height: 12),

            ...pendingDocs.map((doc) => _buildPickupCard(doc, isPending: true)),

            if (pendingDocs.isEmpty && completedDocs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No activity yet', style: TextStyle(color: Colors.grey)),
                ),
              ),

            const SizedBox(height: 24),
            
            if (completedDocs.isNotEmpty)
              _buildSectionTitle('Completed History', completedDocs.length.toString()),
            if (completedDocs.isNotEmpty) const SizedBox(height: 12),

            ...completedDocs.map((doc) => _buildPickupCard(doc, isPending: false)),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupCard(DocumentSnapshot doc, {required bool isPending}) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
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
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                color: isPending ? Colors.orange : Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserNameDisplay(
                    giverId: data['giverId'] ?? '',
                    currentName: data['giverName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.recycling_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${data['material']} • ${data['weight'] ?? data['approxWeight'] ?? '0'} kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPending)
              InkWell(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  try {
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      // 🔥 LOCK DOCUMENT
                      final freshDoc = await transaction.get(doc.reference);

                      if (freshDoc['status'] != 'pending') {
                         throw Exception("Request is not pending (Status: ${freshDoc['status']})");
                      }

                      final data = freshDoc.data() as Map<String, dynamic>;

                      // 🔥 SAFE PARSING
                      double parsedWeight = 0.0;
                      final w = data['weight'];
                      final aw = data['approxWeight'];

                      if (w is num) {
                        parsedWeight = w.toDouble();
                      } else if (w is String) {
                        parsedWeight = double.tryParse(w) ?? 0.0;
                      }

                      if (parsedWeight == 0.0) {
                        if (aw is num) {
                          parsedWeight = aw.toDouble();
                        } else if (aw is String) {
                          parsedWeight = double.tryParse(aw) ?? 0.0;
                        }
                      }

                      final collectorRef = FirebaseFirestore.instance
                          .collection('collectorusers')
                          .doc(user.uid);

                      // 1. Mark as Completed (Do NOT change collectorId, rely on existing)
                      transaction.update(doc.reference, {
                        'status': 'completed',
                        'completedAt': FieldValue.serverTimestamp(),
                      });

                      // 2. Update Collector Stats
                      transaction.update(collectorRef, {
                        'totalPickups': FieldValue.increment(1),
                        'totalWaste': FieldValue.increment(parsedWeight),
                        'points': FieldValue.increment(10),
                      });

                      // 3. Update Giver Stats (if valid)
                      if (data['giverId'] != null) {
                        final giverRef = FirebaseFirestore.instance
                            .collection('giverusers')
                            .doc(data['giverId']);
                            
                        transaction.update(giverRef, {
                          'points': FieldValue.increment(10),
                          'totalWaste': FieldValue.increment(parsedWeight),
                        });
                      }
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pickup Completed Successfully!')),
                      );
                    }

                    await NotificationService.sendNotification(
                      userId: doc['giverId'],
                      userType: 'giver',
                      title: 'Pickup Completed',
                      body: 'Your trash has been successfully collected by $name',
                    );
                  } catch (e) {
                    debugPrint("Error completing pickup: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              )
            else
               Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Done', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
          ],
        ),
      ),
    );
  }

  // ================= PICKUPS =================
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No pickup requests available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final pickups = snapshot.data!.docs;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: pickups.length,
          itemBuilder: (context, index) {
            final doc = pickups[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
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
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF1B5E20), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: UserNameDisplay(
                            giverId: data['giverId'] ?? '',
                            currentName: data['giverName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Open', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoTile('Location', data['address'] ?? 'Unknown', Icons.location_on_rounded),
                        const SizedBox(height: 12),
                        _infoTile('Material', data['material'] ?? 'Unknown', Icons.recycling_rounded),
                        const SizedBox(height: 12),
                        _infoTile('Weight', '${data['weight'] ?? data['approxWeight'] ?? '0'} kg', Icons.scale_rounded),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('pickup_requests')
                                  .doc(doc.id)
                                  .update({'status': 'rejected'});
                            },
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;
                              
                              // 🔥 ACCEPT TRANSACTION (Prevent multiple collectors accepting)
                              await FirebaseFirestore.instance.runTransaction((transaction) async {
                                final fresh = await transaction.get(doc.reference);

                                if (fresh['status'] != 'open') return;

                                transaction.update(doc.reference, {
                                  'status': 'pending',
                                  'collectorId': user.uid,
                                });
                              });

                              await NotificationService.sendNotification(
                                userId: data['giverId'],
                                userType: 'giver',
                                title: 'Pickup Accepted',
                                body: '$name has accepted your pickup request',
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                            label: const Text('Accept', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(24),
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
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1B5E20), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                 name.isNotEmpty ? name : 'Collector',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Personal Info
          const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Full Name',
            value: name,
            controller: _nameEditController,
            isEditing: isEditingName,
            icon: Icons.person_outline_rounded,
            onEdit: () => setState(() => isEditingName = true),
            onUpdate: () async {
              await FirebaseFirestore.instance.collection('collectorusers').doc(FirebaseAuth.instance.currentUser!.uid).update({'name': _nameEditController.text});
              setState(() { name = _nameEditController.text; isEditingName = false; });
            },
          ),

          _buildEditableField(
            label: 'Mobile Number',
            value: phone,
            controller: _phoneEditController,
            isEditing: isEditingPhone,
            icon: Icons.phone_outlined,
            onEdit: () => setState(() => isEditingPhone = true),
            onUpdate: () async {
              await FirebaseFirestore.instance.collection('collectorusers').doc(FirebaseAuth.instance.currentUser!.uid).update({'phone': _phoneEditController.text});
              setState(() { phone = _phoneEditController.text; isEditingPhone = false; });
            },
          ),

          _buildEditableField(
            label: 'Email Address',
            value: email,
            controller: _emailEditController,
            isEditing: isEditingEmail,
            icon: Icons.email_outlined,
            onEdit: () => setState(() => isEditingEmail = true),
            onUpdate: () async {
              await FirebaseFirestore.instance.collection('collectorusers').doc(FirebaseAuth.instance.currentUser!.uid).update({'email': _emailEditController.text});
              setState(() { email = _emailEditController.text; isEditingEmail = false; });
            },
          ),

          const SizedBox(height: 32),

          // Stats
          const Text('Your Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          _profileStatTile('Total Pickups', '$totalPickups', Icons.local_shipping_outlined),
          _profileStatTile('Total Waste', '${totalWaste.toStringAsFixed(1)} kg', Icons.delete_outline_rounded),
          StreamBuilder<int?>(
            stream: _collectorRankStream(),
            builder: (context, snapshot) {
              return _profileStatTile(
                'Global Rank',
                snapshot.hasData ? '#${snapshot.data}' : '--',
                Icons.emoji_events_outlined,
              );
            },
          ),

          const SizedBox(height: 32),

          // Report Issue
          const Text('Report Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe your issue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                const SizedBox(height: 12),
                TextField(
                  controller: _reportController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmittingReport ? null : () => _submitReport('collector'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isSubmittingReport
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Settings
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 16),
          _buildSettingItem('Notifications', Icons.notifications_outlined, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen(userType: 'Collector')));
          }),
          _buildSettingItem('Privacy & Security', Icons.lock_outline_rounded, () {}),
          _buildSettingItem('Help & Support', Icons.help_outline_rounded, () {}),
          _buildSettingItem('About App', Icons.info_outline_rounded, () {}),

          const SizedBox(height: 40),

          // Logout
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _showLogoutDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFFFEBEE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
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
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
              ),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
              const Spacer(),
              if (!isEditing)
                InkWell(
                  onTap: onEdit,
                  child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 18, color: Colors.grey[400])),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ),
                TextButton(onPressed: onUpdate, child: const Text('Done', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold))),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(value.isNotEmpty ? value : 'Not set', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ),
        ],
      ),
    );
  }

  Widget _profileStatTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF1B5E20), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)))),
      ],
    );
  }

  Widget _buildSettingItem(String label, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)))),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class UserNameDisplay extends StatelessWidget {
  final String giverId;
  final String? currentName;
  final TextStyle? style;

  const UserNameDisplay({
    super.key,
    required this.giverId,
    this.currentName,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (currentName != null &&
        currentName!.isNotEmpty &&
        currentName != 'Unknown') {
      return Text(currentName!, style: style ?? const TextStyle(fontWeight: FontWeight.bold));
    }

    if (giverId.isEmpty) {
      return Text('Unknown', style: style ?? const TextStyle(fontWeight: FontWeight.bold));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('giverusers').doc(giverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...', style: TextStyle(color: Colors.grey));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Text(
            data['name'] ?? 'Unknown',
            style: style ?? const TextStyle(fontWeight: FontWeight.bold),
          );
        }

        return Text('Unknown', style: style ?? const TextStyle(fontWeight: FontWeight.bold));
      },
    );
  }
}

