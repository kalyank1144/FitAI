import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () async {
                await repo.signInWithGoogle();
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await repo.signInWithApple();
              },
              icon: const Icon(Icons.apple_rounded),
              label: const Text('Continue with Apple'),
            ),
            const Spacer(),
            const Text('By continuing you agree to our Terms.'),
          ],
        ),
      ),
    );
  }
}