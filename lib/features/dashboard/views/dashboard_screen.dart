import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../core/models/view_state.dart';
import '../../../core/widgets/atari_button.dart';
import '../../../core/theme/theme_toggle_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainLayoutScreen
      appBar: AppBar(
        title: Text('A T A R I', style: Theme.of(context).textTheme.headlineMedium),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, child) {
          if (vm.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            // Add substantial bottom padding so content isn't hidden behind the floating navbar
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 160.0),
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
                
                AtariButton(
                  isSecondary: true,
                  onPressed: () => vm.simulateOverload(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded),
                      const SizedBox(width: 8),
                      const Text('SIMULATE OVERLOAD'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
