import 'package:flutter/material.dart';

import '../../core/models/captured_item.dart';
import '../../core/models/difficulty_tier.dart';
import '../../core/models/health_target.dart';
import '../../core/models/task_tool.dart';
import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/model_backend_badge.dart';
import '../../engine/capture/captured_item_parser.dart';
import '../../engine/scheduling/schedule_calculator.dart';
import '../goals/schedule_pickers.dart';
import '../goals/todo_detail_screen.dart';

/// Type anything, one item per line, and let the model file each line as
/// a task, a note, or a health target.
///
/// The capture flow reads one region at a time; this is the manual
/// counterpart, and it is deliberately batch-first — jotting six things
/// at once is the common case, and filing them by hand is exactly the
/// friction the model is here to remove.
///
/// Filing alone isn't enough to make an item useful, though: a task
/// nobody set a deadline on never shows up in "Due soon", and a health
/// target with no check-in time is just a note that happens to look
/// like a goal. So every draft asks for what its type actually needs —
/// a task asks when and whether to be reminded or alarmed, a health
/// target asks a time and which days, a note asks an optional time only
/// to flag a clash with what's already scheduled. Nothing is written
/// until [_QuickAddScreenState._saveAll]; every filed type and every
/// schedule choice is editable first, which is what keeps model
/// misfiling cheap (Plans/PIVOT_PLAN.md §2.4).
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

/// One line on its way to becoming a record.
class _Draft {
  _Draft({required this.text, required this.type, this.deadline}) {
    // A task with a known deadline defaults to a reminder at that
    // moment. Still one tap away from "no reminder" — this is a
    // starting answer to the question the UI asks, not a silent
    // schedule the user never saw.
    if (deadline != null) reminderTool = TaskTool.setReminder;
  }

  String text;
  ItemType type;

  // --- Todo scheduling ---
  DateTime? deadline;
  TaskTool reminderTool = TaskTool.none;
  DifficultyTier? tier;
  int? savedTodoId;

  // --- Health scheduling ---
  TimeOfDay? healthTime;
  bool healthEveryDay = true;
  Set<int> healthDays = {1, 2, 3, 4, 5, 6, 7};
  int? savedHealthTargetId;
  DateTime? healthNextOccurrence;

  // --- Note scheduling (clash-check only; never persisted) ---
  DateTime? noteWhen;
  DateTime? noteClash;
}

enum _Phase { typing, drafts, saved }

