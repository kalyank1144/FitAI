import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionTotals {
  const NutritionTotals({this.calories = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
}

class NutritionRepository {
  final _client = Supabase.instance.client;

  Stream<NutritionTotals> watchToday() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(const NutritionTotals());
    }
    
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _client
        .from('nutrition_daily_totals')
        .stream(primaryKey: ['user_id','date'])
        .map((rows) {
      // Filter for current user and today's date
      final filteredRows = rows.where((row) => 
        row['user_id'] == userId && row['date'] == today
      ).toList();
      
      if (filteredRows.isEmpty) return const NutritionTotals();
      final r = filteredRows.first;
      return NutritionTotals(
        calories: (r['calories'] ?? 0) as int,
        proteinG: (r['protein_g'] ?? 0) as int,
        carbsG: (r['carbs_g'] ?? 0) as int,
        fatG: (r['fat_g'] ?? 0) as int,
      );
    });
  }
  
  Stream<List<Map<String, dynamic>>> watchEntries() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }
    
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final todayStart = '${today}T00:00:00Z';
    final todayEnd = '${DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String().substring(0, 10)}T00:00:00Z';
    
    return _client
        .from('nutrition_entries')
        .stream(primaryKey: ['id'])
        .map((rows) {
      // Filter for current user and today's entries
      final filteredRows = rows.where((row) {
        final rowUserId = row['user_id'];
        final rowTime = row['time'];
        return rowUserId == userId && 
               rowTime != null && 
               rowTime.compareTo(todayStart) >= 0 && 
               rowTime.compareTo(todayEnd) < 0;
      }).toList();
      
      // Sort by time descending
      filteredRows.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
      return filteredRows;
    });
  }

  Future<void> quickAdd({required int calories, int proteinG = 0, int carbsG = 0, int fatG = 0}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to add nutrition entries');
    }
    
    await _client.from('nutrition_entries').insert({
      'user_id': userId,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    });
  }
}

final nutritionRepoProvider = Provider((_) => NutritionRepository());
final nutritionTodayProvider = StreamProvider<NutritionTotals>((ref) => ref.read(nutritionRepoProvider).watchToday());
final nutritionEntriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) => ref.read(nutritionRepoProvider).watchEntries());