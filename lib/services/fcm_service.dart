// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FcmService {
//   static Future<void> saveFcmToken(String userType) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final token = await FirebaseMessaging.instance.getToken();
//     if (token == null) return;

//     await FirebaseFirestore.instance
//         .collection('${userType}users')
//         .doc(user.uid)
//         .update({
//       'fcmToken': token,
//     });
//   }
// }


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  // 🔹 INIT (call once after login)
  static Future<void> init() async {
    try {
      if (!kIsWeb) {
        await _messaging.requestPermission();
      }
    } catch (_) {
      // silently ignore
    }
  }

  // 🔹 GET TOKEN (safe)
  static Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  // 🔹 SAVE TOKEN (NO CRASH GUARANTEE)
  static Future<void> saveFcmToken(String userType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (_) {
      token = null;
    }

    if (token == null) return;

    final ref = FirebaseFirestore.instance
        .collection('${userType}users')
        .doc(user.uid);

    // ✅ merge = true prevents NOT_FOUND crash
    await ref.set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

