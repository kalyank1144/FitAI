import 'package:flutter/material.dart';
import 'features/subscriptions/paywall_screen.dart';
import '../core/env/env.dart';

class PaywallEntryButton extends StatelessWidget {
  const PaywallEntryButton({super.key, required this.env});
  final EnvConfig env;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaywallScreen(env: env))),
      child: const Text('Unlock Pro'),
    );
  }
}