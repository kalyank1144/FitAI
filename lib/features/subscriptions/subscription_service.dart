import 'dart:io' show Platform;

import 'package:fitai/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  SubscriptionService(this._env);
  final EnvConfig _env;

  Future<void> init() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Purchases.configure(PurchasesConfiguration(_env.revenuecatApiKey)..appUserID = null);
    }
  }

  Future<bool> isPro() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.isNotEmpty;
    }
    return false;
  }
}
