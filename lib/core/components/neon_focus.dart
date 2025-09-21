import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A widget that adds a neon glow effect to its child when focused or hovered.
class NeonFocus extends StatelessWidget {
  /// Creates a [NeonFocus] widget.
  const NeonFocus({required this.child, super.key});
  
  /// The child widget to wrap with the neon focus effect.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTokens.fast,
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(
            color: AppTokens.neonTeal,
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ]),
        child: child,
      ),
    );
  }
}