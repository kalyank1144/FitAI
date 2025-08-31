import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityToday {
  final int steps;
  final int calories;
  final int avgHr;
  const ActivityToday({this.steps = 0, this.calories = 0, this.avgHr = 0});
}

class ActivityRepository {
  final _client = Supabase.instance.client;
  Stream<ActivityToday> watchToday() {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _client
        .from('activity_daily')
        .stream(primaryKey: ['id'])
        .eq('date', today)
        .limit(1)
        .map((rows) {
      if (rows.isEmpty) return const ActivityToday();
      final r = rows.first;
      return ActivityToday(
        steps: (r['steps'] ?? 0) as int,
        calories: (r['calories'] ?? 0) as int,
        avgHr: (r['avg_hr'] ?? 0) as int,
      );
    });
  }

  Stream<List<Map<String, dynamic>>> watchGps() => _client.from('gps_sessions').stream(primaryKey: ['id']).order('started_at', ascending: false).limit(20);
}

final activityRepoProvider = Provider((_) => ActivityRepository());
final activityTodayProvider = StreamProvider<ActivityToday>((ref) => ref.read(activityRepoProvider).watchToday());
final gpsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) => ref.read(activityRepoProvider).watchGps());