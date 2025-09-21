import 'package:fitai/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._env);
  final EnvConfig _env;
  final SupabaseClient _supabase = Supabase.instance.client;
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
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return _supabase.auth.signUp(
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
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear any cached data if needed
      // Note: Supabase automatically clears session data
    } catch (e) {
      // Even if signOut fails, we should clear local session
      // This handles cases where network is unavailable
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
  
  /// Check if user session is valid and not expired
  bool get isSessionValid {
    final session = currentSession;
    if (session == null) return false;
    
    // Check if session is expired
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isBefore(expiresAt);
  }
  
  /// Refresh the current session if needed
  Future<AuthResponse?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      // If refresh fails, the session is likely invalid
      return null;
    }
  }
  
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.read(envConfigProvider);
  return AuthRepository(env);
});
