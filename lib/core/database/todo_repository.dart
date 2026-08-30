import 'package:drift/drift.dart';

import '../models/difficulty_tier.dart';
import '../models/todo.dart';
import 'app_database.dart';

/// Reads and writes `Todo`s, converting between Drift rows and the
/// domain model so nothing outside this file needs to know the storage
/// shape.
class TodoRepository {
  TodoRepository(this._db);

  final AppDatabase _db;

  Todo _toDomain(TodoRow row) => Todo(
    id: row.id,
    title: row.title,
    createdAt: row.createdAt,
    deadline: row.deadline,
    difficulty: _difficultyFromName(row.difficulty),
    completedAt: row.completedAt,
    notes: row.notes,
    parentId: row.parentId,
  );

  /// Unrecognized names resolve to null rather than throwing — a row
  /// written by a newer build with an added tier shouldn't make the
  /// whole list fail to load.
  DifficultyTier? _difficultyFromName(String? name) {
    if (name == null) return null;
    for (final tier in DifficultyTier.values) {
      if (tier.name == name) return tier;
    }
    return null;
  }

  /// Top-level todos (not subtasks), newest first.
  Future<List<Todo>> getTopLevel() async {
    final rows =
        await (_db.select(_db.todos)
              ..where((t) => t.parentId.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Watches top-level todos so the UI updates without manual refresh.
  Stream<List<Todo>> watchTopLevel() {
    return (_db.select(_db.todos)
          ..where((t) => t.parentId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Stream<List<Todo>> watchSubtasksOf(int parentId) {
    return (_db.select(_db.todos)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Future<Todo?> findById(int id) async {
    final row = await (_db.select(
      _db.todos,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Todos due within [window] of [now] and not yet completed — the
  /// direct field query `GoalContext` uses for the `todos` source
  /// (Plans/IMPLEMENTATION.md §4.5), no embeddings involved.
  Future<List<Todo>> dueWithin(DateTime now, Duration window) async {
    final cutoff = now.add(window);
    final rows =
        await (_db.select(_db.todos)
              ..where(
                (t) =>
                    t.completedAt.isNull() &
                    t.deadline.isNotNull() &
                    t.deadline.isSmallerOrEqualValue(cutoff),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.deadline)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Incomplete todos with a deadline within [window] either side of
  /// [center] — the difficulty scorer's only source of "what else is
  /// due around this time," so it can weigh a task against the load
  /// already sitting near it rather than in isolation.
  ///
  /// Capped to [limit] and title-only by the caller's use of it,
  /// deliberately: this feeds a prompt, and a long context slows the
  /// one thing the app can't hide latency behind — the user is looking
  /// at a save button waiting for a tier.
  Future<List<Todo>> withDeadlineNear(
    DateTime center, {
    Duration window = const Duration(days: 5),
    int? excludingId,
    int limit = 5,
  }) async {
    final from = center.subtract(window);
    final to = center.add(window);
    final rows =
        await (_db.select(_db.todos)
              ..where(
                (t) =>
                    t.completedAt.isNull() &
                    t.deadline.isBiggerOrEqualValue(from) &
                    t.deadline.isSmallerOrEqualValue(to),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.deadline)])
              ..limit(limit + (excludingId == null ? 0 : 1)))
            .get();
    final todos = rows.map(_toDomain).toList()
      ..removeWhere((t) => t.id == excludingId);
    return todos.take(limit).toList();
  }

  Future<int> create({
    required String title,
    DateTime? deadline,
    DifficultyTier? difficulty,
    String? notes,
    int? parentId,
    DateTime? now,
  }) {
    return _db
        .into(_db.todos)
        .insert(
          TodosCompanion.insert(
            title: title,
            createdAt: now ?? DateTime.now(),
            deadline: Value(deadline),
            difficulty: Value(difficulty?.name),
            notes: Value(notes),
            parentId: Value(parentId),
          ),
        );
  }

  /// The most recently completed todos, most recent first — what the
  /// Progress screen shows in place of a static "how XP works" table,
  /// since concrete finished work is more legible than a price list.
  Future<List<Todo>> getRecentlyCompleted({int limit = 5}) async {
    final rows =
        await (_db.select(_db.todos)
              ..where((t) => t.completedAt.isNotNull())
              ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Count of todos completed within `[from, to)`.
  ///
  /// This, not a phone-unlock or app-switch count, is the basis for
  /// "how busy has the user been" — a signal count only says the phone
  /// was touched, never what was actually done, so it can't ground a
  /// sentence that names real activity. Finished tasks can.
  Future<int> completedCountBetween(DateTime from, DateTime to) async {
    final rows =
        await (_db.select(_db.todos)..where(
              (t) =>
                  t.completedAt.isBiggerOrEqualValue(from) &
                  t.completedAt.isSmallerThanValue(to),
            ))
            .get();
    return rows.length;
  }

  Future<void> update(Todo todo) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(todo.id))).write(
      TodosCompanion(
        title: Value(todo.title),
        deadline: Value(todo.deadline),
        difficulty: Value(todo.difficulty?.name),
        completedAt: Value(todo.completedAt),
        notes: Value(todo.notes),
      ),
    );
  }

  Future<void> setDifficulty(int id, DifficultyTier tier) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(difficulty: Value(tier.name)),
    );
  }

  Future<void> setCompleted(int id, {required bool completed, DateTime? at}) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        completedAt: Value(completed ? (at ?? DateTime.now()) : null),
      ),
    );
  }

  /// Deletes a todo, any subtasks it owns, and every reminder attached
  /// to them.
  ///
  /// Cleanup lives here rather than in a DB cascade so the policy is
  /// visible in one place — see `Todos.parentId`. It runs in a
  /// transaction because the three deletes are one operation: a failure
  /// between them would orphan subtasks or reminders permanently, and
  /// nothing ever looks for parentless rows to tidy them up later.
  ///
  /// Returns the ids of the reminders that were removed, so the caller
  /// can cancel their OS alarms. Those alarms live outside the database
  /// and outside this transaction — deleting the row is not what stops
  /// the phone ringing. Use `AppServices.deleteTodo`, which does both.
  Future<List<int>> delete(int id) {
    return _db.transaction(() async {
      final subtaskIds =
          await (_db.selectOnly(_db.todos)
                ..addColumns([_db.todos.id])
                ..where(_db.todos.parentId.equals(id)))
              .map((row) => row.read(_db.todos.id)!)
              .get();

      final affected = [id, ...subtaskIds];
      final reminderIds =
          await (_db.selectOnly(_db.reminders)
                ..addColumns([_db.reminders.id])
                ..where(_db.reminders.todoId.isIn(affected)))
              .map((row) => row.read(_db.reminders.id)!)
              .get();

      await (_db.delete(
        _db.reminders,
      )..where((t) => t.todoId.isIn(affected))).go();
      await (_db.delete(_db.todos)..where((t) => t.parentId.equals(id))).go();
      await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();

      return reminderIds;
    });
  }
}
