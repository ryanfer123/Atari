import 'package:flutter/material.dart';

import '../../core/models/difficulty_tier.dart';
import '../../core/models/gamification_event.dart';
import '../../core/models/reminder.dart';
import '../../core/models/subtask_spec.dart';
import '../../core/models/task_tool.dart';
import '../../core/models/todo.dart';
import '../../core/services/model_services.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/model_backend_badge.dart';
import 'reminder_sheet.dart';

/// A single task: its difficulty, subtasks, and scheduled reminders.
///
/// Decomposition and the tool-call chips both live here — a model
/// *proposes* subtasks and an action, and each one needs a tap before it
/// becomes real (Plans/ARCHITECTURE.md §3).
class TodoDetailScreen extends StatefulWidget {
  const TodoDetailScreen({super.key, required this.todoId});

  final int todoId;

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  Todo? _todo;
  DecompositionResult? _decomposition;
  bool _decomposing = false;

  // Created once — see the note in DashboardScreen on why building a
  // stream inside build() loops.
  late final Stream<List<Todo>> _subtasks = ServiceScope.of(context).todos
      .watchSubtasksOf(widget.todoId);
  late final Stream<List<Reminder>> _reminders = ServiceScope.of(context)
      .reminders
      .watchAll();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todo = await ServiceScope.of(context).todos.findById(widget.todoId);
    if (mounted) setState(() => _todo = todo);
  }

  Future<void> _rescore() async {
    final todo = _todo;
    if (todo == null) return;
    final services = ServiceScope.of(context);
    final deadline = todo.deadline;
    final nearby = deadline == null
        ? const <Todo>[]
        : await services.todos.withDeadlineNear(deadline, excludingId: todo.id);
    final tier = await services.difficultyScorer.score(
      title: todo.title,
      notes: todo.notes,
      deadline: deadline,
      nearbyTasks: nearby,
    );
    await services.todos.setDifficulty(todo.id, tier);
    await _load();
  }

  Future<void> _decompose() async {
    final todo = _todo;
    if (todo == null) return;
    setState(() => _decomposing = true);
    final result = await ServiceScope.of(context).taskDecomposer
        .decompose(title: todo.title, notes: todo.notes);
    if (mounted) {
      setState(() {
        _decomposition = result;
        _decomposing = false;
      });
    }
  }

  /// Confirm gate for one proposed subtask — nothing is written until
  /// this runs (Plans/PIVOT_PLAN.md §2.4).
  Future<void> _acceptSubtask(SubtaskSpec spec) async {
    final services = ServiceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = await services.todos.create(
      title: spec.title,
      difficulty: spec.tier,
      parentId: widget.todoId,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added "${spec.title}" · ${xpForDifficulty(spec.tier)} XP',
        ),
      ),
    );

    // The model may propose a timing tool alongside the step. Carrying
    // that proposal into the reminder sheet is the whole point of it
    // being a closed enum — previously it was parsed, validated, and
    // then silently dropped. The sheet is still the confirm gate: the
    // model never schedules anything itself (§2.4).
    if (spec.suggestedTool != TaskTool.none && mounted) {
      final created = await services.todos.findById(id);
      if (created != null && mounted) {
        await showReminderSheet(context, todo: created, tool: spec.suggestedTool);
      }
    }
    if (mounted) {
      setState(() {
        _decomposition = DecompositionResult(
          subtasks: _decomposition!.subtasks.where((s) => s != spec).toList(),
          fallbackReason: _decomposition!.fallbackReason,
        );
      });
    }
  }

  Future<void> _toggleComplete(Todo todo) async {
    final services = ServiceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final completing = !todo.isCompleted;
    await services.completeTodo(todo.id, completed: completing);
    if (completing) {
      final tier = todo.difficulty ?? fallbackDifficultyTier;
      await services.gamification.onTrigger(
        GamificationTrigger.todoCompleted,
        difficulty: tier,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Completed — ${xpForDifficulty(tier)} XP')),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final todo = _todo;
    final services = ServiceScope.of(context);

    if (todo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(todo.title, style: Theme.of(context).textTheme.headlineSmall),
          Gap.s,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (todo.difficulty != null)
                DifficultyChip(tier: todo.difficulty!, showXp: true),
              ModelBackendBadge(
                backend: services.difficultyScorer.backend,
                compact: true,
              ),
              if (todo.deadline != null)
                Chip(
                  avatar: const Icon(Icons.event_outlined, size: 16),
                  label: Text(formatWhen(todo.deadline!)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          Gap.m,
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleComplete(todo),
                  icon: Icon(todo.isCompleted ? Icons.undo : Icons.check),
                  label: Text(todo.isCompleted ? 'Mark not done' : 'Mark done'),
                ),
              ),
              Gap.s,
              IconButton.filledTonal(
                onPressed: _rescore,
                icon: const Icon(Icons.refresh),
                tooltip: 'Re-score difficulty',
              ),
            ],
          ),

          const SectionHeader(title: 'Reminders'),
          _ReminderList(todoId: todo.id, reminders: _reminders),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await showReminderSheet(context, todo: todo);
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Add a reminder'),
            ),
          ),

          const SectionHeader(title: 'Break it down'),
          _DecompositionSection(
            result: _decomposition,
            busy: _decomposing,
            backend: services.taskDecomposer.backend,
            onDecompose: _decompose,
            onAccept: _acceptSubtask,
          ),

          const SectionHeader(title: 'Subtasks'),
          StreamBuilder<List<Todo>>(
            stream: _subtasks,
            builder: (context, snapshot) {
              final subtasks = snapshot.data ?? const <Todo>[];
              if (subtasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('No subtasks yet.'),
                );
              }
              return Column(
                children: [
                  for (final sub in subtasks)
                    CheckboxListTile(
                      value: sub.isCompleted,
                      title: Text(sub.title),
                      // Showing the tier here is what makes the total
                      // legible: the parent's XP is the sum of its
                      // steps, not one flat number.
                      subtitle: Text(
                        '${difficultyLabel(sub.difficulty ?? fallbackDifficultyTier)}'
                        ' · ${xpForDifficulty(sub.difficulty ?? fallbackDifficultyTier)} XP',
                      ),
                      onChanged: (checked) async {
                        await services.completeTodo(
                          sub.id,
                          completed: checked ?? false,
                        );
                        if (checked ?? false) {
                          // Subtasks carry their own tier from the
                          // decomposition, so finishing the pieces of a
                          // heavy task adds up to more than a flat award.
                          await services.gamification.onTrigger(
                            GamificationTrigger.todoCompleted,
                            difficulty: sub.difficulty ?? fallbackDifficultyTier,
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),
          Gap.xl,
        ],
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.todoId, required this.reminders});

  final int todoId;
  final Stream<List<Reminder>> reminders;

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    return StreamBuilder<List<Reminder>>(
      stream: reminders,
      builder: (context, snapshot) {
        final mine = (snapshot.data ?? const <Reminder>[])
            .where((r) => r.todoId == todoId && !r.cancelled)
            .toList();
        if (mine.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('None scheduled.'),
          );
        }
        return Column(
          children: [
            for (final r in mine)
              ListTile(
                leading: Icon(
                  r.tool.name == 'setAlarm'
                      ? Icons.alarm
                      : Icons.notifications_outlined,
                ),
                title: Text(formatWhen(r.scheduledFor)),
                subtitle: Text(
                  r.isMissed
                      ? 'Missed'
                      : (r.firedAt != null ? 'Fired' : 'Scheduled'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
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

class _DecompositionSection extends StatelessWidget {
  const _DecompositionSection({
    required this.result,
    required this.busy,
    required this.backend,
    required this.onDecompose,
    required this.onAccept,
  });

  final DecompositionResult? result;
  final bool busy;
  final ModelBackend backend;
  final VoidCallback onDecompose;
  final Future<void> Function(SubtaskSpec) onAccept;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final current = result;
    if (current == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: onDecompose,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Suggest smaller steps'),
        ),
      );
    }

    if (current.subtasks.isEmpty) {
      // A fallback is a real answer, not a failure — showing the reason
      // keeps the system's behaviour legible instead of looking broken.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No smaller steps suggested.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gap.xs,
            Text(
              current.fallbackReason ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.s,
            OutlinedButton(
              onPressed: onDecompose,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tap to add — nothing is saved until you do.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ModelBackendBadge(backend: backend, compact: true),
            ],
          ),
        ),
        Gap.s,
        for (final spec in current.subtasks)
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(spec.title),
            subtitle: Text(
              '~${spec.estimatedMinutes} min · ${difficultyLabel(spec.tier)}',
            ),
            onTap: () => onAccept(spec),
          ),
      ],
    );
  }
}
