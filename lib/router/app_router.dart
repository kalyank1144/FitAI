import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_screen.dart';
import '../features/train/train_screen.dart';
import '../features/activity/activity_screen.dart';
import '../features/nutrition/nutrition_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../core/analytics/analytics.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final analytics = ref.read(analyticsProvider);
  return GoRouter(
    initialLocation: '/onboarding',
    observers: [if (analytics != null) GoRouteObserver(analytics!)],
    routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingFlow()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppScaffold(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/train', builder: (c, s) => const TrainScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/activity', builder: (c, s) => const ActivityScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/nutrition', builder: (c, s) => const NutritionScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen())]),
        ],
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
});

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int get currentIndex => widget.shell.currentIndex;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: widget.shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.sports_gymnastics_rounded), label: 'Train'),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.restaurant_rounded), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class GoRouteObserver extends NavigatorObserver {
  GoRouteObserver(this.analytics);
  final AnalyticsService analytics;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    analytics.logScreenView(route.settings.name ?? route.settings.runtimeType.toString());
  }
}