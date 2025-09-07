import 'package:fitai/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._env);
  final EnvConfig _env;
  final _supabase = Supabase.instance.client;
  final _localAuth = LocalAuthentication();

  Future<void> signInWithGoogle() async {
    final redirect = kIsWeb ? _env.webRedirectUrl : _env.oauthRedirectUri;
    await _supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirect);
  }

  Future<void> signInWithApple() async {
    final redirect = kIsWeb ? _env.webRedirectUrl : _env.oauthRedirectUri;
    await _supabase.auth.signInWithOAuth(OAuthProvider.apple, redirectTo: redirect);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<bool> biometricsAvailable() => _localAuth.canCheckBiometrics;
  Future<bool> biometricsAuthenticate() => _localAuth.authenticate(localizedReason: 'Unlock FitAI');
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.read(envProvider);
  return AuthRepository(env);
});