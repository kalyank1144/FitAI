import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler for Firebase Cloud Messaging.
/// This function is called when the app receives a message while in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    // ignore: avoid_print
    print('BG message: ${message.messageId}');
  }
}
