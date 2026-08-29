/// Completed actions that award XP via `GamificationEngine`
/// (`lib/engine/gamification`).
///
/// Deliberately excludes any raw-reduced-screen-time trigger — XP must
/// always trace to a completed action. See Plans/IMPLEMENTATION.md §4.7 and
/// RESEARCH.md §Expansion: gamified capture-to-organize layer.
enum GamificationTrigger {
  interventionWorked,
  todoCompleted,
  healthTargetMet,
  captureOrganized,
}

/// A logged XP award. Streaks/levels derived from these are non-losable by
/// design: a missed day pauses progress, it never subtracts XP or resets to
/// zero. See Plans/IMPLEMENTATION.md §4.7.
class GamificationEvent {
  const GamificationEvent({
    required this.trigger,
    required this.xpAwarded,
    required this.timestamp,
  });

  final GamificationTrigger trigger;
  final int xpAwarded;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamificationEvent &&
          runtimeType == other.runtimeType &&
          trigger == other.trigger &&
          xpAwarded == other.xpAwarded &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(trigger, xpAwarded, timestamp);

  @override
  String toString() =>
      'GamificationEvent(trigger: $trigger, xpAwarded: $xpAwarded, '
      'timestamp: $timestamp)';
}
