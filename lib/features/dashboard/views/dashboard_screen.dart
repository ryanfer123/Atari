import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../core/models/view_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Screen')),
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, child) {
          if (vm.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Agent State: ${vm.agentState.name}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text('XP: ${vm.gamification?.totalXp ?? 0}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => vm.simulateOverload(),
                  child: const Text('Simulate Overload'),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () => context.go('/onboarding'), child: const Text('Onboarding')),
                    ElevatedButton(onPressed: () => context.go('/focus'), child: const Text('Focus')),
                    ElevatedButton(onPressed: () => context.go('/goals'), child: const Text('Goals')),
                    ElevatedButton(onPressed: () => context.go('/capture'), child: const Text('Capture')),
                    ElevatedButton(onPressed: () => context.go('/gamification'), child: const Text('Gamification')),
                    ElevatedButton(onPressed: () => context.go('/insights'), child: const Text('Insights')),
                    ElevatedButton(onPressed: () => context.go('/settings'), child: const Text('Settings')),
                    ElevatedButton(onPressed: () => context.go('/intervention'), child: const Text('Intervention')),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
