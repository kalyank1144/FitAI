import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Environment configuration enum.
enum Env { 
  /// Development environment.
  dev, 
  /// Staging environment.
  stg, 
  /// Production environment.
  prod 
}

/// Configuration class that holds environment-specific settings.
class EnvConfig {

  /// Creates an [EnvConfig] instance with the required configuration values.
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
  
  /// The current environment.
  final Env env;
  
  /// The Supabase project URL.
  final String supabaseUrl;
  
  /// The Supabase anonymous key.
  final String supabaseAnonKey;
  
  /// The RevenueCat API key.
  final String revenuecatApiKey;
  
  /// The Stripe publishable key.
  final String stripePublishableKey;
  
  /// The Stripe price ID for subscriptions.
  final String stripePriceId;
  
  /// The Google Maps API key.
  final String mapsApiKey;
  
  /// The OAuth redirect URI.
  final String oauthRedirectUri;
  
  /// The web redirect URL.
  final String webRedirectUrl;

  /// Loads the environment configuration from the appropriate .env file.
  /// 
  /// If [override] is provided, it will be used instead of the environment variable.
  static Future<EnvConfig> load([Env? override]) async {
    final fallback = _fromString(
      const String.fromEnvironment('ENV', defaultValue: 'dev'),
    );
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

  /// Returns true if running on web platform.
  bool get isWeb => kIsWeb;
  
  /// Returns true if running on Android platform.
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Returns true if running on iOS platform.
  bool get isIOS => !kIsWeb && Platform.isIOS;
}

/// Provider for the environment configuration.
/// This is an async provider that loads the configuration from .env files.
final envProvider = FutureProvider<EnvConfig>((ref) async {
  return await EnvConfig.load();
});

/// Synchronous provider for the environment configuration.
/// This should only be used after the async provider has loaded successfully.
final envConfigProvider = Provider<EnvConfig>((ref) {
  final envAsync = ref.watch(envProvider);
  return envAsync.when(
    data: (config) => config,
    loading: () => throw StateError('Environment configuration is still loading'),
    error: (error, stack) => throw StateError('Failed to load environment configuration: $error'),
  );
});
