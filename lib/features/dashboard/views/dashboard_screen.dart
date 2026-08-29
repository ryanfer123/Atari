import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../core/models/view_state.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../core/theme/space_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      appBar: AppBar(
        title: Text('A T A R I', style: Theme.of(context).textTheme.headlineMedium),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      child: Consumer<DashboardViewModel>(
        builder: (context, vm, child) {
          if (vm.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Header Card (Glassmorphism)
                ClipRRect(
                  borderRadius: BorderRadius.circular(0), // Keep sharp edges
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SYSTEM STATUS', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            Text(
                              vm.agentState.name.toUpperCase(), 
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                              )
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('XP / LEVEL', style: Theme.of(context).textTheme.labelLarge),
                                Text('${vm.gamification?.totalXp ?? 0} XP', style: Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => vm.simulateOverload(),
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('SIMULATE OVERLOAD'),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                Text('MODULES', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                
                // Module Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _buildModuleBtn(context, 'Onboarding', '/onboarding'),
                    _buildModuleBtn(context, 'Focus', '/focus'),
                    _buildModuleBtn(context, 'Goals', '/goals'),
                    _buildModuleBtn(context, 'Capture', '/capture'),
                    _buildModuleBtn(context, 'Gamification', '/gamification'),
                    _buildModuleBtn(context, 'Insights', '/insights'),
                    _buildModuleBtn(context, 'Settings', '/settings'),
                    _buildModuleBtn(context, 'Intervention', '/intervention'),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildModuleBtn(BuildContext context, String title, String route) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ElevatedButton(
          onPressed: () => context.go(route),
          child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ),
    );
  }
}
