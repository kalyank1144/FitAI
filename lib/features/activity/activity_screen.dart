import 'package:flutter/material.dart';
import '../../core/components/metric_tile.dart';
import '../../core/theme/tokens.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            SizedBox(width: 160, child: MetricTile(title: 'Steps', value: '8,423')),
            SizedBox(width: 160, child: MetricTile(title: 'Heart Rate', value: '76 bpm', gradient: LinearGradient(colors: [AppTokens.neonCoral, AppTokens.neonMagenta]))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('GPS Sessions'),
            SizedBox(height: 8),
            Text('No outdoor runs yet.'),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => Chip(label: Text('Aug ${i + 1}')),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 14,
          ),
        ),
      ],
    );
  }
}