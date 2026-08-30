/// All seven bits of [HealthTarget.activeDaysMask] set — "every day",
/// spelled out as a value rather than a null special-case.
const int everyDayMask = 0x7F;

/// A structured health goal, e.g. "steps → 8000".
///
/// Queried by direct field filter in `GoalContext`, never embedded —
/// it's a structured record, so a field filter is cheaper and more
/// reliable than semantic search (Plans/IMPLEMENTATION.md §2).
class HealthTarget {
  const HealthTarget({
    required this.id,
    required this.metric,
    required this.threshold,
    required this.createdAt,
    this.active = true,
    this.lastMetAt,
    this.reminderTime,
    this.activeDaysMask,
  });

  final int id;

  /// e.g. `steps`, `water`, `sleep`.
  final String metric;

  /// Free text so units stay flexible (`8000`, `2L`, `7h`) — this is
  /// displayed and put into prompt context, never arithmetic'd.
  final String threshold;

  final DateTime createdAt;
  final bool active;
  final DateTime? lastMetAt;

  /// "HH:mm" in 24-hour time, or null if no recurring check-in is
  /// configured for this target.
  final String? reminderTime;

  /// 7-bit mask, bit 0 = Monday .. bit 6 = Sunday. "Every day" is all
  /// seven bits set (127), not a separate case — see the table's doc
  /// comment. Null alongside a null [reminderTime] means unscheduled.
  final int? activeDaysMask;

  /// Whether this target has a recurring schedule at all.
  bool get hasSchedule => reminderTime != null && activeDaysMask != null;

  /// [activeDaysMask] unpacked into `DateTime.weekday` values (1 = Monday
  /// .. 7 = Sunday), so callers work with the same weekday numbering
  /// `DateTime` and `formatWhen` already use rather than juggling a
  /// second convention.
  Set<int> get activeWeekdays {
    final mask = activeDaysMask;
    if (mask == null) return const {};
    return {
      for (var bit = 0; bit < 7; bit++)
        if (mask & (1 << bit) != 0) bit + 1,
    };
  }

  /// Packs [weekdays] into the bitmask [activeDaysMask] uses — the
  /// inverse of [activeWeekdays].
  static int maskFromWeekdays(Set<int> weekdays) {
    var mask = 0;
    for (final day in weekdays) {
      mask |= 1 << (day - 1);
    }
    return mask;
  }

  bool get metToday {
    final last = lastMetAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}
