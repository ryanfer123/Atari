import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/models/gamification_event.dart';
import 'package:atari/engine/gamification/gamification_engine.dart';
import 'package:atari/engine/gamification/gamification_progress.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('GamificationEngine', () {
    test(
      'onTrigger persists an event with the correct trigger, XP, and timestamp',
      () async {
        final fixedNow = DateTime(2026, 8, 25, 9);
        final engine = GamificationEngine(db, now: () => fixedNow);

        final event = await engine.onTrigger(GamificationTrigger.todoCompleted);

        expect(event.trigger, GamificationTrigger.todoCompleted);
        expect(
          event.xpAwarded,
          xpForTrigger(GamificationTrigger.todoCompleted),
        );
        expect(event.timestamp, fixedNow);
      },
    );

    test('currentProgress reflects every persisted event', () async {
      final engine = GamificationEngine(
        db,
        now: () => DateTime(2026, 8, 25, 9),
      );

      await engine.onTrigger(GamificationTrigger.interventionWorked); // 15
      await engine.onTrigger(GamificationTrigger.captureOrganized); // 5

      final progress = await engine.currentProgress();

      expect(progress.totalXp, 20);
      expect(progress.activeDayCount, 1);
    });

    test(
      'XP is monotonically non-decreasing across successive triggers',
      () async {
        final engine = GamificationEngine(
          db,
          now: () => DateTime(2026, 8, 25, 9),
        );

        final before = await engine.currentProgress();
        await engine.onTrigger(GamificationTrigger.healthTargetMet);
        final after = await engine.currentProgress();

        expect(after.totalXp, greaterThan(before.totalXp));
      },
    );

    test(
      'triggers on different days accumulate distinct active days',
      () async {
        var current = DateTime(2026, 8, 24, 9);
        final engine = GamificationEngine(db, now: () => current);

        await engine.onTrigger(GamificationTrigger.todoCompleted);
        current = DateTime(2026, 8, 25, 9);
        await engine.onTrigger(GamificationTrigger.todoCompleted);

        final progress = await engine.currentProgress();
        expect(progress.activeDayCount, 2);
      },
    );

    test('a fresh GamificationEngine instance reads back events persisted by a previous instance', () async {
      final engine = GamificationEngine(
        db,
        now: () => DateTime(2026, 8, 25, 9),
      );
      await engine.onTrigger(GamificationTrigger.interventionWorked);

      final reopened = GamificationEngine(db);
      final progress = await reopened.currentProgress();

      expect(progress.totalXp, 15);
    });
  });
}
