import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/metric_tile.dart';
import '../../core/theme/tokens.dart';
import 'data/activity_repository.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(activityTodayProvider);
    final gps = ref.watch(gpsStreamProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        today.when(
          loading: () => const SizedBox(height: 64, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Failed to load activity: $e'),
          data: (d) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 160, child: MetricTile(title: 'Steps', value: '${d.steps}')),
              const SizedBox(width: 160, child: MetricTile(title: 'Heart Rate', value: '—', gradient: LinearGradient(colors: [AppTokens.neonCoral, AppTokens.neonMagenta]))),
              SizedBox(width: 160, child: MetricTile(title: 'Calories', value: '${d.calories}')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GPS Sessions'),
            const SizedBox(height: 8),
            gps.when(
              loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (rows) => rows.isEmpty
                  ? const Text('No outdoor runs yet.')
                  : Column(
                      children: rows
                          .map((r) => ListTile(
                                title: Text((r['started_at'] ?? '').toString()),
                                subtitle: Text('Distance: ${r['distance_m'] ?? 0} m'),
                              ))
                          .toList(),
                    ),
            ),
          ]),
        ),
      ],
    );
  }
}