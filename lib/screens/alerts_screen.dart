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
        title: const Text('Alerts'),
        backgroundColor: AppColors.accent,
      ),
      body:StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('alerts')
.where('userType', isEqualTo: userType)
.orderBy('createdAt', descending: true)
.snapshots()
,

  builder: (context, snapshot) {

    // 🔄 LOADING
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ❌ ERROR
    if (snapshot.hasError) {
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    }

    // 📭 EMPTY STATE (MOST IMPORTANT)
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
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final data = alerts[index].data() as Map<String, dynamic>;

        return ListTile(
  leading: Icon(
    data['isRead'] == true
        ? Icons.notifications_none
        : Icons.notifications_active,
    color: data['isRead'] == true ? Colors.grey : Colors.green,
  ),
  title: Text(data['title'] ?? ''),
  subtitle: Text(data['message'] ?? ''),
  onTap: () {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(alerts[index].id)
        .update({'isRead': true});
  },
);

      },
    );
  },
),

    );
  }
}
