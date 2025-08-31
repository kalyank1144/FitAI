import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/neon_focus.dart';
import 'data/exercise_repository.dart';

class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseStreamProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Programs', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => NeonFocus(
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Hypertrophy Base'),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Exercise Library', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        exercisesAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Failed to load exercises: $e'),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('No exercises found.'),
                    SizedBox(height: 8),
                    Text('Add rows to the "exercises" table in Supabase (id, name, primary_muscle, equipment, media_url). Updates appear in real-time.'),
                  ],
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final ex = items[i];
                return _ExerciseTile(name: ex.name, mediaUrl: ex.mediaUrl);
              },
            );
          },
        ),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start Workout')),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.name, this.mediaUrl});
  final String name;
  final String? mediaUrl;
  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset('assets/placeholder/exercise.png', fit: BoxFit.cover);
    Widget image;
    if (mediaUrl == null || mediaUrl!.isEmpty) {
      image = placeholder;
    } else {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mediaUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (c, w, p) => p == null ? w : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: image,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}