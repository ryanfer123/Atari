import 'dart:math' as math;

import 'package:atari/engine/baseline/signal_bucket_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignalBucketStats', () {
    test('starts empty', () {
      const stats = SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      expect(stats.count, 0);
      expect(stats.mean, 0);
      expect(stats.variance().isNaN, isTrue);
    });

    test('observe folds in Welford mean/variance incrementally', () {
      const initial = SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      final samples = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];

      var stats = initial;
      for (final x in samples) {
        stats = stats.observe(x);
      }

      final expectedMean = samples.reduce((a, b) => a + b) / samples.length;
      final expectedVariance =
          samples
              .map((x) => math.pow(x - expectedMean, 2))
              .reduce((a, b) => a + b) /
          (samples.length - 1);

      expect(stats.count, samples.length);
      expect(stats.mean, closeTo(expectedMean, 1e-9));
      expect(stats.variance(), closeTo(expectedVariance, 1e-9));
    });

    test('observe does not mutate the original instance', () {
      const initial = SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      final updated = initial.observe(10);

      expect(initial.count, 0);
      expect(updated.count, 1);
      expect(updated.mean, 10);
    });

    test(
      'blendedMean weights the population prior fully at zero observations',
      () {
        const stats = SignalBucketStats(
          signal: 'unlocks',
          hourOfDay: 9,
          dayOfWeek: 2,
        );
        expect(stats.blendedMean(3), 3);
      },
    );

    test('blendedMean weights prior and empirical mean equally at the half-life count', () {
      var stats = const SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      for (var i = 0; i < 20; i++) {
        stats = stats.observe(10);
      }
      expect(stats.count, 20);
      // half-life default is 20 observations, so weight should be exactly 0.5.
      expect(stats.blendedMean(0, halfLifeObservations: 20), closeTo(5, 1e-9));
    });

    test('blendedMean converges toward the empirical mean as observations accumulate', () {
      var stats = const SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      for (var i = 0; i < 200; i++) {
        stats = stats.observe(10);
      }
      // Convergence is asymptotic (w = 0.5^(count/halfLife)), never exact.
      expect(stats.blendedMean(0), closeTo(10, 0.01));
    });

    test('zScore uses the population std below five observations', () {
      var stats = const SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      stats = stats.observe(10); // count == 1, below the threshold of 5
      final z = stats.zScore(10, populationPrior: 0, populationStd: 2);
      // effectiveMean at count=1, halfLife=20: w = 0.5^(1/20) ~= 0.9659
      final w = math.pow(0.5, 1 / 20).toDouble();
      final expectedMean = w * 0 + (1 - w) * 10;
      expect(z, closeTo((10 - expectedMean) / 2, 1e-9));
    });

    test('zScore uses the empirical standard deviation at five or more observations', () {
      var stats = const SignalBucketStats(
        signal: 'unlocks',
        hourOfDay: 9,
        dayOfWeek: 2,
      );
      for (final x in [8.0, 9.0, 10.0, 11.0, 12.0]) {
        stats = stats.observe(x);
      }
      expect(stats.count, 5);
      final empiricalStd = math.sqrt(stats.variance());
      final effectiveMean = stats.blendedMean(0);
      final z = stats.zScore(20, populationPrior: 0, populationStd: 999);
      expect(z, closeTo((20 - effectiveMean) / empiricalStd, 1e-9));
    });

    test(
      'zScore never divides by zero even when variance collapses to zero',
      () {
        var stats = const SignalBucketStats(
          signal: 'unlocks',
          hourOfDay: 9,
          dayOfWeek: 2,
        );
        for (var i = 0; i < 10; i++) {
          stats = stats.observe(5);
        }
        expect(stats.variance(), 0);
        final z = stats.zScore(6, populationPrior: 0, populationStd: 1);
        expect(z.isFinite, isTrue);
      },
    );
  });
}
