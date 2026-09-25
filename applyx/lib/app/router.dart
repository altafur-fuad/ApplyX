import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/goals/presentation/create_goal_screen.dart';
import '../../features/agent_runs/presentation/agent_activity_screen.dart';
import '../../features/opportunities/presentation/opportunity_results_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/applications/presentation/approval_screen.dart';
import '../../features/applications/presentation/application_tracker_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../core/theme/app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String createGoal = '/home/create-goal';
  static const String agentActivity = '/home/agent-activity';

  static const String opportunityResults = '/opportunity-results';
  static const String opportunityDetail =
      '/opportunity-results/opportunity-detail';

  static const String applicationTracker = '/application-tracker';
  static const String approval = '/application-tracker/approval';

  static const String profile = '/profile';
  static const String settings = '/profile/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellNavigatorResultsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellResults',
);
final _shellNavigatorTrackerKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellTracker',
);
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellProfile',
);

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authStateAsync.isLoading || !authStateAsync.hasValue) return null;

      final session = authStateAsync.value?.session;
      final isAuthenticated = session != null;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isSignup = state.matchedLocation == AppRoutes.signup;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      final isAuthRoute = isLogin || isSignup || isOnboarding || isSplash;

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'create-goal',
                    builder: (context, state) => const CreateGoalScreen(),
                  ),
                  GoRoute(
                    path: 'agent-activity',
                    builder: (context, state) => const AgentActivityScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorResultsKey,
            routes: [
              GoRoute(
                path: AppRoutes.opportunityResults,
                builder: (context, state) => const OpportunityResultsScreen(),
                routes: [
                  GoRoute(
                    path: 'opportunity-detail/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OpportunityDetailScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTrackerKey,
            routes: [
              GoRoute(
                path: AppRoutes.applicationTracker,
                builder: (context, state) => const ApplicationTrackerScreen(),
                routes: [
                  GoRoute(
                    path: 'approval/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ApprovalScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
