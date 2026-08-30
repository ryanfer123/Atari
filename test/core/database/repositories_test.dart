import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/database/health_target_repository.dart';
import 'package:atari/core/database/note_repository.dart';
import 'package:atari/core/database/reminder_repository.dart';
import 'package:atari/core/database/todo_repository.dart';
import 'package:atari/core/models/difficulty_tier.dart';
import 'package:atari/core/models/health_target.dart';
import 'package:atari/core/models/task_tool.dart';
import 'package:atari/core/services/placeholders/placeholder_embedding_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('TodoRepository', () {
    test('creates and reads back a todo with its difficulty', () async {
      final repo = TodoRepository(db);
      final id = await repo.create(
        title: 'Write report',
        difficulty: DifficultyTier.heavy,
      );

      final todo = await repo.findById(id);
      expect(todo, isNotNull);
      expect(todo!.title, 'Write report');
      expect(todo.difficulty, DifficultyTier.heavy);
      expect(todo.isCompleted, isFalse);
    });

    test(
      'an unscored todo reads back with a null difficulty, not a default',
      () async {
        final repo = TodoRepository(db);
        final id = await repo.create(title: 'Unscored');
        expect((await repo.findById(id))!.difficulty, isNull);
      },
    );

    test('getTopLevel excludes subtasks', () async {
      final repo = TodoRepository(db);
      final parent = await repo.create(title: 'Parent');
      await repo.create(title: 'Child', parentId: parent);

      final topLevel = await repo.getTopLevel();
      expect(topLevel.map((t) => t.title), ['Parent']);
    });

    test('deleting a parent removes its subtasks too', () async {
      final repo = TodoRepository(db);
      final parent = await repo.create(title: 'Parent');
      await repo.create(title: 'Child', parentId: parent);

      await repo.delete(parent);

      expect(await repo.getTopLevel(), isEmpty);
      final remaining = await db.select(db.todos).get();
      expect(
        remaining,
        isEmpty,
        reason: 'orphaned subtasks must not survive their parent',
      );
    });

    test('dueWithin returns only incomplete todos inside the window', () async {
      final repo = TodoRepository(db);
      final now = DateTime(2026, 8, 25, 9);

      final soon = await repo.create(
        title: 'Soon',
        deadline: now.add(const Duration(hours: 1)),
      );
      await repo.create(
        title: 'Later',
        deadline: now.add(const Duration(days: 3)),
      );
      await repo.create(title: 'No deadline');
      final done = await repo.create(
        title: 'Done soon',
        deadline: now.add(const Duration(hours: 1)),
      );
      await repo.setCompleted(done, completed: true);

      final due = await repo.dueWithin(now, const Duration(hours: 4));
      expect(due.map((t) => t.id), [soon]);
    });

    test('setCompleted toggles both ways', () async {
      final repo = TodoRepository(db);
      final id = await repo.create(title: 'Task');

      await repo.setCompleted(id, completed: true);
      expect((await repo.findById(id))!.isCompleted, isTrue);

      await repo.setCompleted(id, completed: false);
      expect((await repo.findById(id))!.isCompleted, isFalse);
    });

    test('getRecentlyCompleted returns finished todos, most recent first', () async {
      final repo = TodoRepository(db);
      final first = await repo.create(title: 'First done');
      final second = await repo.create(title: 'Second done');
      await repo.create(title: 'Still open');

      await repo.setCompleted(
        first,
        completed: true,
        at: DateTime(2026, 1, 1),
      );
      await repo.setCompleted(
        second,
        completed: true,
        at: DateTime(2026, 1, 2),
      );

      final recent = await repo.getRecentlyCompleted();
      expect(recent.map((t) => t.title), ['Second done', 'First done']);
    });

    test('getRecentlyCompleted respects the limit', () async {
      final repo = TodoRepository(db);
      for (var i = 0; i < 8; i++) {
        final id = await repo.create(title: 'Task $i');
        await repo.setCompleted(
          id,
          completed: true,
          at: DateTime(2026, 1, 1 + i),
        );
      }

      expect(await repo.getRecentlyCompleted(limit: 5), hasLength(5));
      final recent = await repo.getRecentlyCompleted(limit: 5);
      expect(recent.first.title, 'Task 7');
    });

    test('withDeadlineNear finds todos inside the window, excludes those outside it', () async {
      final repo = TodoRepository(db);
      final center = DateTime(2026, 9, 15);

      await repo.create(title: 'Two days before', deadline: DateTime(2026, 9, 13));
      await repo.create(title: 'Two days after', deadline: DateTime(2026, 9, 17));
      await repo.create(title: 'Nine days before', deadline: DateTime(2026, 9, 6));
      await repo.create(title: 'No deadline at all');

      final nearby = await repo.withDeadlineNear(center);
      expect(
        nearby.map((t) => t.title),
        containsAll(['Two days before', 'Two days after']),
      );
      expect(nearby.map((t) => t.title), isNot(contains('Nine days before')));
      expect(nearby.map((t) => t.title), isNot(contains('No deadline at all')));
    });

    test('withDeadlineNear excludes the task itself and completed todos', () async {
      final repo = TodoRepository(db);
      final center = DateTime(2026, 9, 15);

      final self = await repo.create(title: 'Self', deadline: center);
      final done = await repo.create(
        title: 'Already finished',
        deadline: center,
      );
      await repo.setCompleted(done, completed: true);

      final nearby = await repo.withDeadlineNear(center, excludingId: self);
      expect(nearby, isEmpty);
    });

    test('withDeadlineNear respects the limit', () async {
      final repo = TodoRepository(db);
      final center = DateTime(2026, 9, 15);
      for (var i = 0; i < 8; i++) {
        await repo.create(
          title: 'Task $i',
          deadline: center.add(Duration(hours: i)),
        );
      }

      expect(await repo.withDeadlineNear(center, limit: 3), hasLength(3));
    });

    test('completedCountBetween counts only completions inside the window', () async {
      final repo = TodoRepository(db);
      final inside1 = await repo.create(title: 'Inside 1');
      final inside2 = await repo.create(title: 'Inside 2');
      final before = await repo.create(title: 'Before the window');
      final after = await repo.create(title: 'After the window');
      final stillOpen = await repo.create(title: 'Never completed');

      await repo.setCompleted(inside1, completed: true, at: DateTime(2026, 9, 3));
      await repo.setCompleted(inside2, completed: true, at: DateTime(2026, 9, 4));
      await repo.setCompleted(before, completed: true, at: DateTime(2026, 8, 30));
      await repo.setCompleted(after, completed: true, at: DateTime(2026, 9, 6));
      expect(stillOpen, isNotNull);

      final count = await repo.completedCountBetween(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 6),
      );
      expect(count, 2);
    });
  });

  group('NoteRepository', () {
    test('round-trips note text through the renamed body column', () async {
      final repo = NoteRepository(db, const PlaceholderEmbeddingService());
      await repo.create(text: 'Gym at 6pm\nBring shoes');

      final notes = await repo.getAll();
      expect(notes.single.text, 'Gym at 6pm\nBring shoes');
      // Domain model keeps the natural field name even though the column
      // is `body` to avoid colliding with Drift's Table.text().
      expect(notes.single.title, 'Gym at 6pm');
    });
  });

  group('HealthTargetRepository', () {
    test('activeTargets excludes paused ones', () async {
      final repo = HealthTargetRepository(db);
      await repo.create(metric: 'steps', threshold: '8000');
      final paused = await repo.create(metric: 'water', threshold: '2L');
      await repo.setActive(paused, false);

      final active = await repo.activeTargets();
      expect(active.map((t) => t.metric), ['steps']);
    });

    test('markMet records the time so metToday becomes true', () async {
      final repo = HealthTargetRepository(db);
      final id = await repo.create(metric: 'steps', threshold: '8000');
      await repo.markMet(id);

      final target = (await repo.activeTargets()).single;
      expect(target.id, id);
      expect(target.metToday, isTrue);
    });

    test('a target with no schedule round-trips both fields as null', () async {
      final repo = HealthTargetRepository(db);
      await repo.create(metric: 'steps', threshold: '8000');

      final target = (await repo.activeTargets()).single;
      expect(target.hasSchedule, isFalse);
      expect(target.reminderTime, isNull);
      expect(target.activeDaysMask, isNull);
    });

    test('a recurring schedule round-trips time and the weekday mask', () async {
      final repo = HealthTargetRepository(db);
      await repo.create(
        metric: 'water',
        threshold: '2L',
        reminderTime: '18:30',
        activeDaysMask: HealthTarget.maskFromWeekdays({
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        }),
      );

      final target = (await repo.activeTargets()).single;
      expect(target.hasSchedule, isTrue);
      expect(target.reminderTime, '18:30');
      expect(
        target.activeWeekdays,
        {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );
    });

    test('every day round-trips as all seven weekdays', () async {
      final repo = HealthTargetRepository(db);
      await repo.create(
        metric: 'sleep',
        threshold: '7h',
        reminderTime: '22:00',
        activeDaysMask: everyDayMask,
      );

      final target = (await repo.activeTargets()).single;
      expect(target.activeWeekdays, {1, 2, 3, 4, 5, 6, 7});
    });

    test('deleting a target removes its reminders and reports their ids', () async {
      final targets = HealthTargetRepository(db);
      final reminders = ReminderRepository(db);

      final targetId = await targets.create(
        metric: 'steps',
        threshold: '8000',
        reminderTime: '09:00',
        activeDaysMask: everyDayMask,
      );
      final reminderId = await reminders.create(
        title: 'steps',
        scheduledFor: DateTime(2030),
        tool: TaskTool.setReminder,
        healthTargetId: targetId,
      );

      final cancelled = await targets.delete(targetId);

      expect(cancelled, [reminderId]);
      expect(await reminders.forHealthTarget(targetId), isEmpty);
      expect(await targets.activeTargets(), isEmpty);
    });

    test('deleting a target with no reminders reports nothing to cancel', () async {
      final targets = HealthTargetRepository(db);
      final id = await targets.create(metric: 'steps', threshold: '8000');
      expect(await targets.delete(id), isEmpty);
    });
  });

  group('ReminderRepository', () {
    test('persists the tool by name and reads it back', () async {
      final repo = ReminderRepository(db);
      await repo.create(
        title: 'Standup',
        scheduledFor: DateTime(2030),
        tool: TaskTool.setAlarm,
      );

      final all = await repo.getPending(now: DateTime(2026));
      expect(all.single.tool, TaskTool.setAlarm);
    });

    test('getPending excludes cancelled, fired and past reminders', () async {
      final repo = ReminderRepository(db);
      final now = DateTime(2026, 8, 25, 9);

      final upcoming = await repo.create(
        title: 'Upcoming',
        scheduledFor: now.add(const Duration(hours: 1)),
        tool: TaskTool.setReminder,
      );
      final cancelled = await repo.create(
        title: 'Cancelled',
        scheduledFor: now.add(const Duration(hours: 1)),
        tool: TaskTool.setReminder,
      );
      await repo.cancel(cancelled);
      final fired = await repo.create(
        title: 'Fired',
        scheduledFor: now.add(const Duration(hours: 1)),
        tool: TaskTool.setReminder,
      );
      await repo.markFired(fired);
      await repo.create(
        title: 'Past',
        scheduledFor: now.subtract(const Duration(hours: 1)),
        tool: TaskTool.setReminder,
      );

      final pending = await repo.getPending(now: now);
      expect(pending.map((r) => r.id), [upcoming]);
    });

    test(
      'rejects TaskTool.none, which means no reminder should exist',
      () async {
        final repo = ReminderRepository(db);
        expect(
          () => repo.create(
            title: 'Nothing',
            scheduledFor: DateTime(2030),
            tool: TaskTool.none,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('links to a health target rather than a todo', () async {
      final repo = ReminderRepository(db);
      final id = await repo.create(
        title: 'Water',
        scheduledFor: DateTime(2030),
        tool: TaskTool.setReminder,
        healthTargetId: 7,
      );

      final saved = (await repo.forHealthTarget(7)).single;
      expect(saved.id, id);
      expect(saved.todoId, isNull);
      expect(saved.healthTargetId, 7);
    });

    test('rejects a reminder linked to both a todo and a health target', () {
      final repo = ReminderRepository(db);
      expect(
        () => repo.create(
          title: 'Ambiguous',
          scheduledFor: DateTime(2030),
          tool: TaskTool.setReminder,
          todoId: 1,
          healthTargetId: 2,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
