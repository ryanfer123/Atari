import 'package:atari/engine/baseline/recent_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityWindow.zScore', () {
    test('is positive when recent activity is higher than before', () {
      const window = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 200, // 40/day
        priorTotal: 100, // 20/day
        windowDays: 5,
      );
      expect(window.zScore, greaterThan(0));
    });

    test('is negative when recent activity is lower than before', () {
      const window = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 100, // 20/day
        priorTotal: 200, // 40/day
        windowDays: 5,
      );
      expect(window.zScore, lessThan(0));
    });

    test('is zero when nothing changed', () {
      const window = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 150,
        priorTotal: 150,
        windowDays: 5,
      );
      expect(window.zScore, 0);
    });

    test('is zero rather than infinite when there is no prior data', () {
      const window = ActivityWindow(
        signal: 'app_switches',
        recentTotal: 80,
        priorTotal: 0,
        windowDays: 5,
      );
      expect(window.zScore, 0);
    });

    test(
      'the same absolute jump scores as more unusual against a smaller '
      'usual rate than a larger one — the Poisson approximation this '
      'is documented to use',
      () {
        const smallBase = ActivityWindow(
          signal: 'unlocks',
          recentTotal: 125, // 25/day
          priorTotal: 5, // 1/day (+24/day, same jump as below)
          windowDays: 5,
        );
        const largeBase = ActivityWindow(
          signal: 'unlocks',
          recentTotal: 320, // 64/day
          priorTotal: 200, // 40/day (+24/day)
          windowDays: 5,
        );
        expect(smallBase.zScore, greaterThan(largeBase.zScore));
      },
    );
  });

  group('ActivityWindow.description', () {
    test('states both per-day rates plainly, as data not a judgement', () {
      const window = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 210,
        priorTotal: 140,
        windowDays: 5,
      );
      expect(window.description, contains('42.0 unlocks a day'));
      expect(window.description, contains('28.0 a day'));
    });
  });

  group('mostChanged', () {
    test('picks the largest-magnitude z-score regardless of sign', () {
      const calmer = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 50,
        priorTotal: 200,
        windowDays: 5,
      );
      const busier = ActivityWindow(
        signal: 'app_switches',
        recentTotal: 220,
        priorTotal: 200,
        windowDays: 5,
      );
      expect(mostChanged([calmer, busier]), same(calmer));
    });

    test('returns null for an empty list', () {
      expect(mostChanged(const []), isNull);
    });

    test('returns the only entry when there is just one', () {
      const only = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 10,
        priorTotal: 10,
        windowDays: 5,
      );
      expect(mostChanged([only]), same(only));
    });
  });

  group('preferredWindow', () {
    test('prefers tasks_completed over a phone signal whenever it has data', () {
      const tasks = ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: 2,
        priorTotal: 1,
        windowDays: 5,
      );
      const unlocks = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 500,
        priorTotal: 10,
        windowDays: 5,
      );
      // Unlocks has the far larger z-score, but a completed task can be
      // named while a raw unlock count cannot — completed work still
      // wins.
      expect(preferredWindow([tasks, unlocks]), same(tasks));
    });

    test('falls back to the most-changed phone signal when nothing was completed', () {
      const tasks = ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: 0,
        priorTotal: 0,
        windowDays: 5,
      );
      const unlocks = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 500,
        priorTotal: 10,
        windowDays: 5,
      );
      expect(preferredWindow([tasks, unlocks]), same(unlocks));
    });

    test('supplies its own zero tasks_completed window when none is given', () {
      const unlocks = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 50,
        priorTotal: 40,
        windowDays: 5,
      );
      expect(preferredWindow([unlocks]), same(unlocks));
    });

    test('returns null when there is nothing at all to compare', () {
      expect(preferredWindow(const []), isNull);
    });
  });

  group('describeActivity', () {
    test('returns null when there is no window to describe', () {
      expect(describeActivity(null, const []), isNull);
    });

    test('falls back to the generic description for a phone signal', () {
      const window = ActivityWindow(
        signal: 'unlocks',
        recentTotal: 210,
        priorTotal: 140,
        windowDays: 5,
      );
      expect(describeActivity(window, const []), window.description);
    });

    test('falls back to the generic description when there is nothing to name', () {
      const window = ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: 3,
        priorTotal: 1,
        windowDays: 5,
      );
      expect(describeActivity(window, const []), window.description);
    });

    test('names real completed tasks instead of a bare count', () {
      const window = ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: 2,
        priorTotal: 1,
        windowDays: 5,
      );
      final note = describeActivity(window, const [
        'Submit the report',
        'Book the dentist',
      ]);
      expect(note, contains('Submit the report'));
      expect(note, contains('Book the dentist'));
      expect(note, contains('versus 1 the 5 days before that'));
    });

    test('summarizes with a total instead of listing more than 3 titles', () {
      const window = ActivityWindow(
        signal: 'tasks_completed',
        recentTotal: 4,
        priorTotal: 2,
        windowDays: 5,
      );
      final note = describeActivity(window, const [
        'One',
        'Two',
        'Three',
        'Four',
      ]);
      expect(note, contains('One, Two, Three'));
      expect(note, isNot(contains('Four')));
      expect(note, contains('4 finished in total over the last 5 days'));
    });
  });
}
