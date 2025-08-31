import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Env { dev, stg, prod }

class EnvConfig {
  final Env env;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenuecatApiKey;
  final String stripePublishableKey;
  final String stripePriceId;
  final String mapsApiKey;
  final String oauthRedirectUri;
  final String webRedirectUrl;

  const EnvConfig({
    required this.env,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenuecatApiKey,
    required this.stripePublishableKey,
    required this.stripePriceId,
    required this.mapsApiKey,
    required this.oauthRedirectUri,
    required this.webRedirectUrl,
  });

  static Future<EnvConfig> load([Env? override]) async {
    final fallback = _fromString(const String.fromEnvironment('ENV', defaultValue: 'dev'));
    final env = override ?? fallback;
    final file = switch (env) {
      Env.dev => '.env.dev',
      Env.stg => '.env.stg',
      Env.prod => '.env.prod',
    };
    await dotenv.load(fileName: file);
    return EnvConfig(
      env: env,
      supabaseUrl: dotenv.get('SUPABASE_URL', fallback: ''),
      supabaseAnonKey: dotenv.get('SUPABASE_ANON_KEY', fallback: ''),
      revenuecatApiKey: dotenv.get('REVENUECAT_API_KEY', fallback: ''),
      stripePublishableKey: dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: ''),
      stripePriceId: dotenv.get('STRIPE_PRICE_ID', fallback: ''),
      mapsApiKey: dotenv.get('MAPS_API_KEY', fallback: ''),
      oauthRedirectUri: dotenv.get('OAUTH_REDIRECT_URI', fallback: ''),
      webRedirectUrl: dotenv.get('WEB_REDIRECT_URL', fallback: ''),
    );
  }

  static Env _fromString(String v) {
    switch (v) {
      case 'prod':
        return Env.prod;
      case 'stg':
      case 'staging':
        return Env.stg;
      default:
        return Env.dev;
    }
  }

  bool get isWeb => kIsWeb;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
}