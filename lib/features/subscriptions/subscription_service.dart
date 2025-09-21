import 'dart:io' show Platform;

import 'package:fitai/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  SubscriptionService(this._env);
  final EnvConfig _env;

  Future<void> init() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Purchases.configure(PurchasesConfiguration(_env.revenuecatApiKey)..appUserID = null);
      } catch (e) {
        if (kDebugMode) {
          print('RevenueCat initialization failed (development mode): $e');
        }
        // Continue without RevenueCat in development/testing environments
      }
    }
  }

  Future<bool> isPro() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.active.isNotEmpty;
      } catch (e) {
        if (kDebugMode) {
          print('RevenueCat customer info failed (development mode): $e');
        }
        // Return false in development/testing environments when RevenueCat fails
        return false;
      }
    }
    return false;
  }
}
