import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/models/health_target.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Exercises `AppDatabase.migration`'s v3 -> v4 upgrade against a real
/// pre-migration database, not just a fresh v4 `onCreate`.
///
/// This is the gap the rest of the migration strategy has always had:
/// every earlier version bump only ever ran the happy path on a device
/// during development. That's fine for catching a typo, but it proves
/// nothing about whether upgrading a phone that already has months of
/// real data survives the change — which is exactly the case that
/// matters once there is data on a device worth not corrupting.
///
/// The v3 shape below is hand-written to match what `CREATE TABLE`
/// actually produced before this migration was added (checked against
/// the real generated SQL), not derived from the current table
/// classes — using the current classes would make this test validate
/// against itself and catch nothing.
void main() {
  test('adding health-target schedules and reminders.health_target_id '
      'preserves existing rows', () async {
    final raw = sqlite3.sqlite3.openInMemory();

    // The exact v3 shape of the two tables this migration touches.
    // created_at/scheduled_for use the same "unix seconds" integer
    // encoding Drift's NativeDatabase already uses for DateTimeColumn,
    // confirmed against a real insert rather than assumed.
    raw.execute('''
      CREATE TABLE "health_targets" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "metric" TEXT NOT NULL,
        "threshold" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL,
        "active" INTEGER NOT NULL DEFAULT 1 CHECK ("active" IN (0, 1)),
        "last_met_at" INTEGER NULL
      );
      CREATE TABLE "reminders" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "title" TEXT NOT NULL,
        "scheduled_for" INTEGER NOT NULL,
        "tool" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL,
        "todo_id" INTEGER NULL,
        "fired_at" INTEGER NULL,
        "cancelled" INTEGER NOT NULL DEFAULT 0 CHECK ("cancelled" IN (0, 1))
      );
    ''');
    raw.execute('''
      INSERT INTO health_targets (id, metric, threshold, created_at, active)
      VALUES (1, 'steps', '8000', 1767240000, 1);
    ''');
    raw.execute('''
      INSERT INTO reminders (id, title, scheduled_for, tool, created_at, todo_id)
      VALUES (1, 'Submit the report', 1767328200, 'setReminder', 1767240000, 42);
    ''');
    raw.execute('PRAGMA user_version = 3');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    // Any query forces Drift to compare PRAGMA user_version (3) against
    // schemaVersion (4) and run onUpgrade before answering it.
    final targets = await db.select(db.healthTargets).get();
    final reminders = await db.select(db.reminders).get();

    expect(targets, hasLength(1));
    final target = targets.single;
    expect(target.metric, 'steps');
    expect(target.threshold, '8000');
    // The new columns exist and read as "no schedule configured" for a
    // row that predates them — not a crash, not a default that looks
    // like a real answer.
    expect(target.reminderTime, isNull);
    expect(target.activeDaysMask, isNull);

    expect(reminders, hasLength(1));
    final reminder = reminders.single;
    expect(reminder.title, 'Submit the report');
    expect(reminder.todoId, 42);
    // The new FK-shaped column exists and this pre-existing row, which
    // belongs to a todo, correctly has no health target owner.
    expect(reminder.healthTargetId, isNull);

    // The upgraded database is also fully writable through the new
    // columns, not just readable.
    final id = await db
        .into(db.healthTargets)
        .insert(
          HealthTargetsCompanion.insert(
            metric: 'water',
            threshold: '2L',
            createdAt: DateTime.now(),
            reminderTime: const Value('18:00'),
            activeDaysMask: const Value(everyDayMask),
          ),
        );
    final written = await (db.select(
      db.healthTargets,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(written.reminderTime, '18:00');
    expect(written.activeDaysMask, everyDayMask);
  });
}
