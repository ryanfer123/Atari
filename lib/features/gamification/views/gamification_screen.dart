import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../../../core/widgets/atari_card.dart';
import '../../../core/theme/atari_theme.dart';
import '../../../core/models/view_state.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glowColor = AtariTheme.primaryYellow; // Using the fixed Yellow for both themes

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Progress')),
      body: Consumer<GamificationViewModel>(
        builder: (context, vm, child) {
          if (vm.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalActiveDays = vm.totalActiveDays;
          final daysSinceLastActive = vm.daysSinceLastActive;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Level Card
                AtariCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${vm.level}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('${vm.totalXp} XP earned in total', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vm.progressToNextLevel,
                          backgroundColor: glowColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(glowColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${vm.totalXp % (vm.xpToNextLevel > 0 ? vm.xpToNextLevel : 100)} / ${vm.xpToNextLevel} XP toward level ${vm.level + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Active Days Card
                AtariCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shared bounding box to guarantee identical centering
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: totalActiveDays == 0
                            ? const Align(
                                alignment: Alignment.bottomCenter, // Align to bottom so bases match
                                child: Icon(Icons.local_fire_department_outlined, size: 28),
                              )
                            : Align(
                                alignment: Alignment.bottomCenter, // Align to bottom so bases match
                                child: Lottie.asset(
                                  daysSinceLastActive == 0 
                                      ? 'assets/lotties/red_flame.json' 
                                      : 'assets/lotties/blue_flame.json',
                                  key: ValueKey(daysSinceLastActive == 0 ? 'red' : 'blue'),
                                  width: 38, // Slightly bigger than the 28px static icon
                                  height: 38,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You\'ve been active on $totalActiveDays days',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This only ever goes up. A quiet day pauses it - it never resets.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // How XP is earned section
                Text(
                  'How XP is earned',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                AtariCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _buildXpRow(context, 'Completing a task', 'Scaled by its difficulty'),
                      _buildXpRow(context, 'Meeting a health target', '10 XP'),
                      _buildXpRow(context, 'Organising a capture', '5 XP'),
                      _buildXpRow(context, 'An intervention that measurably helped', '15 XP', isLast: true),
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

  Widget _buildXpRow(BuildContext context, String title, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 16),
              Expanded(child: Text(title)),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
