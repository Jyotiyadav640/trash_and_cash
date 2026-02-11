import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  final String userType;
  const AlertsScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
  title: const Text('Notifications'),
  backgroundColor: AppColors.accent,

  actions: [
    IconButton(
      icon: const Icon(Icons.delete_forever),
      onPressed: () async {
        final uid = FirebaseAuth.instance.currentUser!.uid;

        final snap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .get();

        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      },
    ),
  ],
),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications') // ✅ SAME collection
            .where('userId', isEqualTo: uid) // ✅ SECURITY
            .where('userType', isEqualTo: userType)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ ERROR
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 📭 EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No alerts available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final doc = alerts[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] == true;

              return GestureDetector(
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .update({'read': true});
                },
                onLongPress: () async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(doc.id)
        .delete();
  },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.shade300
                          : Colors.green,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isRead
                                    ? Colors.black87
                                    : Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(data['createdAt']),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
