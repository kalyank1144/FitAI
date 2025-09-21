import 'dart:io' show Platform;

import 'package:fitai/core/env/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({required this.env, super.key});
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
        padding: const EdgeInsets.all(16),
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
                      onPressed: () async {
                        try {
                          await Purchases.purchasePackage(p);
                        } catch (e) {
                          if (kDebugMode) {
                            print('Purchase failed (development mode): $e');
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Purchase unavailable in development mode: $e'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
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
                  trailing: const FilledButton(onPressed: null, child: Text('Select')),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Yearly'),
                  subtitle: const Text('15‑day free trial, then $79.99/yr'),
                  trailing: const FilledButton(onPressed: null, child: Text('Select')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
