import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/goals/presentation/create_goal_screen.dart';
import '../../features/agent_runs/presentation/agent_activity_screen.dart';
import '../../features/opportunities/presentation/opportunity_results_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/applications/presentation/approval_screen.dart';
import '../../features/applications/presentation/application_tracker_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// ApplyX route paths — named constants to avoid typos.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String createGoal = '/create-goal';
  static const String agentActivity = '/agent-activity';
  static const String opportunityResults = '/opportunity-results';
  static const String opportunityDetail = '/opportunity-detail';
  static const String approval = '/approval';
  static const String applicationTracker = '/application-tracker';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Application router configuration.
///
/// Navigation flow documented in the task specification:
/// Splash → Onboarding → Login → Home
/// Home → Create Goal → Agent Activity → Results → Detail → Approval
/// Home → Application Tracker
/// Home → Profile → Settings
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
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
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.createGoal,
      builder: (context, state) => const CreateGoalScreen(),
    ),
    GoRoute(
      path: AppRoutes.agentActivity,
      builder: (context, state) => const AgentActivityScreen(),
    ),
    GoRoute(
      path: AppRoutes.opportunityResults,
      builder: (context, state) => const OpportunityResultsScreen(),
    ),
    GoRoute(
      path: AppRoutes.opportunityDetail,
      builder: (context, state) => const OpportunityDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.approval,
      builder: (context, state) => const ApprovalScreen(),
    ),
    GoRoute(
      path: AppRoutes.applicationTracker,
      builder: (context, state) => const ApplicationTrackerScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
