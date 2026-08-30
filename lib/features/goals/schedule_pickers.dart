import 'package:flutter/material.dart';

import '../../core/models/task_tool.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Date, time, and reminder-or-alarm choice for a task, asked up front
/// rather than left to a heuristic guess or a follow-up sheet.
///
/// [tool] is [TaskTool.none], [TaskTool.setReminder], or
/// [TaskTool.setAlarm] — the other [TaskTool] values don't apply to a
/// plain task deadline. The tool row only appears once a date/time is
/// set: scheduling a reminder for a task with no chosen time isn't a
/// real option, so there's nothing to ask until one exists.
class TaskScheduleField extends StatelessWidget {
  const TaskScheduleField({
    super.key,
    required this.when,
    required this.tool,
    required this.onWhenChanged,
    required this.onToolChanged,
  });

  final DateTime? when;
  final TaskTool tool;
  final ValueChanged<DateTime?> onWhenChanged;
  final ValueChanged<TaskTool> onToolChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: when ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: when != null
          ? TimeOfDay.fromDateTime(when!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (!context.mounted) return;
    onWhenChanged(
      DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.event_outlined, size: 20),
            title: Text(when == null ? 'No date or time' : formatWhen(when!)),
            subtitle: const Text('Tap to set when this is due'),
            trailing: when == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () {
                      onWhenChanged(null);
                      onToolChanged(TaskTool.none);
                    },
                  ),
            onTap: () => _pick(context),
          ),
        ),
        if (when != null) ...[
          Gap.s,
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TaskTool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: TaskTool.none,
                  label: Text('No reminder'),
                  icon: Icon(Icons.notifications_off_outlined, size: 16),
                ),
                ButtonSegment(
                  value: TaskTool.setReminder,
                  label: Text('Reminder'),
                  icon: Icon(Icons.notifications_outlined, size: 16),
                ),
                ButtonSegment(
                  value: TaskTool.setAlarm,
                  label: Text('Alarm'),
                  icon: Icon(Icons.alarm, size: 16),
                ),
              ],
              selected: {tool},
              onSelectionChanged: (s) => onToolChanged(s.first),
            ),
          ),
        ],
      ],
    );
  }
}

/// A recurring check-in time for a health target: a time of day, plus
/// which weekdays it applies to.
///
/// Deliberately no calendar date anywhere in this widget — the whole
/// point of "every day" or "Mon/Wed/Fri" is that the user names a
/// *pattern*, and the actual next occurrence is computed
/// (`schedule_calculator.dart`'s `nextOccurrence`), not picked.
class HealthScheduleField extends StatelessWidget {
  const HealthScheduleField({
    super.key,
    required this.time,
    required this.everyDay,
    required this.days,
    required this.onTimeChanged,
    required this.onEveryDayChanged,
    required this.onDaysChanged,
  });

  final TimeOfDay? time;
  final bool everyDay;

  /// `DateTime.weekday` values (1=Mon..7=Sun). Only read when
  /// [everyDay] is false.
  final Set<int> days;

  final ValueChanged<TimeOfDay?> onTimeChanged;
  final ValueChanged<bool> onEveryDayChanged;
  final ValueChanged<Set<int>> onDaysChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) onTimeChanged(picked);
  }

  void _toggleDay(int day, bool selected) {
    final next = Set<int>.from(days);
    if (selected) {
      next.add(day);
    } else {
      next.remove(day);
    }
    // A schedule with zero active days can never fire, which is a
    // confusing dead state rather than a useful one — keeping the last
    // day pinned means there's always something to compute a next
    // occurrence from.
    if (next.isEmpty) return;
    onDaysChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.alarm_outlined, size: 20),
            title: Text(
              time == null ? 'No check-in time' : formatClock(time!),
            ),
            subtitle: const Text('Tap to add a daily check-in'),
            trailing: time == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () => onTimeChanged(null),
                  ),
            onTap: () => _pick(context),
          ),
        ),
        if (time != null) ...[
          Gap.s,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('Every day'),
                selected: everyDay,
                visualDensity: VisualDensity.compact,
                onSelected: onEveryDayChanged,
              ),
              if (!everyDay)
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(weekdayAbbrev(day)),
                    selected: days.contains(day),
                    visualDensity: VisualDensity.compact,
                    onSelected: (selected) => _toggleDay(day, selected),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

/// An optional date/time for a note, used only to flag when it lands
/// close to something already scheduled — a note is never itself
/// turned into a reminder or alarm.
class NoteScheduleField extends StatelessWidget {
  const NoteScheduleField({
    super.key,
    required this.when,
    required this.clash,
    required this.onWhenChanged,
  });

  final DateTime? when;

  /// The nearest existing scheduled instant this clashes with, or null.
  final DateTime? clash;

  final ValueChanged<DateTime?> onWhenChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: when ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: when != null
          ? TimeOfDay.fromDateTime(when!)
          : TimeOfDay.now(),
    );
    if (!context.mounted) return;
    onWhenChanged(
      DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.schedule_outlined, size: 20),
            title: Text(
              when == null ? 'No date or time' : formatWhen(when!),
            ),
            subtitle: const Text('Optional — checked against what you have scheduled'),
            trailing: when == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: () => onWhenChanged(null),
                  ),
            onTap: () => _pick(context),
          ),
        ),
        if (clash != null) ...[
          Gap.xs,
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
              Gap.xs,
              Expanded(
                child: Text(
                  'Close to something already scheduled at ${formatWhen(clash!)}',
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
