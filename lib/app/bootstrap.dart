import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitai/app/app.dart';
import 'package:fitai/core/analytics/analytics.dart';
import 'package:fitai/core/env/env.dart';
import 'package:fitai/core/messaging/firebase_background.dart';
import 'package:fitai/core/messaging/messaging_service.dart';
import 'package:fitai/core/storage/local_db.dart';
import 'package:fitai/features/subscriptions/subscription_service.dart';
import 'package:fitai/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bootstraps the application with the given environment configuration.
/// 
/// This function initializes all necessary services including Firebase,
/// Supabase, notifications, and error handling.
Future<void> bootstrap(Env env) async {
  // Initialize Flutter bindings within the zone for web compatibility
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final config = await EnvConfig.load(env);

    await _initFirebase();
    _setupCrashlytics();

    await LocalDb.instance.init();
    await _initSupabase(config);
    
    // Skip notifications and messaging on web platform
    if (!kIsWeb) {
      await _initLocalNotifications();
      await MessagingService().init();
    }
    
    try {
      await SubscriptionService(config).init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionService initialization failed: $e');
      }
      // Continue app initialization even if subscription service fails
    }

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWith((ref) => Future.value(config)),
        analyticsProvider.overrideWithValue(AnalyticsService()),
      ],
    );

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    };

    runApp(UncontrolledProviderScope(container: container, child: const App()));
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    }
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
  });
}

Future<void> _initFirebase() async {
  try {
    // Skip Firebase initialization on web to avoid configuration issues
    if (kIsWeb) {
      if (kDebugMode) debugPrint('Firebase init skipped on web platform');
      return;
    }
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init skipped: $e');
  }
}

void _setupCrashlytics() {
  // Firebase Crashlytics is not supported on web platform
  if (kIsWeb) return;
  
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
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Provider for Firebase Analytics instance.
/// 
/// Returns null on web if Firebase Analytics is not properly configured.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics?>((ref) {
  try {
    // Skip Firebase Analytics on web if not properly configured
    if (kIsWeb) {
      return null;
    }
    return FirebaseAnalytics.instance;
  } catch (_) {
    return null;
  }
});