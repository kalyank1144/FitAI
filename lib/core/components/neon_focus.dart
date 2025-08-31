import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class NeonFocus extends StatelessWidget {
  const NeonFocus({super.key, required this.child});
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