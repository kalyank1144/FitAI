import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.onAuthStateChange.map((e) => e);
});

final sessionProvider = Provider<Session?>((ref) {
  final current = Supabase.instance.client.auth.currentSession;
  return current;
});
