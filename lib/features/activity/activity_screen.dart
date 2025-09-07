import 'package:fitai/core/components/metric_tile.dart';
import 'package:fitai/core/theme/tokens.dart';
import 'package:fitai/features/activity/data/activity_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          loading: () => const SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Loading today's activity..."),
                ],
              ),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Failed to load activity data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Error: $e', style: TextStyle(color: Colors.red[700])),
                const SizedBox(height: 8),
                Text('Please check your connection and try again.', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),
          data: (d) {
            if (d == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text('No activity data for today', style: TextStyle(color: Colors.orange)),
                    Text('Start moving to see your stats!', style: TextStyle(color: Colors.orange[700])),
                  ],
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: MetricTile(
                    title: 'Steps',
                    value: '${d.steps}',
                    icon: Icons.directions_walk,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(
                  width: 160,
                  child: MetricTile(
                    title: 'Heart Rate',
                    value: '—',
                    icon: Icons.favorite,
                    gradient: LinearGradient(colors: [AppTokens.neonCoral, AppTokens.neonMagenta]),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: MetricTile(
                    title: 'Calories',
                    value: '${d.calories}',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: MetricTile(
                    title: 'Distance',
                    value: '0.0 km',
                    icon: Icons.route,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
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
                  const Icon(Icons.gps_fixed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'GPS Sessions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              gps.when(
                loading: () => const Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading GPS sessions...'),
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
                          'Failed to load GPS sessions: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.directions_run, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No outdoor activities yet',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Start a GPS workout to see your sessions here',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: rows.map((session) {
                      final startedAt = session['started_at']?.toString() ?? '';
                      final distanceM = session['distance_m'] ?? 0;
                      final distanceKm = (distanceM / 1000).toStringAsFixed(2);
                      final duration = session['duration_minutes']?.toString() ?? '0';
                      
                      // Format the date
                      var formattedDate = 'Unknown date';
                      if (startedAt.isNotEmpty) {
                        try {
                          final date = DateTime.parse(startedAt);
                          formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          formattedDate = startedAt;
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
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_run,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.route, size: 16, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$distanceKm km',
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.timer, size: 16, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$duration min',
                                        style: TextStyle(color: Colors.grey[400]),
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
}