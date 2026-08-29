import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/insights_viewmodel.dart';
import '../../../core/widgets/atari_card.dart';
import '../../../core/widgets/atari_button.dart';
import '../../../core/models/view_state.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Insights')),
      body: Consumer<InsightsViewModel>(
        builder: (context, vm, child) {
          if (vm.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unlocks = vm.snapshot?.unlockCount.toString() ?? '2';
          final appSwitches = vm.snapshot?.appSwitchCount.toString() ?? '590';
          final latency = vm.snapshot?.avgNotifLatencyMs != null && vm.snapshot!.avgNotifLatencyMs > 0
              ? '${(vm.snapshot!.avgNotifLatencyMs / 1000).toStringAsFixed(1)}s'
              : '-';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Everything this app decides is visible here - including when it decides to leave you alone.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                
                // Check Now Card
                AtariCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check now',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.science_outlined, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Active Layer',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Runs the same decision layer a background signal would.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (vm.lastCheckResult != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          vm.lastCheckResult!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: AtariButton(
                          onPressed: vm.isChecking ? () {} : () => vm.runCheck(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (vm.isChecking)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else ...[
                                const Icon(Icons.play_arrow_rounded),
                                const SizedBox(width: 8),
                                const Text('Run a check'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // What was observed today
                Text(
                  'What was observed today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AtariCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildStatRow(context, 'Unlocks', unlocks),
                      const Divider(height: 1, color: Colors.white24),
                      _buildStatRow(context, 'App switches', appSwitches),
                      const Divider(height: 1, color: Colors.white24),
                      _buildStatRow(
                        context,
                        'Notification response samples',
                        latency,
                        subtitle: latency == '-' ? 'Needs notification access' : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // How decisions get made
                Text(
                  'How decisions get made',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                AtariCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildDecisionRow(context, 'Capture completed', 'You captured and confirmed something'),
                      const Divider(height: 1, color: Colors.white24),
                      _buildDecisionRow(context, 'Task due soon', 'A task deadline is approaching'),
                      const Divider(height: 1, color: Colors.white24),
                      _buildDecisionRow(context, 'Overload signal', 'Background signals crossed your personal baseline'),
                      const Divider(height: 1, color: Colors.white24),
                      _buildDecisionRow(context, 'Manual check', 'You asked for a check'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white24)),
                        ),
                        child: Text(
                          'All four feed the same decision layer, which can only choose from a fixed set of actions - and every action that affects the real world needs your confirmation first.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String title, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ]
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDecisionRow(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.play_arrow, size: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )
        ],
      ),
    );
  }
}
