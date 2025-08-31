import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  if (uid == null) return const Stream.empty();
  return c.from('profiles').stream(primaryKey: ['id']).eq('id', uid).limit(1).map((rows) => rows.isEmpty ? null : rows.first);
});

Future<void> saveFcmToken(String token) async {
  final c = Supabase.instance.client;
  await c.from('fcm_tokens').upsert({'token': token, 'platform': c.auth.currentSession?.user.userMetadata?['platform'] ?? ''});
}