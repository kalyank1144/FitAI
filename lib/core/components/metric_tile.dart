import 'package:fitai/core/theme/app_theme.dart';
import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({required this.title, required this.value, super.key, this.gradient, this.icon, this.color, this.onTap});
  final String title;
  final String value;
  final Gradient? gradient;
  final IconData? icon;
  final Color? color;
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
                    Icon(icon!, color: color ?? Colors.white70, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}