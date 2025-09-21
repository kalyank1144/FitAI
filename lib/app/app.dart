import 'package:fitai/core/theme/app_theme.dart';
import 'package:fitai/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The main application widget that sets up the app's theme and routing.
class App extends ConsumerWidget {
  /// Creates an instance of [App].
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FitAI',
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
