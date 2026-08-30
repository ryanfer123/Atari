import 'package:atari/core/models/difficulty_tier.dart';
import 'package:atari/core/models/gamification_event.dart';
import 'package:atari/engine/gamification/gamification_progress.dart';
import 'package:flutter_test/flutter_test.dart';

GamificationEvent _event(GamificationTrigger trigger, DateTime at, {int? xp}) =>
    GamificationEvent(
      trigger: trigger,
      xpAwarded: xp ?? xpForTrigger(trigger),
      timestamp: at,
    );

void main() {
  group('xpForTrigger', () {
    test('awards the fixed XP amount per trigger from §4.7', () {
      expect(xpForTrigger(GamificationTrigger.interventionWorked), 15);
      expect(xpForTrigger(GamificationTrigger.healthTargetMet), 10);
      expect(xpForTrigger(GamificationTrigger.captureOrganized), 5);
    });

    test('completing a task scales with its difficulty tier', () {
      // The point of the model picking a tier: a flat award would
      // discard it, and would contradict the difficulty chip and the
      // completion snackbar, which both show xpForDifficulty.
      for (final tier in DifficultyTier.values) {
        expect(
          xpForTrigger(GamificationTrigger.todoCompleted, difficulty: tier),
          xpForDifficulty(tier),
          reason: 'tier $tier should award exactly what the UI advertises',
        );
      }

      // Guards against the tiers collapsing to one number again.
      expect(
        xpForTrigger(
          GamificationTrigger.todoCompleted,
          difficulty: DifficultyTier.heavy,
        ),
        greaterThan(
          xpForTrigger(
            GamificationTrigger.todoCompleted,
            difficulty: DifficultyTier.trivial,
          ),
        ),
      );
    });

    test('a task with no tier yet falls back to the default award', () {
      expect(
        xpForTrigger(GamificationTrigger.todoCompleted),
        xpForDifficulty(fallbackDifficultyTier),
      );
    });
  });

  group('levelForXp', () {
    test('starts at level 1 with zero XP', () {
      expect(levelForXp(0), 1);
    });

    test('stays at level 1 until xpPerLevel is reached', () {
      expect(levelForXp(xpPerLevel - 1), 1);
    });

    test('advances to level 2 exactly at xpPerLevel', () {
      expect(levelForXp(xpPerLevel), 2);
    });

    test('advances multiple levels for large XP totals', () {
      expect(levelForXp(xpPerLevel * 3 + 50), 4);
    });
  });

  group('GamificationProgress.fromEvents', () {
    final day1 = DateTime(2026, 8, 24, 9);
    final day1Later = DateTime(2026, 8, 24, 20);
    final day3 = DateTime(2026, 8, 26, 9); // day 2 (8/25) skipped

    test('an empty event log has zero XP, level 1, and no active days', () {
      final progress = GamificationProgress.fromEvents(const []);
      expect(progress.totalXp, 0);
      expect(progress.level, 1);
      expect(progress.activeDayCount, 0);
    });

    test('totalXp is the sum of every event\'s xpAwarded', () {
      final progress = GamificationProgress.fromEvents([
        _event(GamificationTrigger.todoCompleted, day1),
        _event(GamificationTrigger.healthTargetMet, day1Later),
      ]);
      expect(progress.totalXp, 20);
    });

    test(
      'multiple events on the same calendar day count as one active day',
      () {
        final progress = GamificationProgress.fromEvents([
          _event(GamificationTrigger.todoCompleted, day1),
          _event(GamificationTrigger.captureOrganized, day1Later),
        ]);
        expect(progress.activeDayCount, 1);
      },
    );

    test(
      'a gap day between active days does not reduce the active-day count',
      () {
        final progress = GamificationProgress.fromEvents([
          _event(GamificationTrigger.todoCompleted, day1),
          _event(GamificationTrigger.todoCompleted, day3),
        ]);

        // Two active days (8/24 and 8/26); the skipped 8/25 simply never
        // contributed, it did not subtract from a prior count.
        expect(progress.activeDayCount, 2);
      },
    );

    test(
      'level is derived from the summed totalXp, not counted separately',
      () {
        final progress = GamificationProgress.fromEvents([
          _event(GamificationTrigger.interventionWorked, day1, xp: xpPerLevel),
        ]);
        expect(progress.totalXp, xpPerLevel);
        expect(progress.level, levelForXp(xpPerLevel));
      },
    );
  });
}
