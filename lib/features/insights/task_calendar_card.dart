import 'package:flutter/material.dart';

import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Groups [todos] by the calendar day of their deadline, dropping the
/// time of day and anything with no deadline at all — the calendar can
/// only place a task on a date it actually has.
Map<DateTime, List<Todo>> groupByDeadlineDay(List<Todo> todos) {
  final byDay = <DateTime, List<Todo>>{};
  for (final todo in todos) {
    final deadline = todo.deadline;
    if (deadline == null) continue;
    final day = DateTime(deadline.year, deadline.month, deadline.day);
    byDay.putIfAbsent(day, () => []).add(todo);
  }
  return byDay;
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Month-grid view of every task with a deadline, in place of the raw
/// "how decisions get made" explainer card — a date the user can tap is
/// a more direct way to see what's registered when than a list of the
/// engine's internal trigger names.
class TaskCalendarCard extends StatefulWidget {
  const TaskCalendarCard({super.key});

  @override
  State<TaskCalendarCard> createState() => _TaskCalendarCardState();
}

class _TaskCalendarCardState extends State<TaskCalendarCard> {
  late DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _selectedDay;

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<List<Todo>>(
          stream: services.todos.watchTopLevel(),
          builder: (context, snapshot) {
            final byDay = groupByDeadlineDay(snapshot.data ?? const []);
            final selected = _selectedDay;
            final selectedTasks = selected == null
                ? const <Todo>[]
                : (byDay[selected] ?? const <Todo>[]);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                Gap.s,
                _weekdayRow(context),
                _grid(context, byDay),
                if (selected != null) ...[
                  const Divider(),
                  _selectedDayList(context, selected, selectedTasks),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Expanded(
          child: Text(
            '${_monthNames[_month.month - 1]} ${_month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _weekdayRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var weekday = 1; weekday <= 7; weekday++)
          Expanded(
            child: Center(
              child: Text(
                weekdayAbbrev(weekday).substring(0, 2),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }

  Widget _grid(BuildContext context, Map<DateTime, List<Todo>> byDay) {
    final scheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // DateTime.weekday is 1 (Monday) .. 7 (Sunday); the grid's first
    // column is Monday, so a Monday first-of-month needs zero blanks.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++) ...[
                Builder(
                  builder: (context) {
                    final dayNum = row * 7 + col - leadingBlanks + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }
                    final day = DateTime(_month.year, _month.month, dayNum);
                    final tasks = byDay[day] ?? const <Todo>[];
                    final isToday = day == todayDay;
                    final isSelected = _selectedDay == day;

                    return Expanded(
                      child: InkWell(
                        onTap: tasks.isEmpty
                            ? null
                            : () => setState(
                                () => _selectedDay = isSelected ? null : day,
                              ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primaryContainer
                                : null,
                            border: isToday && !isSelected
                                ? Border.all(color: scheme.primary)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNum',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? scheme.onPrimaryContainer
                                          : null,
                                    ),
                              ),
                              if (tasks.isNotEmpty)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? scheme.onPrimaryContainer
                                        : scheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _selectedDayList(
    BuildContext context,
    DateTime day,
    List<Todo> tasks,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${weekdayAbbrev(day.weekday)} ${day.day} ${_monthNames[day.month - 1]}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        for (final task in tasks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              task.isCompleted
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              size: 20,
              color: task.isCompleted ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: Text(
              task.title,
              style: task.isCompleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: task.deadline == null
                ? null
                : Text(formatClock(TimeOfDay.fromDateTime(task.deadline!))),
          ),
      ],
    );
  }
}
