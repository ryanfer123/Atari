import 'package:flutter/material.dart';

import '../../core/models/task_tool.dart';
import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// The confirm gate between a *proposed* reminder and a real scheduled
/// one.
///
/// A model may propose a [TaskTool]; only a tap here schedules anything,
/// because a wrong alarm has a real-world cost
/// (Plans/PIVOT_PLAN.md §2.4, Plans/ARCHITECTURE.md §2).
/// [tool] pre-selects which kind of event is offered, so a model's
/// proposal arrives as a filled-in suggestion the user confirms rather
/// than something they have to re-pick by hand. [TaskTool.none] and
/// [TaskTool.addTodo] are not schedulable, so both fall back to a plain
/// reminder.
Future<bool> showReminderSheet(
  BuildContext context, {
  required Todo todo,
  TaskTool tool = TaskTool.setReminder,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReminderSheet(todo: todo, tool: tool),
  );
  return confirmed ?? false;
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.todo, required this.tool});

  final Todo todo;
  final TaskTool tool;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late DateTime _when;
  late TaskTool _tool;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final deadline = widget.todo.deadline;
    final now = DateTime.now();
    // Default to shortly before the deadline if there is one — a
    // reminder that arrives at the deadline is already too late to act
    // on. Otherwise an hour out, which is a neutral near-term default.
    _when = deadline != null && deadline.isAfter(now)
        ? deadline.subtract(const Duration(minutes: 30))
        : now.add(const Duration(hours: 1));
    if (_when.isBefore(now)) _when = now.add(const Duration(minutes: 10));

    // Only the two schedulable tools have a control in this sheet.
    _tool = widget.tool == TaskTool.setAlarm
        ? TaskTool.setAlarm
        : TaskTool.setReminder;
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(
      () => _when = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final services = ServiceScope.of(context);
    final navigator = Navigator.of(context);

    try {
      final scheduled = await services.scheduleReminder(
        title: widget.todo.title,
        scheduledFor: _when,
        tool: _tool,
        todoId: widget.todo.id,
      );

      if (!scheduled) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'Android refused to schedule this. Check notification and alarm permissions in Settings.';
        });
        return;
      }

      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remind you about this?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Gap.xs,
            Text(
              widget.todo.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.l,
            SegmentedButton<TaskTool>(
              segments: const [
                ButtonSegment(
                  value: TaskTool.setReminder,
                  label: Text('Reminder'),
                  icon: Icon(Icons.notifications_outlined),
                ),
                ButtonSegment(
                  value: TaskTool.setAlarm,
                  label: Text('Alarm'),
                  icon: Icon(Icons.alarm),
                ),
              ],
              selected: {_tool},
              onSelectionChanged: (s) => setState(() => _tool = s.first),
            ),
            Gap.m,
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(formatWhen(_when)),
                subtitle: const Text('Tap to change'),
                onTap: _pickTime,
              ),
            ),
            if (_error != null) ...[
              Gap.m,
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            Gap.l,
            FilledButton.icon(
              onPressed: _saving ? null : _confirm,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Scheduling…' : 'Confirm'),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
