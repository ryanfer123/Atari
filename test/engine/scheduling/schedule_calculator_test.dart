import 'package:atari/engine/scheduling/schedule_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextOccurrence', () {
    test('picks later today when the time has not passed yet', () {
      // A Monday at 09:00.
      final from = DateTime(2026, 9, 21, 9, 0);
      final next = nextOccurrence(
        hour: 18,
        minute: 30,
        weekdays: {DateTime.monday},
        from: from,
      );
      expect(next, DateTime(2026, 9, 21, 18, 30));
    });

    test('rolls to next week when today matches but the time already passed', () {
      final from = DateTime(2026, 9, 21, 20, 0); // Monday 8pm
      final next = nextOccurrence(
        hour: 18,
        minute: 30,
        weekdays: {DateTime.monday},
        from: from,
      );
      expect(next, DateTime(2026, 9, 28, 18, 30));
    });

    test('finds the nearest matching weekday among several', () {
      final from = DateTime(2026, 9, 21, 9, 0); // Monday
      final next = nextOccurrence(
        hour: 7,
        minute: 0,
        weekdays: {DateTime.wednesday, DateTime.friday},
        from: from,
      );
      expect(next, DateTime(2026, 9, 23, 7, 0)); // Wednesday
    });

    test('every day picks tomorrow when today already passed', () {
      final from = DateTime(2026, 9, 21, 23, 0); // Monday 11pm
      final next = nextOccurrence(
        hour: 6,
        minute: 0,
        weekdays: const {1, 2, 3, 4, 5, 6, 7},
        from: from,
      );
      expect(next, DateTime(2026, 9, 22, 6, 0));
    });

    test('a candidate exactly at from is not treated as due', () {
      final from = DateTime(2026, 9, 21, 18, 30);
      final next = nextOccurrence(
        hour: 18,
        minute: 30,
        weekdays: {DateTime.monday},
        from: from,
      );
      // Strictly after, not on-the-dot, so it rolls a full week rather
      // than firing an alarm for a moment that has already arrived.
      expect(next, DateTime(2026, 9, 28, 18, 30));
    });
  });

  group('findNearestClash', () {
    test('finds an entry inside the window', () {
      final candidate = DateTime(2026, 9, 21, 17, 0);
      final clash = findNearestClash(
        candidate: candidate,
        existing: [DateTime(2026, 9, 21, 17, 20)],
      );
      expect(clash, DateTime(2026, 9, 21, 17, 20));
    });

    test('ignores entries outside the window', () {
      final candidate = DateTime(2026, 9, 21, 17, 0);
      final clash = findNearestClash(
        candidate: candidate,
        existing: [DateTime(2026, 9, 21, 19, 0)],
      );
      expect(clash, isNull);
    });

    test('returns the nearest of several candidates, not just the first', () {
      final candidate = DateTime(2026, 9, 21, 17, 0);
      final clash = findNearestClash(
        candidate: candidate,
        existing: [
          DateTime(2026, 9, 21, 17, 25),
          DateTime(2026, 9, 21, 17, 5),
        ],
      );
      expect(clash, DateTime(2026, 9, 21, 17, 5));
    });

    test('a window boundary exactly at the limit counts as a clash', () {
      final candidate = DateTime(2026, 9, 21, 17, 0);
      final clash = findNearestClash(
        candidate: candidate,
        existing: [DateTime(2026, 9, 21, 17, 30)],
        window: const Duration(minutes: 30),
      );
      expect(clash, isNotNull);
    });

    test('an empty existing list never clashes', () {
      expect(
        findNearestClash(
          candidate: DateTime(2026, 9, 21, 17, 0),
          existing: const [],
        ),
        isNull,
      );
    });
  });
}
