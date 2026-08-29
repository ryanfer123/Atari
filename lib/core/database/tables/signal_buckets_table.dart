import 'package:drift/drift.dart';

/// Persisted form of `SignalBucketStats` (`lib/engine/baseline`): one
/// Welford accumulator per `(signal, hourOfDay, dayOfWeek)` bucket.
///
/// See Plans/IMPLEMENTATION.md §4.1.
@DataClassName('SignalBucketRow')
class SignalBuckets extends Table {
  TextColumn get signal => text()();
  IntColumn get hourOfDay => integer()();
  IntColumn get dayOfWeek => integer()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  RealColumn get mean => real().withDefault(const Constant(0))();
  RealColumn get m2 => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {signal, hourOfDay, dayOfWeek};
}
