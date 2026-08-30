import 'package:drift/drift.dart';

import '../models/health_target.dart';
import 'app_database.dart';

class HealthTargetRepository {
  HealthTargetRepository(this._db);

  final AppDatabase _db;

  HealthTarget _toDomain(HealthTargetRow row) => HealthTarget(
    id: row.id,
    metric: row.metric,
    threshold: row.threshold,
    createdAt: row.createdAt,
    active: row.active,
    lastMetAt: row.lastMetAt,
    reminderTime: row.reminderTime,
    activeDaysMask: row.activeDaysMask,
  );

  Stream<List<HealthTarget>> watchAll() {
    return (_db.select(_db.healthTargets)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  /// Active targets only — the direct field query `GoalContext` uses for
  /// the `healthTargets` source (Plans/IMPLEMENTATION.md §4.5).
  Future<List<HealthTarget>> activeTargets() async {
    final rows = await (_db.select(
      _db.healthTargets,
    )..where((t) => t.active.equals(true))).get();
    return rows.map(_toDomain).toList();
  }

  /// Pass both [reminderTime] and [activeDaysMask] together, or neither
  /// — a schedule is one concrete thing (see the table's doc comment),
  /// so a target is never left with a time but no days or vice versa.
  Future<int> create({
    required String metric,
    required String threshold,
    String? reminderTime,
    int? activeDaysMask,
    DateTime? now,
  }) {
    assert(
      (reminderTime == null) == (activeDaysMask == null),
      'a schedule needs both a time and a set of days, or neither',
    );
    return _db
        .into(_db.healthTargets)
        .insert(
          HealthTargetsCompanion.insert(
            metric: metric,
            threshold: threshold,
            createdAt: now ?? DateTime.now(),
            reminderTime: Value(reminderTime),
            activeDaysMask: Value(activeDaysMask),
          ),
        );
  }

  Future<void> setActive(int id, bool active) {
    return (_db.update(_db.healthTargets)..where((t) => t.id.equals(id))).write(
      HealthTargetsCompanion(active: Value(active)),
    );
  }

  /// Marks the target met "now". Feeds a `healthTargetMet` gamification
  /// trigger at the call site — this repository only records the fact.
  Future<void> markMet(int id, {DateTime? at}) {
    return (_db.update(_db.healthTargets)..where((t) => t.id.equals(id))).write(
      HealthTargetsCompanion(lastMetAt: Value(at ?? DateTime.now())),
    );
  }

  /// Deletes the target and any reminders scheduled from it, returning
  /// the removed reminders' ids so the caller can cancel their OS
  /// alarms — the same shape as `TodoRepository.delete`, and for the
  /// same reason: deleting only the row would leave a check-in still
  /// firing for a target the user removed.
  Future<List<int>> delete(int id) {
    return _db.transaction(() async {
      final reminderIds =
          await (_db.selectOnly(_db.reminders)
                ..addColumns([_db.reminders.id])
                ..where(_db.reminders.healthTargetId.equals(id)))
              .map((row) => row.read(_db.reminders.id)!)
              .get();

      await (_db.delete(
        _db.reminders,
      )..where((t) => t.healthTargetId.equals(id))).go();
      await (_db.delete(
        _db.healthTargets,
      )..where((t) => t.id.equals(id))).go();

      return reminderIds;
    });
  }
}
