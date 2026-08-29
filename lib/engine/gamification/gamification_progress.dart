import '../../core/models/gamification_event.dart';

/// XP required per level — a placeholder default pending real playtesting
/// data, in the same spirit as the population priors in
/// `lib/engine/baseline`; replace once dogfooding gives a real number.
const int xpPerLevel = 100;

/// XP each trigger awards, gated on the underlying condition already being
/// met (e.g. `interventionWorked` is only fired after `FeedbackLoop`'s own
/// ≥5% success threshold). See Plans/IMPLEMENTATION.md §4.7.
int xpForTrigger(GamificationTrigger trigger) => switch (trigger) {
  GamificationTrigger.interventionWorked => 15,
  GamificationTrigger.todoCompleted => 10,
  GamificationTrigger.healthTargetMet => 10,
  GamificationTrigger.captureOrganized => 5,
};

int levelForXp(int totalXp) => 1 + totalXp ~/ xpPerLevel;

/// Aggregate progress derived entirely from the append-only
/// [GamificationEvent] log — total XP, level, and a non-losable streak of
/// distinct active days.
///
/// Everything here is *computed* from the log rather than stored as
/// separately-mutable totals, so there is no code path that can decrement
/// or reset it. That satisfies the pre-ship self-audit's first check by
/// construction: a missed day simply doesn't add to [activeDayCount] — it
/// never subtracts from it. See Plans/IMPLEMENTATION.md §4.7.
class GamificationProgress {
  const GamificationProgress({
    required this.totalXp,
    required this.level,
    required this.activeDayCount,
  });

  final int totalXp;
  final int level;

  /// Count of distinct calendar days with at least one XP event. This is
  /// the "streak" — non-losable because it is a monotonically
  /// non-decreasing count, not a consecutive-day counter that resets on a
  /// gap.
  final int activeDayCount;

  factory GamificationProgress.fromEvents(List<GamificationEvent> events) {
    var totalXp = 0;
    final activeDays = <DateTime>{};
    for (final event in events) {
      totalXp += event.xpAwarded;
      final t = event.timestamp;
      activeDays.add(DateTime(t.year, t.month, t.day));
    }
    return GamificationProgress(
      totalXp: totalXp,
      level: levelForXp(totalXp),
      activeDayCount: activeDays.length,
    );
  }
}