/// One reminder to schedule with the OS after the batch's database
/// transaction has committed.
typedef _PendingReminder = ({
  String title,
  DateTime when,
  TaskTool tool,
  int? todoId,
  int? healthTargetId,
});

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _controller = TextEditingController();
  final _parser = CapturedItemParser();

  List<_Draft> _drafts = [];
  _Phase _phase = _Phase.typing;
  bool _busy = false;
  String? _progress;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sort() async {
    final lines = _controller.text
        .split(RegExp(r'\r\n|\r|\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    final services = ServiceScope.of(context);
    setState(() {
      _busy = true;
      _progress = 'Reading ${lines.length} line${lines.length == 1 ? '' : 's'}…';
    });

    final drafts = <_Draft>[];
    for (var i = 0; i < lines.length; i++) {
      if (mounted) {
        setState(() => _progress = 'Filing ${i + 1} of ${lines.length}…');
      }
      // Every line goes through the same slot, so the model is loaded
      // once for the whole batch rather than once per line — which is
      // what makes batching worth doing under the one-model-at-a-time
      // rule (Plans/PIVOT_PLAN.md §2.2).
      final type = await services.itemClassifier.classify(lines[i]);
      drafts.add(
        _Draft(
          text: lines[i],
          type: type,
          // A heuristic prefill, not the ask itself — the schedule
          // field it feeds is still shown and still editable, so a
          // pattern the parser can't read (a weekday name, "next
          // Tuesday") doesn't silently leave the task undated.
          deadline: _parser.parse(lines[i]).suggestedDeadline,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _phase = _Phase.drafts;
      _busy = false;
      _progress = null;
    });
  }

  /// Every instant already scheduled or proposed elsewhere in this
  /// batch — what a note's date/time is checked against.
  Future<List<DateTime>> _scheduledInstants({_Draft? excluding}) async {
    final services = ServiceScope.of(context);
    final pending = await services.reminders.getPending();
    return [
      for (final r in pending) r.scheduledFor,
      for (final other in _drafts)
        if (other != excluding) ...[
          if (other.type == ItemType.todo && other.deadline != null)
            other.deadline!,
          if (other.type == ItemType.healthTarget && other.healthTime != null)
            nextOccurrence(
              hour: other.healthTime!.hour,
              minute: other.healthTime!.minute,
              weekdays: other.healthEveryDay ? const {1, 2, 3, 4, 5, 6, 7} : other.healthDays,
            ),
        ],
    ];
  }

  Future<void> _updateNoteWhen(_Draft draft, DateTime? when) async {
    setState(() {
      draft.noteWhen = when;
      draft.noteClash = null;
    });
    if (when == null) return;

    final existing = await _scheduledInstants(excluding: draft);
    final clash = findNearestClash(candidate: when, existing: existing);
    if (!mounted) return;
    setState(() => draft.noteClash = clash);
  }

  Future<void> _saveAll() async {
    final services = ServiceScope.of(context);
    setState(() {
      _busy = true;
      _progress = 'Saving…';
    });

    final usable = _drafts.where((d) => d.text.trim().isNotEmpty).toList();

    // Deliberately two passes, grouped by which model each needs.
    // Scoring uses the language model and saving a note uses the
    // embedder, and only one is resident at a time
    // (Plans/PIVOT_PLAN.md §2.2) — so interleaving them by draft order
    // would reload a 2.5GB model between every pair of lines. Grouped,
    // a mixed batch costs one swap in total.
    final todos = usable.where((d) => d.type == ItemType.todo).toList();
    for (var i = 0; i < todos.length; i++) {
      if (mounted) {
        setState(() => _progress = 'Scoring ${i + 1} of ${todos.length}…');
      }
      final deadline = todos[i].deadline;
      // Only other saved todos, not sibling drafts in this same batch —
      // those don't have deadlines in the database yet to be found by.
      final nearby = deadline == null
          ? const <Todo>[]
          : await services.todos.withDeadlineNear(deadline);
      todos[i].tier = await services.difficultyScorer.score(
        title: todos[i].text.trim(),
        notes: todos[i].text.trim(),
        deadline: deadline,
        nearbyTasks: nearby,
      );
    }

    // Notes are embedded here, before the transaction opens. Embedding
    // is a model call that can trigger a multi-second model load, and
    // holding a write lock across that would stall every other query in
    // the app.
    if (mounted) setState(() => _progress = 'Preparing…');
    final vectors = <_Draft, List<double>?>{};
    for (final draft in usable.where((d) => d.type == ItemType.note)) {
      vectors[draft] = await services.notes.tryEmbed(draft.text.trim());
    }

    if (mounted) setState(() => _progress = 'Saving…');
    final pendingReminders = <_PendingReminder>[];
    try {
      // One transaction for the whole batch: a half-saved list is worse
      // than a failed one, because the user cannot tell which lines made
      // it and re-running would duplicate the rest. OS alarms are
      // deliberately scheduled *after* this commits (see below) — an
      // alarm is an external side effect a database transaction can't
      // roll back, so it has no business inside one.
      await services.database.transaction(() async {
        for (final draft in usable) {
          final text = draft.text.trim();
          switch (draft.type) {
            case ItemType.note:
              await services.notes.create(
                text: text,
                embedding: vectors[draft],
              );

            case ItemType.healthTarget:
              // Splits on a dash or colon so "Sleep - 7 hours" becomes a
              // metric and a threshold; without one the whole line is
              // the metric.
              final parts = text.split(RegExp(r'\s+[-–—:]\s+'));
              final metric = parts.first.trim();
              final threshold = parts.length > 1 ? parts[1].trim() : '—';
              final scheduled = draft.healthTime != null;
              final weekdays = draft.healthEveryDay
                  ? const {1, 2, 3, 4, 5, 6, 7}
                  : draft.healthDays;

              final targetId = await services.healthTargets.create(
                metric: metric,
                threshold: threshold,
                reminderTime: scheduled ? formatHHmm(draft.healthTime!) : null,
                activeDaysMask: scheduled
                    ? (draft.healthEveryDay
                          ? everyDayMask
                          : HealthTarget.maskFromWeekdays(weekdays))
                    : null,
              );
              draft.savedHealthTargetId = targetId;

              if (scheduled) {
                final when = nextOccurrence(
                  hour: draft.healthTime!.hour,
                  minute: draft.healthTime!.minute,
                  weekdays: weekdays,
                );
                draft.healthNextOccurrence = when;
                pendingReminders.add((
                  title: metric,
                  when: when,
                  tool: TaskTool.setReminder,
                  todoId: null,
                  healthTargetId: targetId,
                ));
              }

            case ItemType.todo:
              final id = await services.todos.create(
                title: text,
                deadline: draft.deadline,
                difficulty: draft.tier,
              );
              draft.savedTodoId = id;

              if (draft.deadline != null && draft.reminderTool != TaskTool.none) {
                pendingReminders.add((
                  title: text,
                  when: draft.deadline!,
                  tool: draft.reminderTool,
                  todoId: id,
                  healthTargetId: null,
                ));
              }
          }
        }
      });
    } catch (e) {
      debugPrint('Batch save rolled back: $e');
      if (!mounted) return;
      // The rollback means nothing was written, so the drafts are still
      // exactly what the user typed — leaving them here lets a retry
      // work without re-typing or double-saving.
      for (final draft in usable) {
        draft.savedTodoId = null;
        draft.savedHealthTargetId = null;
      }
      setState(() {
        _busy = false;
        _progress = null;
        _error = 'Nothing was saved — something went wrong. Try again.';
      });
      return;
    }

    // Scheduling the OS alarms is best-effort and per item: one denied
    // permission or one Android refusal shouldn't undo a batch that
    // already committed to the database.
    if (pendingReminders.isNotEmpty) {
      if (mounted) setState(() => _progress = 'Scheduling…');
      for (final reminder in pendingReminders) {
        final ok = await services.scheduleReminder(
          title: reminder.title,
          scheduledFor: reminder.when,
          tool: reminder.tool,
          todoId: reminder.todoId,
          healthTargetId: reminder.healthTargetId,
        );
        if (!ok) {
          debugPrint('Could not schedule a reminder for "${reminder.title}"');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _phase = _Phase.saved;
      _busy = false;
      _progress = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_phase) {
          _Phase.typing => 'Add anything',
          _Phase.drafts => 'Check the filing',
          _Phase.saved => 'Saved',
        }),
        actions: [
          if (_phase == _Phase.typing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: ModelBackendBadge(
                  backend: services.itemClassifier.backend,
                  compact: true,
                ),
              ),
            ),
        ],
      ),
      body: switch (_phase) {
        _Phase.typing => _buildTyping(context),
        _Phase.drafts => _buildDrafts(context),
        _Phase.saved => _buildSaved(context),
      },
    );
  }

  Widget _buildTyping(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'One per line. Mix tasks, notes and targets freely — they get '
          'sorted for you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Gap.m,
        TextField(
          controller: _controller,
          maxLines: null,
          minLines: 8,
          autofocus: true,
          decoration: const InputDecoration(
            hintText:
                'Submit OS assignment by Friday\n'
                'Sleep 7 hours a night\n'
                'Library closes at 9 on weekends',
          ),
        ),
        Gap.l,
        if (_busy) ...[
          const Center(child: CircularProgressIndicator()),
          Gap.s,
          Text(
            _progress ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else
          FilledButton.icon(
            onPressed: _sort,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Sort these out'),
          ),
      ],
    );
  }

  Widget _buildDrafts(BuildContext context) {
    if (_busy) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            Gap.m,
            Text(_progress ?? 'Working…'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _drafts.length,
            itemBuilder: (context, i) {
              final draft = _drafts[i];
              return _DraftCard(
                draft: draft,
                onTypeChanged: (type) => setState(() => draft.type = type),
                onTextChanged: (text) => draft.text = text,
                onRemove: () => setState(() => _drafts.removeAt(i)),
                onDeadlineChanged: (when) => setState(() {
                  draft.deadline = when;
                  if (when == null) draft.reminderTool = TaskTool.none;
                }),
                onReminderToolChanged: (tool) =>
                    setState(() => draft.reminderTool = tool),
                onHealthTimeChanged: (time) =>
                    setState(() => draft.healthTime = time),
                onHealthEveryDayChanged: (everyDay) => setState(() {
                  draft.healthEveryDay = everyDay;
                  if (everyDay) draft.healthDays = {1, 2, 3, 4, 5, 6, 7};
                }),
                onHealthDaysChanged: (days) =>
                    setState(() => draft.healthDays = days),
                onNoteWhenChanged: (when) => _updateNoteWhen(draft, when),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Gap.s,
                ],
                FilledButton.icon(
                  onPressed: _drafts.isEmpty ? null : _saveAll,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    'Save ${_drafts.length} item'
                    '${_drafts.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaved(BuildContext context) {
    final todos = _drafts.where((d) => d.savedTodoId != null).toList();
    final healthTargets = _drafts
        .where((d) => d.savedHealthTargetId != null)
        .toList();
    final notes = _drafts.where(
      (d) => d.type == ItemType.note && d.savedTodoId == null,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Saved ${_drafts.length} item${_drafts.length == 1 ? '' : 's'}.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (todos.isNotEmpty) ...[
          const SectionHeader(title: 'Tasks'),
          Text(
            'Each was scored for effort. Breaking one into steps scores '
            'each step too, so finishing them adds up.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Gap.s,
          for (final draft in todos)
            Card(
              child: ListTile(
                title: Text(draft.text),
                subtitle: Text(_todoSummary(draft)),
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TodoDetailScreen(todoId: draft.savedTodoId!),
                    ),
                  ),
                  child: const Text('Break down'),
                ),
              ),
            ),
        ],
        if (healthTargets.isNotEmpty) ...[
          const SectionHeader(title: 'Health targets'),
          for (final draft in healthTargets)
            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: Text(draft.text),
                subtitle: Text(_healthSummary(draft)),
              ),
            ),
        ],
        if (notes.isNotEmpty) ...[
          const SectionHeader(title: 'Notes'),
          for (final draft in notes)
            ListTile(
              dense: true,
              leading: const Icon(Icons.sticky_note_2_outlined, size: 20),
              title: Text(draft.text),
            ),
        ],
        Gap.l,
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
        Gap.s,
        TextButton(
          onPressed: () => setState(() {
            _controller.clear();
            _drafts = [];
            _phase = _Phase.typing;
          }),
          child: const Text('Add more'),
        ),
      ],
    );
  }

  String _todoSummary(_Draft draft) {
    final tier = draft.tier ?? fallbackDifficultyTier;
    final base = '${difficultyLabel(tier)} · ${xpForDifficulty(tier)} XP';
    if (draft.deadline == null) return base;
    final tool = switch (draft.reminderTool) {
      TaskTool.setAlarm => ' · Alarm ${formatWhen(draft.deadline!)}',
      TaskTool.setReminder => ' · Reminder ${formatWhen(draft.deadline!)}',
      _ => ' · Due ${formatWhen(draft.deadline!)}',
    };
    return '$base$tool';
  }

  String _healthSummary(_Draft draft) {
    if (draft.healthNextOccurrence == null) return 'No check-in scheduled';
    final pattern = draft.healthEveryDay
        ? 'Every day'
        : (draft.healthDays.toList()..sort()).map(weekdayAbbrev).join(', ');
    return '$pattern at ${formatClock(draft.healthTime!)} · '
        'next ${formatWhen(draft.healthNextOccurrence!)}';
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onTypeChanged,
    required this.onTextChanged,
    required this.onRemove,
    required this.onDeadlineChanged,
    required this.onReminderToolChanged,
    required this.onHealthTimeChanged,
    required this.onHealthEveryDayChanged,
    required this.onHealthDaysChanged,
    required this.onNoteWhenChanged,
  });

  final _Draft draft;
  final ValueChanged<ItemType> onTypeChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onRemove;
  final ValueChanged<DateTime?> onDeadlineChanged;
  final ValueChanged<TaskTool> onReminderToolChanged;
  final ValueChanged<TimeOfDay?> onHealthTimeChanged;
  final ValueChanged<bool> onHealthEveryDayChanged;
  final ValueChanged<Set<int>> onHealthDaysChanged;
  final ValueChanged<DateTime?> onNoteWhenChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: draft.text,
                    onChanged: onTextChanged,
                    maxLines: null,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
            Gap.s,
            // Full-width so the three options stay readable; changing a
            // filing must be one tap, or correcting the model costs more
            // than doing it by hand would have.
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ItemType>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(
                    value: ItemType.note,
                    label: Text('Note'),
                    icon: Icon(Icons.sticky_note_2_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: ItemType.todo,
                    label: Text('Task'),
                    icon: Icon(Icons.check_circle_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: ItemType.healthTarget,
                    label: Text('Health'),
                    icon: Icon(Icons.favorite_outline, size: 16),
                  ),
                ],
                selected: {draft.type},
                onSelectionChanged: (s) => onTypeChanged(s.first),
              ),
            ),
            Gap.s,
            switch (draft.type) {
              ItemType.todo => TaskScheduleField(
                when: draft.deadline,
                tool: draft.reminderTool,
                onWhenChanged: onDeadlineChanged,
                onToolChanged: onReminderToolChanged,
              ),
              ItemType.healthTarget => HealthScheduleField(
                time: draft.healthTime,
                everyDay: draft.healthEveryDay,
                days: draft.healthDays,
                onTimeChanged: onHealthTimeChanged,
                onEveryDayChanged: onHealthEveryDayChanged,
                onDaysChanged: onHealthDaysChanged,
              ),
              ItemType.note => NoteScheduleField(
                when: draft.noteWhen,
                clash: draft.noteClash,
                onWhenChanged: onNoteWhenChanged,
              ),
            },
          ],
        ),
      ),
    );
  }
}
