import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'population_priors.dart';
import 'signal_bucket_stats.dart';

/// On-device, per-signal personal baseline.
///
/// Wraps Drift-backed `SignalBuckets` storage around
/// [SignalBucketStats]' Welford/Bayesian-blend math: every mutating call
/// reads the current bucket, folds in the new observation, and writes the
/// updated bucket back, so in-memory state and storage never diverge.
///
/// See Plans/IMPLEMENTATION.md §4.1.
class BaselineStore {
  BaselineStore(this._db, {this.priors = defaultPopulationPriors});

  final AppDatabase _db;

  /// Population-default priors per signal, used for the cold-start blend.
  /// See [defaultPopulationPriors] for why these are hardcoded placeholders.
  final Map<String, PopulationPrior> priors;

  /// Folds [value] into the bucket for [signal] at [at]'s
  /// `(hourOfDay, dayOfWeek)`, persists it, and returns the updated stats.
  Future<SignalBucketStats> observe(
    String signal,
    DateTime at,
    double value,
  ) async {
    final current = await _load(signal, at);
    final updated = current.observe(value);
    await _save(updated);
    return updated;
  }

  /// Z-score of [value] against [signal]'s current baseline for [at]'s
  /// bucket, without recording [value] as a new observation.
  ///
  /// The classifier (`lib/engine/detection`) scores against the existing
  /// baseline before deciding whether the sample should be folded in as a
  /// new observation, so scoring and observing are deliberately separate
  /// calls rather than one combined "score and record" method.
  Future<double> zScoreFor(String signal, DateTime at, double value) async {
    final bucket = await _load(signal, at);
    final prior = priors[signal];
    if (prior == null) {
      throw ArgumentError.value(
        signal,
        'signal',
        'No population prior registered for this signal',
      );
    }
    return bucket.zScore(
      value,
      populationPrior: prior.mean,
      populationStd: prior.std,
    );
  }

  Future<SignalBucketStats> _load(String signal, DateTime at) async {
    final hourOfDay = at.hour;
    final dayOfWeek = at.weekday;
    final row =
        await (_db.select(_db.signalBuckets)..where(
              (t) =>
                  t.signal.equals(signal) &
                  t.hourOfDay.equals(hourOfDay) &
                  t.dayOfWeek.equals(dayOfWeek),
            ))
            .getSingleOrNull();
    if (row == null) {
      return SignalBucketStats(
        signal: signal,
        hourOfDay: hourOfDay,
        dayOfWeek: dayOfWeek,
      );
    }
    return SignalBucketStats(
      signal: row.signal,
      hourOfDay: row.hourOfDay,
      dayOfWeek: row.dayOfWeek,
      count: row.count,
      mean: row.mean,
      m2: row.m2,
    );
  }

  Future<void> _save(SignalBucketStats stats) {
    return _db
        .into(_db.signalBuckets)
        .insertOnConflictUpdate(
          SignalBucketsCompanion.insert(
            signal: stats.signal,
            hourOfDay: stats.hourOfDay,
            dayOfWeek: stats.dayOfWeek,
            count: Value(stats.count),
            mean: Value(stats.mean),
            m2: Value(stats.m2),
          ),
        );
  }
}
