import 'package:flutter/material.dart';

import '../../core/models/gamification_event.dart';
import '../../core/models/health_target.dart';
import '../../core/models/task_tool.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../engine/scheduling/schedule_calculator.dart';
import 'schedule_pickers.dart';

class HealthTargetsTab extends StatefulWidget {
  const HealthTargetsTab({super.key});

  @override
  State<HealthTargetsTab> createState() => _HealthTargetsTabState();
}

class _HealthTargetsTabState extends State<HealthTargetsTab> {
  late final Stream<List<HealthTarget>> _targets = ServiceScope.of(context)
      .healthTargets
      .watchAll();

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      body: StreamBuilder<List<HealthTarget>>(
        stream: _targets,
        builder: (context, snapshot) {
          final targets = snapshot.data ?? const <HealthTarget>[];
          if (targets.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: 'No health targets',
              message:
                  'Simple goals like "steps → 8000". Marking one met earns XP.',
              action: FilledButton.icon(
                onPressed: () => _showEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Add a target'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: targets.length,
            itemBuilder: (context, i) {
              final target = targets[i];
              return ListTile(
                leading: Icon(
                  target.metToday ? Icons.check_circle : Icons.favorite_outline,
                ),
                iconColor: target.metToday
                    ? Theme.of(context).colorScheme.primary
                    : null,
                title: Text('${target.metric} → ${target.threshold}'),
                subtitle: Text(_subtitleFor(target)),
                trailing: target.metToday
                    ? null
                    : TextButton(
                        onPressed: () async {
                          await services.healthTargets.markMet(target.id);
                          await services.gamification.onTrigger(
                            GamificationTrigger.healthTargetMet,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Target met — XP awarded'),
                              ),
                            );
                          }
                        },
                        child: const Text('Mark met'),
                      ),
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete target?'),
                      content: target.hasSchedule
                          ? const Text(
                              'Its recurring check-in reminder will be '
                              'cancelled too.',
                            )
                          : null,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  // Not healthTargets.delete: that removes the rows but
                  // leaves any check-in alarm still scheduled with the OS.
                  if (confirmed ?? false) {
                    await services.deleteHealthTarget(target.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add-health',
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _TargetEditor(),
    );
  }

  String _subtitleFor(HealthTarget target) {
    final status = target.metToday
        ? 'Met today'
        : (target.active ? 'Active' : 'Paused');
    if (!target.hasSchedule) return status;

    final time = parseHHmm(target.reminderTime);
    final days = target.activeDaysMask == everyDayMask
        ? 'Every day'
        : (target.activeWeekdays.toList()..sort())
              .map(weekdayAbbrev)
              .join(', ');
    return time == null
        ? status
        : '$status · $days at ${formatClock(time)}';
  }
}

class _TargetEditor extends StatefulWidget {
  const _TargetEditor();

  @override
  State<_TargetEditor> createState() => _TargetEditorState();
}

class _TargetEditorState extends State<_TargetEditor> {
  final _metric = TextEditingController();
  final _threshold = TextEditingController();

  TimeOfDay? _time;
  bool _everyDay = true;
  Set<int> _days = {1, 2, 3, 4, 5, 6, 7};
  bool _saving = false;

  @override
  void dispose() {
    _metric.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final metric = _metric.text.trim();
    final threshold = _threshold.text.trim();
    if (metric.isEmpty || threshold.isEmpty || _saving) return;

    setState(() => _saving = true);
    final services = ServiceScope.of(context);
    final navigator = Navigator.of(context);

    final scheduled = _time != null;
    final weekdays = _everyDay ? const {1, 2, 3, 4, 5, 6, 7} : _days;

    final id = await services.healthTargets.create(
      metric: metric,
      threshold: threshold,
      reminderTime: scheduled ? formatHHmm(_time!) : null,
      activeDaysMask: scheduled
          ? (_everyDay ? everyDayMask : HealthTarget.maskFromWeekdays(weekdays))
          : null,
    );

    if (scheduled) {
      final when = nextOccurrence(
        hour: _time!.hour,
        minute: _time!.minute,
        weekdays: weekdays,
      );
      // Best-effort, same as everywhere else a reminder is scheduled:
      // the target itself is already saved and shouldn't be undone by
      // Android refusing the alarm.
      await services.scheduleReminder(
        title: metric,
        scheduledFor: when,
        tool: TaskTool.setReminder,
        healthTargetId: id,
      );
    }

    navigator.pop();
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
              'New health target',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Gap.m,
            TextField(
              controller: _metric,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Metric',
                hintText: 'steps, water, sleep',
              ),
            ),
            Gap.s,
            TextField(
              controller: _threshold,
              decoration: const InputDecoration(
                labelText: 'Target',
                hintText: '8000, 2L, 7h',
              ),
            ),
            Gap.m,
            HealthScheduleField(
              time: _time,
              everyDay: _everyDay,
              days: _days,
              onTimeChanged: (time) => setState(() => _time = time),
              onEveryDayChanged: (everyDay) => setState(() {
                _everyDay = everyDay;
                if (everyDay) _days = {1, 2, 3, 4, 5, 6, 7};
              }),
              onDaysChanged: (days) => setState(() => _days = days),
            ),
            Gap.l,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Adding…' : 'Add target'),
            ),
          ],
        ),
      ),
    );
  }
}
