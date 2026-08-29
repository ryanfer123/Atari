import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/gamification_events_table.dart';
import 'tables/signal_buckets_table.dart';

part 'app_database.g.dart';

/// Local-only, on-device SQLite database (via Drift). No table here is ever
/// synced off-device — see README.md's architectural boundaries.
@DriftDatabase(tables: [SignalBuckets, GamificationEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'atari.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
