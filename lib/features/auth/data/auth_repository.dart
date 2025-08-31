import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env/env.dart';

class AuthRepository {
  AuthRepository(this._env);
  final EnvConfig _env;
  final _supabase = Supabase.instance.client;
  final _localAuth = LocalAuthentication();

  Future<void> signInWithGoogle() async {
    final redirect = kIsWeb ? _env.webRedirectUrl : _env.oauthRedirectUri;
    await _supabase.auth.signInWithOAuth(Provider.google, redirectTo: redirect);
  }

  Future<void> signInWithApple() async {
    final redirect = kIsWeb ? _env.webRedirectUrl : _env.oauthRedirectUri;
    await _supabase.auth.signInWithOAuth(Provider.apple, redirectTo: redirect);
  }

  Future<bool> biometricsAvailable() => _localAuth.canCheckBiometrics;
  Future<bool> biometricsAuthenticate() => _localAuth.authenticate(localizedReason: 'Unlock FitAI');
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.read(envProvider);
  return AuthRepository(env);
});