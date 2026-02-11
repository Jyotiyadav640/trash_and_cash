const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const userId = data.userId;
    const userType = data.userType;

    const userDoc = await admin
      .firestore()
      .collection(`${userType}users`)
      .doc(userId)
      .get();

    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: data.title,
        body: data.body,
      },
      token: fcmToken,
    };

    return admin.messaging().send(payload);
  });
