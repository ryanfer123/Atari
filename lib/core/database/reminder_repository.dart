import 'package:drift/drift.dart';

import '../models/reminder.dart';
import '../models/task_tool.dart';
import 'app_database.dart';

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Reminder _toDomain(ReminderRow row) => Reminder(
    id: row.id,
    title: row.title,
    scheduledFor: row.scheduledFor,
    tool: _toolFromName(row.tool),
    createdAt: row.createdAt,
    todoId: row.todoId,
    healthTargetId: row.healthTargetId,
    firedAt: row.firedAt,
    cancelled: row.cancelled,
  );

  /// Unrecognized names fall back to [TaskTool.setReminder] rather than
  /// throwing — a row is still a real scheduled thing the user
  /// confirmed, so showing it as a generic reminder beats dropping it.
  TaskTool _toolFromName(String name) {
    for (final tool in TaskTool.values) {
      if (tool.name == name) return tool;
    }
    return TaskTool.setReminder;
  }

  Stream<List<Reminder>> watchAll() {
    return (_db.select(_db.reminders)
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledFor)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Reminder>> getPending({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final rows =
        await (_db.select(_db.reminders)
              ..where(
                (t) =>
                    t.cancelled.equals(false) &
                    t.firedAt.isNull() &
                    t.scheduledFor.isBiggerThanValue(at),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.scheduledFor)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Reminder>> forTodo(int todoId) async {
    final rows = await (_db.select(
      _db.reminders,
    )..where((t) => t.todoId.equals(todoId))).get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Reminder>> forHealthTarget(int healthTargetId) async {
    final rows = await (_db.select(
      _db.reminders,
    )..where((t) => t.healthTargetId.equals(healthTargetId))).get();
    return rows.map(_toDomain).toList();
  }

  Future<int> create({
    required String title,
    required DateTime scheduledFor,
    required TaskTool tool,
    int? todoId,
    int? healthTargetId,
    DateTime? now,
  }) {
    assert(
      tool != TaskTool.none,
      'TaskTool.none means no reminder should be created at all',
    );
    assert(
      todoId == null || healthTargetId == null,
      'a reminder belongs to exactly one owner, never both',
    );
    return _db
        .into(_db.reminders)
        .insert(
          RemindersCompanion.insert(
            title: title,
            scheduledFor: scheduledFor,
            tool: tool.name,
            createdAt: now ?? DateTime.now(),
            todoId: Value(todoId),
            healthTargetId: Value(healthTargetId),
          ),
        );
  }

  Future<void> markFired(int id, {DateTime? at}) {
    return (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(firedAt: Value(at ?? DateTime.now())),
    );
  }

  Future<void> cancel(int id) {
    return (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      const RemindersCompanion(cancelled: Value(true)),
    );
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();
  }
}
