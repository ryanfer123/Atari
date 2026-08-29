import 'dart:math' as math;

import 'package:atari/engine/feedback/intervention_bandit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [math.Random] with fully scripted outputs, so bandit exploration vs.
/// exploitation is deterministic instead of statistical in tests.
class _ScriptedRandom implements math.Random {
  _ScriptedRandom({this.doubles = const [], this.ints = const []});

  final List<double> doubles;
  final List<int> ints;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  double nextDouble() => doubles[_doubleIndex++];

  @override
  int nextInt(int max) => ints[_intIndex++];

  @override
  bool nextBool() => throw UnimplementedError();
}

void main() {
  group('InterventionBandit', () {
    test('requires at least one arm', () {
      expect(
        () => InterventionBandit(arms: const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'explores an unpulled arm even when epsilon would not otherwise trigger',
      () {
        final bandit = InterventionBandit(
          arms: const ['focus_layer', 'break_notification'],
          epsilon: 0,
          random: _ScriptedRandom(doubles: [0.99], ints: [1]),
        );

        expect(bandit.choose(), 'break_notification');
      },
    );

    test('exploits the arm with the highest running average once all arms have data', () {
      final bandit = InterventionBandit(
        arms: const ['focus_layer', 'break_notification'],
        epsilon: 0,
        random: _ScriptedRandom(
          doubles: [0.99],
        ), // 0.99 >= epsilon(0) -> exploit
      );

      bandit.record('focus_layer', 0.10);
      bandit.record('break_notification', 0.02);

      expect(bandit.choose(), 'focus_layer');
    });

    test('explores with probability epsilon even after every arm has data', () {
      final bandit = InterventionBandit(
        arms: const ['focus_layer', 'break_notification'],
        epsilon: 0.2,
        random: _ScriptedRandom(
          doubles: [0.05],
          ints: [1],
        ), // 0.05 < epsilon(0.2) -> explore
      );

      bandit.record('focus_layer', 0.50); // clearly the better arm
      bandit.record('break_notification', 0.01);

      expect(bandit.choose(), 'break_notification');
    });

    test('record accumulates pulls and running average effect', () {
      final bandit = InterventionBandit(arms: const ['focus_layer']);

      bandit.record('focus_layer', 0.10);
      bandit.record('focus_layer', 0.20);

      expect(bandit.pullsFor('focus_layer'), 2);
      expect(bandit.averageEffectFor('focus_layer'), closeTo(0.15, 1e-9));
    });

    test(
      'a negative effect size is recorded normally, not treated as an error',
      () {
        final bandit = InterventionBandit(arms: const ['focus_layer']);

        bandit.record('focus_layer', -0.10);

        expect(bandit.pullsFor('focus_layer'), 1);
        expect(bandit.averageEffectFor('focus_layer'), closeTo(-0.10, 1e-9));
      },
    );

    test('averageEffectFor is zero for an arm that has never been pulled', () {
      final bandit = InterventionBandit(arms: const ['focus_layer']);
      expect(bandit.averageEffectFor('focus_layer'), 0);
    });
  });
}
