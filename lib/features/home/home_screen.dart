import 'package:flutter/material.dart';
import '../../core/components/metric_tile.dart';
import '../../core/components/progress_ring.dart';
import '../../core/theme/tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          expandedHeight: 200,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Today'),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(decoration: BoxDecoration(gradient: AppTokens.perfGradient.withOpacity(0.15))),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        ProgressRing(progress: 0.68, size: 72),
                        SizedBox(width: 16),
                        Text('Resume session', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              MetricTile(title: 'Steps', value: '7,842'),
              MetricTile(title: 'Calories', value: '1,230', gradient: LinearGradient(colors: [AppTokens.neonCoral, AppTokens.neonMagenta])),
              MetricTile(title: 'HR', value: '74 bpm'),
              MetricTile(title: 'Sleep', value: '7h 42m'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (c, i) => Container(
                width: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: i.isEven ? AppTokens.perfGradient : AppTokens.activityGradient,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              separatorBuilder: (c, _) => const SizedBox(width: 12),
              itemCount: 6,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTokens.neonTeal.withOpacity(0.3)),
              ),
              child: const Text('Streak: 5 days 🔥'),
            ),
          ),
        ),
      ],
    );
  }
}