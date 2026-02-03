import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String userId,
    required String userType, // giver / collector / admin
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection('notifications1').add({
      'userId': userId,
      'userType': userType,
      'title': title,
      'body': body,
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }
}
