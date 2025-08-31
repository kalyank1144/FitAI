import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  FirebaseAnalytics? get _fa => _tryAnalytics();

  void logAppOpen() => _log('app_open');
  void logOnboardingComplete() => _log('onboarding_complete');
  void logWorkoutStart() => _log('workout_start');
  void logSetComplete() => _log('set_complete');
  void logSessionComplete() => _log('session_complete');
  void logPrUnlocked() => _log('pr_unlocked');
  void logRecommendationView() => _log('recommendation_view');
  void logRecommendationAccept() => _log('recommendation_accept');
  void logNutritionQuickAdd() => _log('nutrition_quick_add');
  void logBarcodeScan() => _log('barcode_scan');
  void logPhotoLogStart() => _log('photo_log_start');
  void logPhotoLogSuccess() => _log('photo_log_success');
  void logReminderSent() => _log('reminder_sent');
  void logReminderTapped() => _log('reminder_tapped');

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
    } catch (_) {
      return null;
    }
  }
}

final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());