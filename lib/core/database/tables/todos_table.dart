import 'package:drift/drift.dart';

/// Persisted form of `Todo` (`lib/core/models/todo.dart`).
@DataClassName('TodoRow')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deadline => dateTime().nullable()();

  /// `DifficultyTier.name`, or null until scored. Stored as its name
  /// rather than its index so reordering the enum can't silently
  /// remap existing rows.
  TextColumn get difficulty => text().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  /// Set when this row is a subtask produced by decomposing another
  /// todo. Self-referencing, so a deleted parent's subtasks are cleaned
  /// up by the repository rather than by a DB cascade (Drift would need
  /// the reference declared up front, and this keeps deletion policy in
  /// one readable place).
  IntColumn get parentId => integer().nullable()();
}
