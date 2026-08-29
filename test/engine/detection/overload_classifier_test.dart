import 'package:atari/engine/detection/overload_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverloadClassifier', () {
    test('returns null when severity does not exceed the threshold', () {
      final classifier = OverloadClassifier(
        weights: {'unlocks': 1.0},
        threshold: 5,
      );
      expect(classifier.classify({'unlocks': 4.9}), isNull);
    });

    test('returns null when severity exactly equals the threshold', () {
      final classifier = OverloadClassifier(
        weights: {'unlocks': 1.0},
        threshold: 5,
      );
      expect(classifier.classify({'unlocks': 5}), isNull);
    });

    test('returns an event with the weighted-sum severity once the threshold is exceeded', () {
      final fixedNow = DateTime(2026, 8, 25, 9);
      final classifier = OverloadClassifier(
        weights: {'unlocks': 2.0, 'app_switches': 1.0},
        threshold: 5,
        now: () => fixedNow,
      );

      final event = classifier.classify({'unlocks': 2.0, 'app_switches': 3.0});

      expect(event, isNotNull);
      expect(event!.severity, closeTo(2.0 * 2.0 + 1.0 * 3.0, 1e-9));
      expect(event.timestamp, fixedNow);
      expect(event.signalScores, {'unlocks': 2.0, 'app_switches': 3.0});
    });

    test('a signal below its baseline (negative z-score) never contributes to severity', () {
      final classifier = OverloadClassifier(
        weights: {'unlocks': 10.0, 'app_switches': 10.0},
        threshold: 1,
      );

      // app_switches is well below baseline; only unlocks should count.
      final event = classifier.classify({'unlocks': 1.0, 'app_switches': -5.0});

      expect(event, isNotNull);
      expect(event!.severity, closeTo(10.0, 1e-9));
    });

    test('a signal with no configured weight contributes zero', () {
      final classifier = OverloadClassifier(
        weights: {'unlocks': 1.0},
        threshold: 1,
      );

      final event = classifier.classify({
        'unlocks': 0.5,
        'notif_latency_ms': 100,
      });

      expect(event, isNull);
    });
  });
}
