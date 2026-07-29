import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();

    if (token != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    });
  }
}
