import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/captures_table.dart';
import 'tables/gamification_events_table.dart';
import 'tables/health_targets_table.dart';
import 'tables/notes_table.dart';
import 'tables/reminders_table.dart';
import 'tables/signal_buckets_table.dart';
import 'tables/todos_table.dart';

part 'app_database.g.dart';

/// Local-only, on-device SQLite database (via Drift). No table here is ever
/// synced off-device — see README.md's architectural boundaries.
@DriftDatabase(
  tables: [
    SignalBuckets,
    GamificationEvents,
    Todos,
    Notes,
    HealthTargets,
    Reminders,
    Captures,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the pivot's product tables (Plans/PIVOT_PLAN.md §2.6):
      // todos, notes, health targets, and confirmed reminders. The v1
      // tables (signal buckets, gamification events) are untouched, so
      // existing on-device baseline/XP history survives the upgrade.
      if (from < 2) {
        await m.createTable(todos);
        await m.createTable(notes);
        await m.createTable(healthTargets);
        await m.createTable(reminders);
      }
      // v3 adds saved captures and the embedding columns that make
      // notes and captures semantically searchable. Existing rows keep
      // null embeddings until they are next saved — searchable by
      // nothing rather than lost.
      if (from < 3) {
        await m.createTable(captures);
        await m.addColumn(notes, notes.embedding);
        await m.addColumn(notes, notes.embeddingModel);
        await m.addColumn(notes, notes.embeddingDimensions);
      }
      // v4 adds recurring schedules to health targets (a time of day
      // plus which weekdays) and the reminder link that lets a health
      // target own scheduled occurrences the same way a todo does.
      // Existing targets keep both columns null, which reads as "no
      // schedule configured" rather than a hidden default.
      if (from < 4) {
        await m.addColumn(healthTargets, healthTargets.reminderTime);
        await m.addColumn(healthTargets, healthTargets.activeDaysMask);
        await m.addColumn(reminders, reminders.healthTargetId);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'atari.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
