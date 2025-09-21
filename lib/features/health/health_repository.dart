import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthRepository {
  final HealthFactory _health = HealthFactory();

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<bool> requestPermissions() async {
    if (!supported) return false;
    final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];
    final rights = [HealthDataAccess.READ, HealthDataAccess.READ];
    return _health.requestAuthorization(types, permissions: rights);
  }
}
