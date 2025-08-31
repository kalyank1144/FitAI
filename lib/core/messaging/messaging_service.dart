import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fcmTokenProvider = StateProvider<String?>((_) => null);

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

  Future<String?> requestAndGetToken(WidgetRef ref) async {
    try {
      await _fm.requestPermission();
      final t = await _fm.getToken();
      ref.read(fcmTokenProvider.notifier).state = t;
      return t;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token error: $e');
      return null;
    }
  }
}