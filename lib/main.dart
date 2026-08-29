import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/atari_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'features/goals/viewmodels/goals_viewmodel.dart';
import 'features/gamification/viewmodels/gamification_viewmodel.dart';
import 'features/insights/viewmodels/insights_viewmodel.dart';

void main() {
  setupFakes();
  runApp(const AtariApp());
}

class AtariApp extends StatelessWidget {
  const AtariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => getIt<DashboardViewModel>()..init()),
        ChangeNotifierProvider(create: (_) => getIt<GoalsViewModel>()..init()),
        ChangeNotifierProvider(create: (_) => getIt<GamificationViewModel>()..init()),
        ChangeNotifierProvider(create: (_) => getIt<InsightsViewModel>()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'ATARI Skeleton',
            theme: AtariTheme.lightTheme,
            darkTheme: AtariTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 1000), // Slow fade transition
            themeAnimationCurve: Curves.easeInOut,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
