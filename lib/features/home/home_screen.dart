import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/metric_tile.dart';
import '../../core/components/progress_ring.dart';
import '../../core/theme/tokens.dart';
import '../train/data/program_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProgramsProvider);
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
              MetricTile(title: 'Steps', value: '—'),
              MetricTile(title: 'Calories', value: '—', gradient: LinearGradient(colors: [AppTokens.neonCoral, AppTokens.neonMagenta])),
              MetricTile(title: 'HR', value: '—'),
              MetricTile(title: 'Sleep', value: '—'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 180, child: _FeaturedCarousel(featured: featured)),
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

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.featured});
  final AsyncValue<List<dynamic>> featured;
  @override
  Widget build(BuildContext context) {
    return featured.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _FeaturedCard(title: 'No featured programs yet'),
            ],
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (c, i) => _FeaturedCard(title: items[i].name, coverUrl: items[i].coverUrl),
          separatorBuilder: (c, _) => const SizedBox(width: 12),
          itemCount: items.length,
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.title, this.coverUrl});
  final String title;
  final String? coverUrl;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTokens.perfGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (coverUrl != null && coverUrl!.isNotEmpty)
            Positioned.fill(child: Image.network(coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}