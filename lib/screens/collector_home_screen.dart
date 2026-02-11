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
  
  // Map to keep track of weight inputs for each pending request
  final Map<String, TextEditingController> _weightControllers = {};

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
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
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
            // --- Pending Section ---
            _buildSectionTitle('Pending Pickups', pendingDocs.length.toString()),
            const SizedBox(height: 12),
            
            if (pendingDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No pending pickups', 
                    style: TextStyle(color: Colors.grey[400],fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...pendingDocs.map((doc) => _buildPickupCard(doc, isPending: true)),

            const SizedBox(height: 24),
            
            // --- Completed Section ---
            _buildSectionTitle('Completed History', completedDocs.length.toString()),
            const SizedBox(height: 12),

            if (completedDocs.isEmpty)
              Padding(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 child: Center(
                   child: Text(
                     'No completed pickups', 
                     style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                   ),
                 ),
              )
            else
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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            data['giverPhone']?.toString() ?? 'No Phone',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (!isPending && data.containsKey('weight')) ...[
                        const SizedBox(height: 6),
                         Text(
                           'Collected: ${data['weight']} kg',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 13),
                         )
                      ]
                    ],
                  ),
                ),
                if (!isPending)
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
            if (isPending) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _weightControllers.putIfAbsent(doc.id, () => TextEditingController()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Enter Weight (kg)',
                  hintText: 'e.g. 2.5',
                  isDense: true,
                  prefixIcon: const Icon(Icons.scale_rounded, size: 20, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    try {
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final freshDoc = await transaction.get(doc.reference);
                        if (freshDoc['status'] != 'pending') {
                          throw Exception("Request is not pending (Status: ${freshDoc['status']})");
                        }

                        final data = freshDoc.data() as Map<String, dynamic>;
                        final weightText = _weightControllers[doc.id]?.text.trim();
                        if (weightText == null || weightText.isEmpty) {
                          throw Exception("Please enter the weight first.");
                        }

                        final enteredWeight = double.tryParse(weightText);
                        if (enteredWeight == null || enteredWeight <= 0) {
                          throw Exception("Please enter a valid weight greater than 0.");
                        }

                        double parsedWeight = enteredWeight;

                        final collectorRef = FirebaseFirestore.instance.collection('collectorusers').doc(user.uid);

                        transaction.update(doc.reference, {
                          'status': 'completed',
                          'weight': parsedWeight,
                          'completedAt': FieldValue.serverTimestamp(),
                        });

                        transaction.update(collectorRef, {
                          'totalPickups': FieldValue.increment(1),
                          'totalWaste': FieldValue.increment(parsedWeight),
                          'points': FieldValue.increment(10),
                        });

                        if (data['giverId'] != null) {
                          final giverRef = FirebaseFirestore.instance.collection('giverusers').doc(data['giverId']);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Complete Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
                        _infoTile('Phone', data['giverPhone']?.toString() ?? 'No Phone', Icons.phone_rounded),
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
          _buildSettingItem('About App', Icons.info_rounded, () {
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

