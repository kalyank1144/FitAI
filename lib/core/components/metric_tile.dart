import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.title, required this.value, this.gradient});
  final String title;
  final String value;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return GradientBorder(
      gradient: gradient ?? AppTokens.perfGradient,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}