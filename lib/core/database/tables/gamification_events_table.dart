import 'package:drift/drift.dart';

/// Append-only log of XP awards. `GamificationEngine`
/// (`lib/engine/gamification`) derives total XP, level, and the
/// non-losable active-day streak entirely from this log — there is no
/// separately-mutable totals row, so no code path can decrement or reset
/// progress. See Plans/IMPLEMENTATION.md §4.7.
@DataClassName('GamificationEventRow')
class GamificationEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trigger => text()();
  IntColumn get xpAwarded => integer()();
  DateTimeColumn get timestamp => dateTime()();
}
