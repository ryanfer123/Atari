import 'package:flutter/material.dart';

import '../../core/models/difficulty_tier.dart';
import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../engine/gamification/gamification_progress.dart';

/// XP, level and the active-day streak.
///
/// Everything here is derived from an append-only event log, so nothing
/// can decrease: a missed day pauses progress, it never subtracts. That
/// is a deliberate response to evidence that losable streaks increase
/// anxiety and compulsive checking (Plans/IMPLEMENTATION.md §4.7) — the
/// copy on this screen is written to match, using accomplishment
/// framing and never urgency or loss framing.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<GamificationProgress> _future;
  late Future<List<Todo>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _future = ServiceScope.of(context).gamification.currentProgress();
    _recentFuture = ServiceScope.of(
      context,
    ).todos.getRecentlyCompleted();
  }

  Future<void> _refresh() async {
    // Block body, not an arrow — see the note in DashboardScreen: an
    // arrow returns the assigned Future and trips setState's assert.
    setState(() {
      _future = ServiceScope.of(context).gamification.currentProgress();
      _recentFuture = ServiceScope.of(context).todos.getRecentlyCompleted();
    });
    await Future.wait([_future, _recentFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<GamificationProgress>(
          future: _future,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            if (progress == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final xpIntoLevel = progress.totalXp % xpPerLevel;
            final fraction = xpIntoLevel / xpPerLevel;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${progress.level}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Gap.xs,
                        Text(
                          '${progress.totalXp} XP earned in total',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        Gap.m,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 10,
                          ),
                        ),
                        Gap.s,
                        Text(
                          '$xpIntoLevel / $xpPerLevel XP toward level ${progress.level + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                Gap.m,
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Gap.m,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.activeDayCount == 1
                                    ? "You've been active on 1 day"
                                    : "You've been active on ${progress.activeDayCount} days",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Gap.xs,
                              Text(
                                'This only ever goes up. A quiet day pauses it — it never resets.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionHeader(title: 'Recently completed'),
                FutureBuilder<List<Todo>>(
                  future: _recentFuture,
                  builder: (context, recentSnapshot) {
                    final recent = recentSnapshot.data;
                    if (recent == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _RecentlyCompleted(todos: recent);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The last few finished tasks, in place of a static "how XP is earned"
/// price list — concrete completed work is more legible than a table of
/// rates, and it's exactly what this screen's accomplishment framing
/// (Plans/IMPLEMENTATION.md §4.7) is meant to reinforce.
class _RecentlyCompleted extends StatelessWidget {
  const _RecentlyCompleted({required this.todos});

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Nothing completed yet — it will show up here.'),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final todo in todos)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline, size: 20),
              title: Text(todo.title),
              subtitle: todo.completedAt == null
                  ? null
                  : Text(formatWhen(todo.completedAt!)),
              trailing: Text(
                '${xpForDifficulty(todo.difficulty ?? fallbackDifficultyTier)} XP',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
