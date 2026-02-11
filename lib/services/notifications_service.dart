import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String userId,
    required String userType, // giver / collector
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': userId,
      'userType': userType,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
