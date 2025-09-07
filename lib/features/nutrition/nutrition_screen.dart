import 'package:fitai/core/components/progress_ring.dart';
import 'package:fitai/core/theme/tokens.dart';
import 'package:fitai/features/nutrition/ui/quick_add.dart';
import 'package:fitai/features/nutrition/data/nutrition_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(nutritionTodayProvider);
    final entries = ref.watch(nutritionEntriesProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: totals.when(
            loading: () => const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading nutrition data...'),
              ],
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to load nutrition data: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            data: (t) {
              final progress = (t.calories / 2000).clamp(0, 1).toDouble();
              return Column(
                children: [
                  Row(
                    children: [
                      ProgressRing(progress: progress, size: 96),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Goal',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${t.calories.toInt()} / 2000 kcal',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).toInt()}% of daily goal',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroInfo('Protein', '${t.proteinG.toInt()}g', Colors.blue),
                      _buildMacroInfo('Carbs', '${t.carbsG.toInt()}g', Colors.orange),
                      _buildMacroInfo('Fat', '${t.fatG.toInt()}g', Colors.green),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Quick add'),
            subtitle: const Text('Log macros fast'),
            trailing: FilledButton(
              onPressed: () async {
                await showModalBottomSheet(context: context, builder: (_) => QuickAddMacrosSheet());
              },
              child: const Text('Add'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('Scan barcode'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_camera_rounded), label: const Text('Meal photo'))),
        ]),
        const SizedBox(height: 24),
        // Today's Entries
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Entries",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              entries.when(
                loading: () => const Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading entries...'),
                  ],
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load entries: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (entryList) {
                  if (entryList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.no_meals, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No entries today',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Start logging your meals to track your nutrition',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: entryList.map((entry) {
                      final createdAt = entry['created_at']?.toString() ?? '';
                      final foodName = entry['food_name']?.toString() ?? 'Unknown food';
                      final calories = entry['calories'] ?? 0;
                      final protein = entry['protein'] ?? 0;
                      final carbs = entry['carbs'] ?? 0;
                      final fat = entry['fat'] ?? 0;
                      
                      // Format the time
                      var formattedTime = 'Unknown time';
                      if (createdAt.isNotEmpty) {
                        try {
                          final date = DateTime.parse(createdAt);
                          formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          formattedTime = createdAt;
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          foodName,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${calories.toInt()} kcal',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'P: ${protein.toInt()}g',
                                        style: TextStyle(color: Colors.blue[300], fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'C: ${carbs.toInt()}g',
                                        style: TextStyle(color: Colors.orange[300], fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'F: ${fat.toInt()}g',
                                        style: TextStyle(color: Colors.green[300], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMacroInfo(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getMacroIcon(label),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }
  
  IconData _getMacroIcon(String macro) {
    switch (macro.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center;
      case 'carbs':
        return Icons.grain;
      case 'fat':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }
}