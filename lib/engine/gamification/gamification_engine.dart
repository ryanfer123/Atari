import '../../core/database/app_database.dart';
import '../../core/models/difficulty_tier.dart';
import '../../core/models/gamification_event.dart';
import 'gamification_progress.dart';

/// XP/level/streak state machine: rewards *completion and effort*, never
/// raw reduced screen time — direct response to literature showing
/// streak/reward mechanics can independently increase anxiety and
/// compulsive checking (RESEARCH.md §Expansion: gamified capture-to-organize
/// layer).
///
/// **Pre-ship self-audit — run this as an actual checklist item before the
/// app is considered demo-ready, against the real shipped UI copy, not
/// this file:**
/// 1. Does any mechanic penalize a *missed* day (lost streak, lost XP,
///    red/warning color on a gap)? If yes, it fails the audit — redesign
///    as a pause, not a loss. [GamificationProgress.activeDayCount] is
///    monotonic by construction, so this engine can't fail that check on
///    its own, but UI copy/coloring built on top of it still can.
/// 2. Does any copy use urgency/loss-framing ("don't lose your streak!",
///    "your level is at risk")? Rewrite as accomplishment-framing instead
///    ("you're on a 5-day streak!").
/// 3. Does the app ever reward *not* using a feature (bonus XP purely for
///    low screen time, no completed action behind it)? [GamificationTrigger]
///    only has action-completion values, so this can't happen through
///    [onTrigger] — but don't add a trigger that violates this.
/// 4. Run this checklist against the actual shipped copy/UI in the final
///    hours before demo, not just this design doc.
///
/// See Plans/IMPLEMENTATION.md §4.7.
class GamificationEngine {
  GamificationEngine(this._db, {DateTime Function() now = DateTime.now})
    : _now = now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Awards XP for [trigger] and persists the event. XP totals are only
  /// ever added to — this table has no update/delete path.
  ///
  /// Pass [difficulty] when completing a task so the award scales with its
  /// tier. The amount is computed here rather than by the caller so the
  /// number written to the log is always the one `xpForTrigger` defines.
  Future<GamificationEvent> onTrigger(
    GamificationTrigger trigger, {
    DifficultyTier? difficulty,
  }) async {
    final event = GamificationEvent(
      trigger: trigger,
      xpAwarded: xpForTrigger(trigger, difficulty: difficulty),
      timestamp: _now(),
    );
    await _db
        .into(_db.gamificationEvents)
        .insert(
          GamificationEventsCompanion.insert(
            trigger: trigger.name,
            xpAwarded: event.xpAwarded,
            timestamp: event.timestamp,
          ),
        );
    return event;
  }

  /// Total XP, level, and active-day streak derived from the full event
  /// log persisted so far.
  Future<GamificationProgress> currentProgress() async {
    final rows = await _db.select(_db.gamificationEvents).get();
    final events = rows
        .map(
          (row) => GamificationEvent(
            trigger: GamificationTrigger.values.byName(row.trigger),
            xpAwarded: row.xpAwarded,
            timestamp: row.timestamp,
          ),
        )
        .toList();
    return GamificationProgress.fromEvents(events);
  }
}
