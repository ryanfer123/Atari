import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../../../core/models/view_state.dart';
import '../../../core/widgets/atari_card.dart';
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
            physics: const BouncingScrollPhysics(),
            // Add substantial bottom padding so content isn't hidden behind the floating navbar
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 160.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Warning Card
                AtariCard(
                  padding: const EdgeInsets.all(16),
                  isSecondary: true,
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'No on-device models loaded. Text extraction, difficulty and explanations are coming from deterministic placeholders.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2. Stats Grid Card
                AtariCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(context, '1', 'Level'),
                      _buildStatColumn(context, '0', 'XP'),
                      _buildStatColumn(context, '0', 'Done today'),
                      _buildStatColumn(context, '0', 'Open'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Due Soon Section
                Text('Due soon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Nothing with a deadline. Capture something or add a task.'),
                
                const SizedBox(height: 32),

                // 4. Scheduled Section
                Text('Scheduled', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Nothing scheduled. Reminders you confirm will show here.'),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
