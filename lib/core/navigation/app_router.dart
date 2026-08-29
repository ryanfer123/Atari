import 'package:go_router/go_router.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/onboarding/views/splash_screen.dart';
import '../../features/focus/views/focus_screen.dart';
import '../../features/goals/views/goals_screen.dart';
import '../../features/capture/views/capture_screen.dart';
import '../../features/gamification/views/gamification_screen.dart';
import '../../features/insights/views/insights_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/intervention/views/intervention_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/focus',
      builder: (context, state) => const FocusScreen(),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const GoalsScreen(),
    ),
    GoRoute(
      path: '/capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/gamification',
      builder: (context, state) => const GamificationScreen(),
    ),
    GoRoute(
      path: '/insights',
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/intervention',
      builder: (context, state) => const InterventionScreen(),
    ),
  ],
);
