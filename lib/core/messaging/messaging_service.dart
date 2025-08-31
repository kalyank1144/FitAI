import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final _fm = FirebaseMessaging.instance;
  Future<void> init() async {
    try {
      await _fm.requestPermission();
      final token = await _fm.getToken();
      if (kDebugMode) debugPrint('FCM token: $token');
    } catch (e) {
      if (kDebugMode) debugPrint('Messaging init skipped: $e');
    }
  }
}