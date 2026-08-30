import 'package:flutter/material.dart';

import '../../core/models/reminder.dart';
import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../engine/gamification/gamification_progress.dart';
import '../goals/todo_detail_screen.dart';
import '../settings/settings_screen.dart';

/// "Today" — what's due, what's scheduled, and current progress.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Created once. Building a Drift stream inside build() would open a
  // fresh subscription on every rebuild, and each emission would trigger
  // another rebuild — an endless loop that also hammers the database.
  late final Stream<List<Todo>> _todos = ServiceScope.of(context).todos
      .watchTopLevel();
  late final Stream<List<Reminder>> _reminders = ServiceScope.of(context)
      .reminders
      .watchAll();

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ATARI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                // Yellow reads fine on the dark background but is
                // near-invisible on the light one's near-white — see
                // AppTheme's accentForeground note on the same trade-off.
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.primaryYellow
                    : Colors.black87,
                letterSpacing: 3,
              ),
            ),
            const Text('Today'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<Todo>>(
        stream: _todos,
        builder: (context, todoSnapshot) {
          final todos = todoSnapshot.data ?? const <Todo>[];
          final open = todos.where((t) => !t.isCompleted).toList();
          final dueSoon = open.where((t) => t.deadline != null).toList()
            ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

          final now = DateTime.now();
          final completedToday = todos.where((t) {
            final c = t.completedAt;
            return c != null &&
                c.year == now.year &&
                c.month == now.month &&
                c.day == now.day;
          }).length;

          return ListView(
            padding: const EdgeInsets.only(bottom: 140),
            children: [
              if (services.placeholderCapabilities.isNotEmpty)
                _PlaceholderNotice(
                  capabilities: services.placeholderCapabilities,
                ),
              _ProgressSummary(
                completedToday: completedToday,
                openCount: open.length,
              ),
              const SectionHeader(title: 'Due soon'),
              if (dueSoon.isEmpty)
                const _InlineEmpty(
                  text: 'Nothing with a deadline. Capture something or add a task.',
                )
              else
                ...dueSoon.take(5).map((t) => _TodoTile(todo: t)),
              const SectionHeader(title: 'Scheduled'),
              _UpcomingReminders(reminders: _reminders),
            ],
          );
        },
      ),
    );
  }
}

/// Names exactly which capabilities are still deterministic stand-ins,
/// so a partially-filled set of model slots is never reported as either
/// fully loaded or fully empty.
class _PlaceholderNotice extends StatelessWidget {
  const _PlaceholderNotice({required this.capabilities});

  final List<String> capabilities;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = capabilities.length == 1
        ? capabilities.single
        : '${capabilities.take(capabilities.length - 1).join(', ')} '
              'and ${capabilities.last}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.science_outlined, color: scheme.onSurfaceVariant),
              Gap.m,
              Expanded(
                child: Text(
                  'Still using placeholders for $list. '
                  'Add the models in Settings to replace them.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Re-reads progress whenever the counts it's shown alongside change,
/// which is the only time XP can have moved.
class _ProgressSummary extends StatefulWidget {
  const _ProgressSummary({
    required this.completedToday,
    required this.openCount,
  });

  final int completedToday;
  final int openCount;

  @override
  State<_ProgressSummary> createState() => _ProgressSummaryState();
}

class _ProgressSummaryState extends State<_ProgressSummary> {
  late Future<GamificationProgress> _progress = ServiceScope.of(context)
      .gamification
      .currentProgress();

  @override
  void didUpdateWidget(_ProgressSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedToday != widget.completedToday ||
        oldWidget.openCount != widget.openCount) {
      // Block body, not an arrow: an arrow would *return* the assigned
      // Future, and setState asserts its callback returns nothing (the
      // check that catches accidentally-async callbacks). That assert
      // firing here threw inside the enclosing ListView's update, which
      // left the viewport's re-entrancy flag stuck and blanked the whole
      // screen on the next rebuild.
      setState(() {
        _progress = ServiceScope.of(context).gamification.currentProgress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: FutureBuilder<GamificationProgress>(
        future: _progress,
        builder: (context, snapshot) {
          final progress = snapshot.data;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Stat(value: '${progress?.level ?? 1}', label: 'Level'),
                  _Stat(value: '${progress?.totalXp ?? 0}', label: 'XP'),
                  _Stat(value: '${widget.completedToday}', label: 'Done today'),
                  _Stat(value: '${widget.openCount}', label: 'Open'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingReminders extends StatelessWidget {
  const _UpcomingReminders({required this.reminders});

  final Stream<List<Reminder>> reminders;

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    return StreamBuilder<List<Reminder>>(
      stream: reminders,
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? const <Reminder>[])
            .where((r) => r.isPending)
            .toList();
        if (pending.isEmpty) {
          return const _InlineEmpty(
            text: 'Nothing scheduled. Reminders you confirm will show here.',
          );
        }
        return Column(
          children: [
            for (final r in pending.take(5))
              ListTile(
                leading: Icon(
                  r.tool.name == 'setAlarm'
                      ? Icons.alarm
                      : Icons.notifications_outlined,
                ),
                title: Text(r.title),
                subtitle: Text(formatWhen(r.scheduledFor)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: () async {
                    await services.reminderScheduler.cancel(r.id);
                    await services.reminders.cancel(r.id);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        todo.isOverdue ? Icons.error_outline : Icons.radio_button_unchecked,
      ),
      iconColor: todo.isOverdue ? scheme.error : null,
      title: Text(todo.title),
      subtitle: todo.deadline == null ? null : Text(formatWhen(todo.deadline!)),
      trailing: todo.difficulty == null
          ? null
          : DifficultyChip(tier: todo.difficulty!),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TodoDetailScreen(todoId: todo.id)),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
