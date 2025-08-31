import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/env/env.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.env});
  final EnvConfig env;
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<Package> packages = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final offerings = await Purchases.getOfferings();
        setState(() => packages = offerings.current?.availablePackages ?? []);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitAI Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Unlock all features'),
            const SizedBox(height: 8),
            const Chip(label: Text('15-day free trial')),
            const SizedBox(height: 16),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && packages.isNotEmpty) ...[
              for (final p in packages)
                Card(
                  child: ListTile(
                    title: Text(p.storeProduct.title),
                    subtitle: Text(p.storeProduct.description),
                    trailing: FilledButton(
                      onPressed: () => Purchases.purchasePackage(p),
                      child: Text(p.storeProduct.priceString),
                    ),
                  ),
                ),
            ] else ...[
              const Text('Offerings loading… showing placeholders'),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Monthly'),
                  subtitle: const Text('15‑day free trial, then $9.99/mo'),
                  trailing: FilledButton(onPressed: null, child: const Text('Select')),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Yearly'),
                  subtitle: const Text('15‑day free trial, then $79.99/yr'),
                  trailing: FilledButton(onPressed: null, child: const Text('Select')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}