import 'package:drift/drift.dart';

/// Persisted form of `Reminder` (`lib/core/models/reminder.dart`).
///
/// Every row here represents something the user explicitly confirmed —
/// see that model's doc comment and Plans/PIVOT_PLAN.md §2.4.
@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get scheduledFor => dateTime()();

  /// `TaskTool.name`. Stored by name, not index — see the equivalent
  /// note on `Todos.difficulty`.
  TextColumn get tool => text()();

  DateTimeColumn get createdAt => dateTime()();
  IntColumn get todoId => integer().nullable()();

  /// Set when this reminder is one occurrence of a health target's
  /// recurring schedule, rather than tied to a todo. A row is never
  /// linked to both — each reminder has exactly one owner.
  IntColumn get healthTargetId => integer().nullable()();

  DateTimeColumn get firedAt => dateTime().nullable()();
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();
}
