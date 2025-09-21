import 'package:fitai/core/theme/app_theme.dart';
import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A tile widget that displays a metric with title and value.
class MetricTile extends StatelessWidget {
  /// Creates a metric tile with the given title and value.
  const MetricTile({
    required this.title,
    required this.value,
    super.key,
    this.gradient,
    this.icon,
    this.color,
    this.onTap,
  });
  
  /// The title text displayed at the top of the tile.
  final String title;
  
  /// The value text displayed prominently in the tile.
  final String value;
  
  /// Optional gradient for the tile border.
  final Gradient? gradient;
  
  /// Optional icon displayed next to the title.
  final IconData? icon;
  
  /// Optional color for the icon.
  final Color? color;
  
  /// Optional callback when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GradientBorder(
        gradient: gradient ?? AppTokens.perfGradient,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color ?? Colors.white70, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
