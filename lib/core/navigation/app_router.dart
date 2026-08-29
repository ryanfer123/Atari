import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main_layout_screen.dart';
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

// Helper for transparent routes in nested navigation
Page<dynamic> _buildTransparentPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    opaque: false, // THIS IS THE FIX: Prevents GoRouter from painting an opaque background!
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

// Create a global navigator key for the root router
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Top Level Routes (No Bottom Nav)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
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
      path: '/capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/intervention',
      builder: (context, state) => const InterventionScreen(),
    ),

    // Stateful Nested Routing (With Bottom Nav)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayoutScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Dashboard (Today)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => _buildTransparentPage(const DashboardScreen(), state),
            ),
          ],
        ),
        // Branch 1: Goals
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              pageBuilder: (context, state) => _buildTransparentPage(const GoalsScreen(), state),
            ),
          ],
        ),
        // Branch 2: Progress (Gamification)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/gamification',
              pageBuilder: (context, state) => _buildTransparentPage(const GamificationScreen(), state),
            ),
          ],
        ),
        // Branch 3: Insights
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              pageBuilder: (context, state) => _buildTransparentPage(const InsightsScreen(), state),
            ),
          ],
        ),
      ],
    ),
  ],
);
