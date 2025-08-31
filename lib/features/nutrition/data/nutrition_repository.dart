import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionTotals {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  const NutritionTotals({this.calories = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
}

class NutritionRepository {
  final _client = Supabase.instance.client;

  Stream<NutritionTotals> watchToday() {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _client
        .from('nutrition_daily_totals')
        .stream(primaryKey: ['user_id','date'])
        .eq('date', today)
        .limit(1)
        .map((rows) {
      if (rows.isEmpty) return const NutritionTotals();
      final r = rows.first;
      return NutritionTotals(
        calories: (r['calories'] ?? 0) as int,
        proteinG: (r['protein_g'] ?? 0) as int,
        carbsG: (r['carbs_g'] ?? 0) as int,
        fatG: (r['fat_g'] ?? 0) as int,
      );
    });
  }

  Future<void> quickAdd({required int calories, int proteinG = 0, int carbsG = 0, int fatG = 0}) async {
    await _client.from('nutrition_entries').insert({
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    });
  }
}

final nutritionRepoProvider = Provider((_) => NutritionRepository());
final nutritionTodayProvider = StreamProvider<NutritionTotals>((ref) => ref.read(nutritionRepoProvider).watchToday());