import 'package:flutter/material.dart';
import '../../core/components/progress_ring.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: const [ProgressRing(progress: 0.62, size: 96), SizedBox(width: 16), Text('Daily Macros')]),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Quick add'),
            subtitle: const Text('Log macros fast'),
            trailing: FilledButton(onPressed: () {}, child: const Text('Add')),
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