import 'package:flutter/material.dart';

import '../../core/models/context_bullet.dart';
import '../../core/services/app_switch_signal_service.dart';
import '../../core/services/notif_latency_signal_service.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/unlock_signal_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/model_backend_badge.dart';
import '../../engine/baseline/recent_activity.dart';
import '../../engine/jitai/decision_point.dart';
import '../../engine/jitai/intervention_option.dart';
import '../../engine/jitai/intervention_spec.dart';
import '../../engine/jitai/tailoring_variables.dart';
import 'task_calendar_card.dart';

/// How many days count as "recent" and how many before that count as
/// "usual", for the manual check's busyness comparison.
/// `ActivityWindow`'s doc comment explains why this is a day-count
/// comparison rather than `BaselineStore`'s hour-of-week buckets.
const _kActivityWindowDays = 5;

/// How many recently-completed todos to fetch when looking for ones to
/// name — wider than the 2-3 actually named, so a busy window doesn't
/// silently lose real completions to the fetch limit before the date
/// filter even runs.
const _kNamedTaskLimit = 10;

/// The always-available transparency panel.
///
/// Shows what the system observed, what it decided, and why — including
/// when it decided to do *nothing*, which is the more common and more
/// important case. Overload detection is deliberately presented here as
/// one input among four rather than as the product's headline
/// (Plans/ARCHITECTURE.md §4, Plans/PIVOT_PLAN.md §2.1).
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  InterventionSpec? _lastDecision;

  /// What the last check's explanation was actually grounded in — shown
  /// alongside the decision so the ±5-day comparison is itself visible,
  /// not just folded invisibly into the model's sentence.
  List<ActivityWindow> _lastActivityWindows = const [];

  bool _deciding = false;

  /// Decision point D — the manual check. Always answers, which is what
  /// makes it usable as the demo's fallback trigger when live signals
  /// aren't cooperating (Plans/IMPLEMENTATION.md §6).
  Future<void> _runManualCheck() async {
    setState(() => _deciding = true);
    final services = ServiceScope.of(context);
    final now = DateTime.now();

    // Real context from the user's own data, so the explanation is
    // grounded rather than generic.
    final dueSoon = await services.todos.dueWithin(
      now,
      const Duration(hours: 4),
    );
    final bullets = [
      for (final todo in dueSoon.take(2))
        ContextBullet(
          source: 'todo',
          text: '${todo.title} due ${formatWhen(todo.deadline!)}',
        ),
    ];

    final windows = await _recentActivityWindows(now);
    final top = preferredWindow(windows);

    final recentTitles = await services.todos.getRecentlyCompleted(
      limit: _kNamedTaskLimit,
    );
    final since = now.subtract(const Duration(days: _kActivityWindowDays));
    final namedRecent = recentTitles
        .where((t) => t.completedAt != null && t.completedAt!.isAfter(since))
        .map((t) => t.title)
        .toList();

    final spec = await services.decisionEngine.decide(
      TailoringVariables(
        decisionPoint: DecisionPoint.manualCheck,
        now: now,
        timeBucket: _timeBucket(now),
        signalZScores: {for (final w in windows) w.signal: w.zScore},
        topSignal: top?.signal ?? 'tasks_completed',
        contextBullets: bullets,
        pendingTodoCount: dueSoon.length,
        recentActivityNote: describeActivity(top, namedRecent),
      ),
    );

    if (mounted) {
      setState(() {
        _lastDecision = spec;
        _lastActivityWindows = windows;
        _deciding = false;
      });
    }
  }

  /// Gathers the ±5-day comparison itself: two windowed counts per
  /// source, turned into an `ActivityWindow` each. Completed tasks are
  /// always included — nothing to grant permission for, since it's
  /// ATARI's own record of what the user did. A phone signal without
  /// its permission (app switches, without Usage access) is left out
  /// entirely rather than reported as "no change" — that would
  /// misrepresent a missing read as a calm one.
  Future<List<ActivityWindow>> _recentActivityWindows(DateTime now) async {
    const days = _kActivityWindowDays;
    final recentSince = now.subtract(const Duration(days: days));
    final priorSince = now.subtract(const Duration(days: days * 2));

    final windows = <ActivityWindow>[];

    final services = ServiceScope.of(context);
    final recentTasks = await services.todos.completedCountBetween(
      recentSince,
      now,
    );
    final priorTasks = await services.todos.completedCountBetween(
      priorSince,
      recentSince,
    );
    windows.add(
      ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: recentTasks,
        priorTotal: priorTasks,
        windowDays: days,
      ),
    );

    final unlocks = UnlockSignalService();
    final recentUnlocks = await unlocks.getUnlockCountSince(recentSince);
    final totalUnlocks = await unlocks.getUnlockCountSince(priorSince);
    windows.add(
      ActivityWindow(
        signal: 'unlocks',
        recentTotal: recentUnlocks,
        priorTotal: totalUnlocks - recentUnlocks,
        windowDays: days,
      ),
    );

    final appSwitches = AppSwitchSignalService();
    if (await appSwitches.hasUsageAccess()) {
      final recentSwitches = await appSwitches.getAppSwitchCountSince(
        recentSince,
      );
      final totalSwitches = await appSwitches.getAppSwitchCountSince(
        priorSince,
      );
      windows.add(
        ActivityWindow(
          signal: 'app_switches',
          recentTotal: recentSwitches,
          priorTotal: totalSwitches - recentSwitches,
          windowDays: days,
        ),
      );
    }

    return windows;
  }

  String _timeBucket(DateTime when) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final part = when.hour < 12
        ? 'morning'
        : when.hour < 17
        ? 'afternoon'
        : 'evening';
    return '${days[(when.weekday - 1).clamp(0, 6)]} $part';
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          Text(
            'Everything this app decides is visible here — including when it decides to leave you alone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Gap.l,

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Check now',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ModelBackendBadge(
                        backend: services.slmExplainer.backend,
                        compact: true,
                      ),
                    ],
                  ),
                  Gap.xs,
                  Text(
                    'Runs the same decision layer a background signal would.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Gap.m,
                  FilledButton.icon(
                    onPressed: _deciding ? null : _runManualCheck,
                    icon: _deciding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_deciding ? 'Deciding…' : 'Run a check'),
                  ),
                ],
              ),
            ),
          ),

          if (_lastDecision != null) ...[
            Gap.m,
            _DecisionCard(spec: _lastDecision!),
          ],
          if (_lastActivityWindows.isNotEmpty) ...[
            Gap.s,
            _ActivityWindowsCard(windows: _lastActivityWindows),
          ],

          const SectionHeader(title: 'What was observed today'),
          const _RawSignalsCard(),

          const SectionHeader(title: 'Calendar'),
          const TaskCalendarCard(),
          Gap.xl,
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.spec});

  final InterventionSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  spec.isDeferred
                      ? Icons.do_not_disturb_on_outlined
                      : Icons.lightbulb_outline,
                  size: 20,
                ),
                Gap.s,
                Text(
                  spec.isDeferred
                      ? 'Decided to do nothing'
                      : interventionOptionLabel(spec.option),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            Gap.s,
            if (spec.explanation != null)
              Text(
                spec.explanation!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (spec.deferReason != null)
              Text(
                spec.deferReason!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            Gap.s,
            Text(
              'Trigger: ${decisionPointLabel(spec.decisionPoint)}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ±5-day comparison a check's explanation was actually grounded
/// in, shown as its own numbers rather than left implicit inside the
/// sentence above — the same transparency-first reasoning as
/// `_RawSignalsCard`, applied to the window the manual check reads
/// from instead of "since midnight today".
class _ActivityWindowsCard extends StatelessWidget {
  const _ActivityWindowsCard({required this.windows});

  final List<ActivityWindow> windows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          for (final window in windows)
            ListTile(
              dense: true,
              leading: Icon(
                window.zScore > 0.3
                    ? Icons.trending_up
                    : window.zScore < -0.3
                    ? Icons.trending_down
                    : Icons.trending_flat,
                size: 20,
              ),
              title: Text(_labelFor(window.signal)),
              subtitle: Text(
                '${window.recentPerDay.toStringAsFixed(1)}/day recently, '
                'was ${window.priorPerDay.toStringAsFixed(1)}/day before',
              ),
              trailing: Text(
                window.zScore.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(String signal) => switch (signal) {
    'tasks_completed' => 'Tasks completed',
    'app_switches' => 'App switches',
    'unlocks' => 'Unlocks',
    'notif_latency_ms' => 'Notification response',
    _ => signal,
  };
}

/// Raw signal counts — the transparency panel's job per
/// Plans/IMPLEMENTATION.md §3. Shows the actual observed numbers, not a
/// score, so the user can check the system's inputs for themselves.
class _RawSignalsCard extends StatefulWidget {
  const _RawSignalsCard();

  @override
  State<_RawSignalsCard> createState() => _RawSignalsCardState();
}

class _RawSignalsCardState extends State<_RawSignalsCard> {
  int? _unlocks;
  int? _appSwitches;
  int? _notifSamples;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Each collector is independently permissioned, so one being
    // unavailable must not blank the others.
    final unlocks = await _safe(
      () => UnlockSignalService().getUnlockCountSince(startOfToday),
    );

    final appSwitchService = AppSwitchSignalService();
    final hasUsage =
        await _safe(() => appSwitchService.hasUsageAccess()) ?? false;
    final switches = hasUsage
        ? await _safe(
            () => appSwitchService.getAppSwitchCountSince(startOfToday),
          )
        : null;

    final notifService = NotifLatencySignalService();
    final hasNotif =
        await _safe(() => notifService.hasNotificationAccess()) ?? false;
    final latencies = hasNotif
        ? await _safe(() => notifService.getLatenciesSince(startOfToday))
        : null;

    if (!mounted) return;
    setState(() {
      _unlocks = unlocks;
      _appSwitches = switches;
      _notifSamples = latencies?.length;
      _loaded = true;
    });
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Card(child: ListTile(title: Text('Reading signals…')));
    }
    return Card(
      child: Column(
        children: [
          _row('Unlocks', _unlocks, 'No permission needed'),
          _row('App switches', _appSwitches, 'Needs usage access'),
          _row(
            'Notification response samples',
            _notifSamples,
            'Needs notification access',
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int? value, String whenMissing) {
    return Builder(
      builder: (context) => ListTile(
        dense: true,
        title: Text(label),
        subtitle: value == null
            ? Text(whenMissing, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: Text(
          value?.toString() ?? '—',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
