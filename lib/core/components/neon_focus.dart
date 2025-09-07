import 'package:fitai/core/theme/tokens.dart';
import 'package:flutter/material.dart';

class NeonFocus extends StatelessWidget {
  const NeonFocus({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTokens.fast,
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(color: AppTokens.neonTeal, blurRadius: 12, spreadRadius: 0.5),
        ]),
        child: child,
      ),
    );
  }
}