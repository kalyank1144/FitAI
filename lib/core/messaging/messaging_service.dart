import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for storing the FCM token state.
final fcmTokenProvider = StateProvider<String?>((_) => null);

/// Service for handling Firebase Cloud Messaging operations.
class MessagingService {
  /// Firebase Messaging instance.
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  
  /// Initializes the messaging service and requests permissions.
  Future<void> init() async {
    try {
      await _fm.requestPermission();
      final token = await _fm.getToken();
      if (kDebugMode) debugPrint('FCM token: $token');
    } catch (e) {
      if (kDebugMode) debugPrint('Messaging init skipped: $e');
    }
  }

  /// Requests permission and gets the FCM token, storing it in the provider.
  /// 
  /// Returns the FCM token if successful, null otherwise.
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
