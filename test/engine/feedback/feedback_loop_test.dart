import 'package:atari/engine/feedback/feedback_loop.dart';
import 'package:atari/engine/feedback/intervention_bandit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackLoop', () {
    test('evaluate computes fractional signal drop and flags success at the threshold', () async {
      final bandit = InterventionBandit(arms: const ['focus_layer']);
      final loop = FeedbackLoop(
        bandit: bandit,
        measureSignalWindow: (signal, start, end) async =>
            9.5, // 5% drop from preValue 10
      );

      final result = await loop.evaluate(
        arm: 'focus_layer',
        signal: 'unlocks',
        preValue: 10,
        postWindowStart: DateTime(2026, 8, 25, 9),
        postWindowEnd: DateTime(2026, 8, 25, 9, 15),
      );

      expect(result.effectSize, closeTo(0.05, 1e-9));
      expect(result.worked, isTrue);
    });

    test('evaluate flags failure just below the success threshold', () async {
      final bandit = InterventionBandit(arms: const ['focus_layer']);
      final loop = FeedbackLoop(
        bandit: bandit,
        measureSignalWindow: (signal, start, end) async => 9.6, // 4% drop
      );

      final result = await loop.evaluate(
        arm: 'focus_layer',
        signal: 'unlocks',
        preValue: 10,
        postWindowStart: DateTime(2026, 8, 25, 9),
        postWindowEnd: DateTime(2026, 8, 25, 9, 15),
      );

      expect(result.effectSize, closeTo(0.04, 1e-9));
      expect(result.worked, isFalse);
    });

    test(
      'a signal increase (negative effect size) is recorded, not thrown away',
      () async {
        final bandit = InterventionBandit(arms: const ['focus_layer']);
        final loop = FeedbackLoop(
          bandit: bandit,
          measureSignalWindow: (signal, start, end) async =>
              12, // signal went up
        );

        final result = await loop.evaluate(
          arm: 'focus_layer',
          signal: 'unlocks',
          preValue: 10,
          postWindowStart: DateTime(2026, 8, 25, 9),
          postWindowEnd: DateTime(2026, 8, 25, 9, 15),
        );

        expect(result.effectSize, closeTo(-0.2, 1e-9));
        expect(result.worked, isFalse);
        expect(bandit.pullsFor('focus_layer'), 1);
        expect(bandit.averageEffectFor('focus_layer'), closeTo(-0.2, 1e-9));
      },
    );

    test('evaluate is safe when preValue is zero', () async {
      final bandit = InterventionBandit(arms: const ['focus_layer']);
      final loop = FeedbackLoop(
        bandit: bandit,
        measureSignalWindow: (signal, start, end) async => 3,
      );

      final result = await loop.evaluate(
        arm: 'focus_layer',
        signal: 'unlocks',
        preValue: 0,
        postWindowStart: DateTime(2026, 8, 25, 9),
        postWindowEnd: DateTime(2026, 8, 25, 9, 15),
      );

      expect(result.effectSize, 0.0);
      expect(result.worked, isFalse);
    });

    test(
      'evaluate records the outcome against the bandit arm it was called with',
      () async {
        final bandit = InterventionBandit(
          arms: const ['focus_layer', 'break_notification'],
        );
        final loop = FeedbackLoop(
          bandit: bandit,
          measureSignalWindow: (signal, start, end) async => 8,
        );

        await loop.evaluate(
          arm: 'break_notification',
          signal: 'unlocks',
          preValue: 10,
          postWindowStart: DateTime(2026, 8, 25, 9),
          postWindowEnd: DateTime(2026, 8, 25, 9, 15),
        );

        expect(bandit.pullsFor('break_notification'), 1);
        expect(bandit.pullsFor('focus_layer'), 0);
      },
    );

    test('chooseIntervention delegates to the bandit', () {
      final bandit = InterventionBandit(arms: const ['only_arm']);
      final loop = FeedbackLoop(
        bandit: bandit,
        measureSignalWindow: (signal, start, end) async => 0,
      );

      expect(loop.chooseIntervention(), 'only_arm');
    });

    test('measureSignalWindow passes the signal and window through to the injected measurer', () async {
      String? capturedSignal;
      DateTime? capturedStart;
      DateTime? capturedEnd;

      final loop = FeedbackLoop(
        bandit: InterventionBandit(arms: const ['focus_layer']),
        measureSignalWindow: (signal, start, end) async {
          capturedSignal = signal;
          capturedStart = start;
          capturedEnd = end;
          return 42;
        },
      );

      final start = DateTime(2026, 8, 25, 9);
      final end = DateTime(2026, 8, 25, 9, 15);
      final value = await loop.measureSignalWindow('app_switches', start, end);

      expect(value, 42);
      expect(capturedSignal, 'app_switches');
      expect(capturedStart, start);
      expect(capturedEnd, end);
    });
  });
}
