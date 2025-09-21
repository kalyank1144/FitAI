import 'package:fitai/core/env/env.dart';
import 'package:fitai/features/subscriptions/paywall_screen.dart';
import 'package:flutter/material.dart';

class PaywallEntryButton extends StatelessWidget {
  const PaywallEntryButton({required this.env, super.key});
  final EnvConfig env;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaywallScreen(env: env))),
      child: const Text('Unlock Pro'),
    );
  }
}
