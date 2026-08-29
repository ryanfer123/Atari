import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'features/dashboard/viewmodels/dashboard_viewmodel.dart';

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
        ChangeNotifierProvider(create: (_) => getIt<DashboardViewModel>()..init()),
      ],
      child: MaterialApp.router(
        title: 'ATARI Skeleton',
        theme: ThemeData.dark(),
        routerConfig: appRouter,
      ),
    );
  }
}
