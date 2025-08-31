import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/progress_ring.dart';
import 'data/nutrition_repository.dart';
import 'capture/quick_add.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(nutritionTodayProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        totals.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error: $e'),
          data: (t) {
            final progress = (t.calories / 2000).clamp(0, 1).toDouble();
            return Row(children: [
              ProgressRing(progress: progress, size: 96),
              const SizedBox(width: 16),
              Text('Daily Macros: ${t.calories} kcal'),
            ]);
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Quick add'),
            subtitle: const Text('Log macros fast'),
            trailing: FilledButton(
              onPressed: () async {
                await showModalBottomSheet(context: context, builder: (_) => const QuickAddMacrosSheet());
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
      ],
    );
  }
}