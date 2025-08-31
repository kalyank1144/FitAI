import 'package:flutter/material.dart';
import '../../core/components/neon_focus.dart';

class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 9,
          itemBuilder: (_, i) => Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Squat')),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start Workout')),
      ],
    );
  }
}