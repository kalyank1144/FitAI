import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for tracking analytics events throughout the app.
class AnalyticsService {
  FirebaseAnalytics? get _fa => _tryAnalytics();

  /// Logs when the app is opened.
  void logAppOpen() => _log('app_open');
  
  /// Logs when onboarding is completed.
  void logOnboardingComplete() => _log('onboarding_complete');
  
  /// Logs when a workout is started.
  void logWorkoutStart() => _log('workout_start');
  
  /// Logs when a set is completed.
  void logSetComplete() => _log('set_complete');
  
  /// Logs when a workout session is completed.
  void logSessionComplete() => _log('session_complete');
  
  /// Logs when a personal record is unlocked.
  void logPrUnlocked() => _log('pr_unlocked');
  
  /// Logs when a recommendation is viewed.
  void logRecommendationView() => _log('recommendation_view');
  
  /// Logs when a recommendation is accepted.
  void logRecommendationAccept() => _log('recommendation_accept');
  
  /// Logs when nutrition is quickly added.
  void logNutritionQuickAdd() => _log('nutrition_quick_add');
  
  /// Logs when a barcode is scanned.
  void logBarcodeScan() => _log('barcode_scan');
  
  /// Logs when photo logging is started.
  void logPhotoLogStart() => _log('photo_log_start');
  
  /// Logs when photo logging is successful.
  void logPhotoLogSuccess() => _log('photo_log_success');
  
  /// Logs when a reminder is sent.
  void logReminderSent() => _log('reminder_sent');
  
  /// Logs when a reminder is tapped.
  void logReminderTapped() => _log('reminder_tapped');

  /// Logs a screen view event.
  void logScreenView(String name) {
    _fa?.logScreenView(screenName: name);
  }

  void _log(String name, [Map<String, Object?>? params]) {
    if (kDebugMode) debugPrint('Analytics: $name $params');
    _fa?.logEvent(name: name, parameters: params?.cast<String, Object>());
  }

  FirebaseAnalytics? _tryAnalytics() {
    try {
      return FirebaseAnalytics.instance;
    } on Exception catch (_) {
      return null;
    }
  }
}

/// Provider for the analytics service.
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);
