/// Pure date/time logic behind recurring health schedules and the
/// note-clash check.
///
/// Kept free of any storage or platform dependency, like the rest of
/// `lib/engine` — a schedule is either "the next time this fires" or
/// "does this land near something else", and both are plain arithmetic
/// that doesn't need a database or a model to get right.
library;

/// The next moment at [hour]:[minute] that falls on one of [weekdays]
/// (`DateTime.weekday` numbering: 1 = Monday .. 7 = Sunday) and is
/// strictly after [from].
///
/// This is the "day gets calculated" half of a health schedule: the
/// user only ever picks a time of day and which weekdays apply — never
/// a calendar date — and this is what turns that pattern into a real
/// instant to schedule an alarm for.
DateTime nextOccurrence({
  required int hour,
  required int minute,
  required Set<int> weekdays,
  DateTime? from,
}) {
  assert(weekdays.isNotEmpty, 'a schedule needs at least one active day');
  assert(
    weekdays.every((d) => d >= 1 && d <= 7),
    'weekdays must be DateTime.weekday values (1=Mon..7=Sun)',
  );

  final start = from ?? DateTime.now();
  final today = DateTime(start.year, start.month, start.day);

  // 0..7 inclusive: one full week finds every weekday at least once,
  // and the 8th offset is the safety net for "today's weekday matches,
  // but hour:minute has already passed" — that case needs the same
  // weekday a week later, not any of the other six.
  for (var offset = 0; offset <= 7; offset++) {
    final day = today.add(Duration(days: offset));
    if (!weekdays.contains(day.weekday)) continue;
    final candidate = DateTime(day.year, day.month, day.day, hour, minute);
    if (candidate.isAfter(start)) return candidate;
  }

  // Unreachable: every weekday number appears in today..today+6, so the
  // loop above always returns for a non-empty weekday set.
  throw StateError('no matching day found for weekdays $weekdays');
}

/// The entry in [existing] nearest to [candidate], if any fall within
/// [window] of it — the "does this clash with something already
/// scheduled" check behind the note editor's warning.
///
/// Returns the clashing instant itself, not a bool, so the caller can
/// say what it clashes *with* rather than just that it does.
DateTime? findNearestClash({
  required DateTime candidate,
  required Iterable<DateTime> existing,
  Duration window = const Duration(minutes: 30),
}) {
  DateTime? nearest;
  Duration? nearestGap;
  for (final other in existing) {
    final gap = candidate.difference(other).abs();
    if (gap <= window && (nearestGap == null || gap < nearestGap)) {
      nearest = other;
      nearestGap = gap;
    }
  }
  return nearest;
}
