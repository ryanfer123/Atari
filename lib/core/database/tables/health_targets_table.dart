import 'package:drift/drift.dart';

/// Persisted form of `HealthTarget`
/// (`lib/core/models/health_target.dart`).
@DataClassName('HealthTargetRow')
class HealthTargets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get metric => text()();
  TextColumn get threshold => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastMetAt => dateTime().nullable()();

  /// Time of day to check this target, as "HH:mm" in 24-hour time.
  /// Null means no recurring reminder is configured — the target is
  /// still a normal field record either way.
  TextColumn get reminderTime => text().nullable()();

  /// Which days [reminderTime] applies to, as a 7-bit mask — bit 0 is
  /// Monday, bit 6 is Sunday, matching `DateTime.weekday - 1`. "Every
  /// day" is all seven bits set (127), not a separate null case, so a
  /// schedule is always one concrete thing rather than two shapes to
  /// handle everywhere it's read. Null alongside a null [reminderTime]
  /// means no schedule at all.
  IntColumn get activeDaysMask => integer().nullable()();
}
