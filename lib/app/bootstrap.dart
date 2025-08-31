import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env/env.dart';
import '../core/storage/local_db.dart';
import '../core/analytics/analytics.dart';
import '../core/messaging/messaging_service.dart';
import '../core/messaging/firebase_background.dart';
import '../features/subscriptions/subscription_service.dart';
import 'app.dart';

Future<void> bootstrap(Env env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await EnvConfig.load(env);

  await _initFirebase();
  _setupCrashlytics();

  await LocalDb.instance.init();
  await _initSupabase(config);
  await _initLocalNotifications();
  await MessagingService().init();
  await SubscriptionService(config).init();

  final container = ProviderContainer(
    overrides: [
      envProvider.overrideWithValue(config),
      analyticsProvider.overrideWithValue(AnalyticsService()),
    ],
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  runZonedGuarded(() {
    runApp(UncontrolledProviderScope(container: container, child: const App()));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init skipped: $e');
  }
}

void _setupCrashlytics() {
  if (kDebugMode) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
}

Future<void> _initSupabase(EnvConfig config) async {
  if (config.supabaseUrl.isEmpty || config.supabaseAnonKey.isEmpty) return;
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
    debug: kDebugMode,
  );
}

Future<void> _initLocalNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(initializationSettings);

  const channel = AndroidNotificationChannel(
    'reminders',
    'Reminders',
    description: 'Workout and streak reminders',
    importance: Importance.high,
  );
  await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics?>((ref) {
  try {
    return FirebaseAnalytics.instance;
  } catch (_) {
    return null;
  }
});