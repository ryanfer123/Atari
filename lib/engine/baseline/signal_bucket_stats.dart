import 'dart:math' as math;

/// Welford online mean/variance for one signal within one
/// `(hourOfDay, dayOfWeek)` bucket, plus the Bayesian cold-start blend that
/// lets a population-default prior decay out as personal data accumulates.
///
/// Immutable: [observe] returns the next state rather than mutating in
/// place, so callers (notably [BaselineStore]) can treat a bucket as a
/// plain value loaded from and written back to storage.
///
/// See Plans/IMPLEMENTATION.md §4.1.
class SignalBucketStats {
  const SignalBucketStats({
    required this.signal,
    required this.hourOfDay,
    required this.dayOfWeek,
    this.count = 0,
    this.mean = 0,
    this.m2 = 0,
  }) : assert(hourOfDay >= 0 && hourOfDay <= 23),
       assert(dayOfWeek >= 1 && dayOfWeek <= 7);

  /// e.g. `unlocks`, `app_switches`, `notif_latency_ms`.
  final String signal;

  /// 0-23.
  final int hourOfDay;

  /// 1-7 (ISO-8601: Monday = 1 .. Sunday = 7, matching `DateTime.weekday`).
  final int dayOfWeek;

  final int count;
  final double mean;

  /// Sum of squared deviations from the running mean, for variance.
  final double m2;

  /// Folds one new observation in and returns the updated bucket.
  SignalBucketStats observe(double x) {
    final newCount = count + 1;
    final delta = x - mean;
    final newMean = mean + delta / newCount;
    final delta2 = x - newMean;
    final newM2 = m2 + delta * delta2;
    return SignalBucketStats(
      signal: signal,
      hourOfDay: hourOfDay,
      dayOfWeek: dayOfWeek,
      count: newCount,
      mean: newMean,
      m2: newM2,
    );
  }

  /// Sample variance (Bessel-corrected). `NaN` below two observations.
  double variance() => count < 2 ? double.nan : m2 / (count - 1);

  /// Population prior decays out as personal data accumulates: at
  /// `count == halfLifeObservations` the prior and the empirical mean are
  /// weighted equally.
  double blendedMean(double populationPrior, {int halfLifeObservations = 20}) {
    final w = math.pow(0.5, count / halfLifeObservations).toDouble();
    return w * populationPrior + (1 - w) * mean;
  }

  /// Z-score of [x] against the cold-start-blended mean. Below five
  /// observations the empirical variance is too noisy to trust, so
  /// [populationStd] is used instead of the sample standard deviation.
  double zScore(
    double x, {
    required double populationPrior,
    required double populationStd,
  }) {
    final effectiveMean = blendedMean(populationPrior);
    final std = count < 5
        ? populationStd
        : math.max(math.sqrt(variance()), 1e-6);
    return (x - effectiveMean) / std;
  }

  @override
  String toString() =>
      'SignalBucketStats(signal: $signal, hourOfDay: $hourOfDay, '
      'dayOfWeek: $dayOfWeek, count: $count, mean: $mean, m2: $m2)';
}
