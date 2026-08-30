import 'dart:math' as math;

/// "How busy has the user been lately" — a comparison `BaselineStore`
/// can't answer.
///
/// `BaselineStore` buckets every observation by `(hourOfDay, dayOfWeek)`,
/// which is exactly right for "is this hour unusual for a Tuesday
/// afternoon" but throws away the calendar-day dimension entirely — it
/// has no way to say "the last 5 days versus the 5 before that". This is
/// a second, deliberately separate lens: two trailing day-count totals
/// for one signal, turned into a z-score-shaped number the same
/// `SlmExplainer` prompt already knows how to phrase.
///
/// The two totals a caller passes in are day counts (unlocks, app
/// switches — not a value collected once, but a total of events), so
/// there is no per-day sample to compute a real standard deviation from
/// without ten separate windowed queries. [zScore] uses the standard
/// Poisson approximation instead — for count data, variance is
/// approximately the mean, so `sqrt(priorPerDay)` stands in for the
/// "expected spread" a small sample would otherwise have to supply. This
/// is a lightweight personal read, not the population-calibrated
/// statistic `BaselineStore` computes; the wording built on top of it
/// says "above/below usual", never a number implying it's more precise
/// than that.
class ActivityWindow {
  const ActivityWindow({
    required this.signal,
    required this.recentTotal,
    required this.priorTotal,
    required this.windowDays,
  });

  /// e.g. `unlocks`, `app_switches` — matches `SlmExplainer`'s existing
  /// signal-name vocabulary.
  final String signal;

  /// Total events in the most recent [windowDays] days.
  final int recentTotal;

  /// Total events in the [windowDays] days before that.
  final int priorTotal;

  final int windowDays;

  double get recentPerDay => recentTotal / windowDays;
  double get priorPerDay => priorTotal / windowDays;

  /// Positive means busier lately, negative means calmer, zero means no
  /// prior data to compare against or no observed change.
  double get zScore {
    if (priorPerDay <= 0) {
      // Nothing to compare against — going from zero to any activity is
      // a real change, but there's no "usual" yet to score it against,
      // so it reads as flat rather than an arbitrarily large spike.
      return 0;
    }
    final expectedSpread = math.sqrt(priorPerDay);
    if (expectedSpread <= 0) return 0;
    return (recentPerDay - priorPerDay) / expectedSpread;
  }

  /// A short, human-readable comparison for the explanation prompt —
  /// e.g. "42 unlocks a day over the last 5 days, versus 28 a day the
  /// 5 days before that". Deliberately says the numbers, not a
  /// judgement — the model is only ever handed data to restate.
  String get description =>
      '${recentPerDay.toStringAsFixed(1)} $signal a day over the last '
      '$windowDays days, versus ${priorPerDay.toStringAsFixed(1)} a day '
      'the $windowDays days before that';
}

/// Picks the [ActivityWindow] with the largest-magnitude z-score from
/// [windows] — the one change most worth mentioning — or null if
/// [windows] is empty (e.g. every signal was unavailable).
ActivityWindow? mostChanged(List<ActivityWindow> windows) {
  if (windows.isEmpty) return null;
  return windows.reduce(
    (a, b) => b.zScore.abs() > a.zScore.abs() ? b : a,
  );
}

/// Picks which [ActivityWindow] the manual check's explanation should be
/// grounded in.
///
/// A phone-signal count (unlocks, app switches) can only ever say the
/// phone was touched, never what was actually done — so completed tasks
/// lead the narrative whenever there is anything to talk about, and
/// phone signals are only the fallback for a user with nothing completed
/// yet, not the default. [windows] must contain a window whose
/// [ActivityWindow.signal] is `tasks_completed`.
ActivityWindow? preferredWindow(List<ActivityWindow> windows) {
  final tasksWindow = windows.firstWhere(
    (w) => w.signal == 'tasks_completed',
    orElse: () => const ActivityWindow(
      signal: 'tasks_completed',
      recentTotal: 0,
      priorTotal: 0,
      windowDays: 5,
    ),
  );
  if (tasksWindow.recentTotal + tasksWindow.priorTotal > 0) return tasksWindow;
  return mostChanged(
    windows.where((w) => w.signal != 'tasks_completed').toList(),
  );
}

/// Names what was actually done when [top] is a `tasks_completed` window
/// with titles to name in [namedRecent]; falls back to
/// [ActivityWindow.description]'s generic count-based phrasing otherwise
/// (a phone signal, or task counts with nothing nameable — e.g. subtasks
/// completed after their titles scrolled out of the recent list).
/// Deliberately states real titles and numbers, never a judgement — the
/// model is only ever handed data to restate.
String? describeActivity(ActivityWindow? top, List<String> namedRecent) {
  if (top == null) return null;
  if (top.signal != 'tasks_completed' || namedRecent.isEmpty) {
    return top.description;
  }
  final named = namedRecent.take(3).join(', ');
  final ofTotal = namedRecent.length > 3
      ? ' — ${top.recentTotal} finished in total over the last '
            '${top.windowDays} days'
      : ' (${top.recentTotal} finished over the last ${top.windowDays} days)';
  return 'you finished $named$ofTotal, versus ${top.priorTotal} the '
      '${top.windowDays} days before that';
}
