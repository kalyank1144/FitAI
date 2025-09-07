import 'package:fitai/core/components/metric_tile.dart';
import 'package:fitai/core/components/progress_ring.dart';
import 'package:fitai/core/theme/tokens.dart';
import 'package:fitai/features/activity/data/activity_repository.dart';
import 'package:fitai/features/auth/data/auth_repository.dart';
import 'package:fitai/features/profile/data/profile_repository.dart';
import 'package:fitai/features/train/data/program_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProgramsProvider);
    final profile = ref.watch(profileStreamProvider);
    final activityToday = ref.watch(activityTodayProvider);
    final authRepo = ref.read(authRepositoryProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh activity data
        ref.invalidate(activityTodayProvider);
        ref.invalidate(featuredProgramsProvider);
        ref.invalidate(profileProvider);
        // Wait a bit for the providers to refresh
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
        SliverAppBar.large(
          expandedHeight: 200,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: profile.when(
              loading: () => const Text('Today'),
              error: (_, __) => const Text('Today'),
              data: (profileData) {
                final name = profileData?['full_name']?.toString().split(' ').first ?? 
                           authRepo.currentUser?.email?.split('@').first ?? 
                           'User';
                return Text('Hello, $name');
              },
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(decoration: BoxDecoration(gradient: AppTokens.perfGradient.withOpacity(0.15))),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GestureDetector(
                      onTap: () => context.go('/train'),
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
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildListDelegate([
              activityToday.when(
                loading: () => const MetricTile(
                  title: 'Steps',
                  value: '...',
                  icon: Icons.directions_walk,
                  color: Colors.blue,
                ),
                error: (_, __) => const MetricTile(
                  title: 'Steps',
                  value: '0',
                  icon: Icons.directions_walk,
                  color: Colors.blue,
                ),
                data: (activity) => MetricTile(
                  title: 'Steps',
                  value: activity?.steps.toString() ?? '0',
                  icon: Icons.directions_walk,
                  color: Colors.blue,
                  onTap: () => context.go('/activity'),
                ),
              ),
              activityToday.when(
                loading: () => const MetricTile(
                  title: 'Calories',
                  value: '...',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                error: (_, __) => const MetricTile(
                  title: 'Calories',
                  value: '0',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                data: (activity) => MetricTile(
                  title: 'Calories',
                  value: activity?.calories.toString() ?? '0',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  onTap: () => context.go('/nutrition'),
                ),
              ),
              activityToday.when(
                loading: () => const MetricTile(
                  title: 'Distance',
                  value: '...',
                  icon: Icons.route,
                  color: Colors.green,
                ),
                error: (_, __) => const MetricTile(
                  title: 'Distance',
                  value: '0 km',
                  icon: Icons.route,
                  color: Colors.green,
                ),
                data: (activity) {
                  final distance = activity?.distance ?? 0.0;
                  return MetricTile(
                    title: 'Distance',
                    value: '${distance.toStringAsFixed(1)} km',
                    icon: Icons.route,
                    color: Colors.green,
                    onTap: () => context.go('/activity'),
                  );
                },
              ),
              activityToday.when(
                loading: () => const MetricTile(
                  title: 'Active Time',
                  value: '...',
                  icon: Icons.timer,
                  color: Colors.purple,
                ),
                error: (_, __) => const MetricTile(
                  title: 'Active Time',
                  value: '0 min',
                  icon: Icons.timer,
                  color: Colors.purple,
                ),
                data: (activity) {
                  final activeMinutes = activity?.activeMinutes ?? 0;
                  return MetricTile(
                    title: 'Active Time',
                    value: '$activeMinutes min',
                    icon: Icons.timer,
                    color: Colors.purple,
                    onTap: () => context.go('/activity'),
                  );
                },
              ),
            ]),
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
      ),
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
    return GestureDetector(
      onTap: () => context.go('/train'),
      child: Container(
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
      ),
    );
  }
}