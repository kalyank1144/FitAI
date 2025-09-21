import 'package:fitai/core/analytics/analytics.dart';
import 'package:fitai/core/env/env.dart';
import 'package:fitai/features/activity/activity_screen.dart';
import 'package:fitai/features/auth/ui/sign_in_screen.dart';
import 'package:fitai/features/home/home_screen.dart';
import 'package:fitai/features/nutrition/nutrition_screen.dart';
import 'package:fitai/features/onboarding/onboarding_flow.dart';
import 'package:fitai/features/profile/profile_screen.dart';
import 'package:fitai/features/train/train_screen.dart';
import 'package:fitai/features/train/workout_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the application router configuration.
final routerProvider = Provider<GoRouter>((ref) {
  final analytics = ref.read(analyticsProvider);
  final env = ref.read(envConfigProvider);
  return GoRouter(
    initialLocation: '/auth',
    observers: [GoRouteObserver(analytics)],
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == '/auth';
      
      // Check for dev mode bypass
      var devBypass = false;
      if (env.env == Env.dev) {
        final prefs = await SharedPreferences.getInstance();
        devBypass = prefs.getBool('dev_auth_bypass') ?? false;
      }
      
      if (session == null && !isAuthRoute && !devBypass) {
        return '/auth';
      }
      if ((session != null || devBypass) && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (c, s) => const SignInScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingFlow()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (c, s) => const HomeScreen())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/train',
              builder: (c, s) => const TrainScreen(),
              routes: [
                GoRoute(
                  path: 'session',
                  builder: (c, s) {
                    final programId = s.uri.queryParameters['programId'];
                    return WorkoutSessionScreen(programId: programId);
                  },
                ),
                GoRoute(
                  path: 'session/:sessionId',
                  builder: (c, s) {
                    final sessionId = s.pathParameters['sessionId']!;
                    return WorkoutSessionScreen(sessionId: sessionId);
                  },
                ),
              ],
            )
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/activity',
              builder: (c, s) => const ActivityScreen(),
            )
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/nutrition',
              builder: (c, s) => const NutritionScreen(),
            )
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (c, s) => const ProfileScreen(),
            )
          ]),
        ],
      ),
    ],
  );
});

/// Main application scaffold that provides bottom navigation.
class AppScaffold extends ConsumerStatefulWidget {
  /// Creates an instance of [AppScaffold].
  const AppScaffold({required this.shell, super.key});
  
  /// The navigation shell for managing different app sections.
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
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_gymnastics_rounded),
            label: 'Train',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_rounded),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Observer for tracking route changes and logging screen views.
class GoRouteObserver extends NavigatorObserver {
  /// Creates an instance of [GoRouteObserver].
  GoRouteObserver(this.analytics);
  
  /// The analytics service for logging screen views.
  final AnalyticsService analytics;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    analytics.logScreenView(
      route.settings.name ?? route.settings.runtimeType.toString(),
    );
  }
}
