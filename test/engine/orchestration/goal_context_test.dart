import 'package:atari/core/models/context_bullet.dart';
import 'package:atari/engine/orchestration/goal_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalContext', () {
    final now = DateTime(2026, 8, 25, 9);

    GoalContext buildContext({
      CalendarEventsWithinLookup? calendarLookup,
      CaptureHistoryLookup? captureLookup,
    }) {
      return GoalContext(
        notesTopK: (query, k) async => [NoteMatch(text: 'note about $query')],
        todosDueWithin: (now, window) async => [
          TodoSummary(title: 'Submit report', deadline: now.add(window)),
        ],
        activeHealthTargets: () async => const [
          HealthTargetSummary(metric: 'steps', threshold: '8000'),
        ],
        calendarEventsWithin: calendarLookup,
        captureHistoryWithin: captureLookup,
      );
    }

    test('queries only the requested sources', () async {
      var todosCalled = false;
      var healthCalled = false;
      final context = GoalContext(
        notesTopK: (query, k) async => [NoteMatch(text: 'note about $query')],
        todosDueWithin: (now, window) async {
          todosCalled = true;
          return const [];
        },
        activeHealthTargets: () async {
          healthCalled = true;
          return const [];
        },
      );

      final bullets = await context.retrieve(
        triggerSignal: 'app_switches',
        now: now,
        sources: const [GoalContextSource.notes],
      );

      expect(bullets, [
        const ContextBullet(source: 'note', text: 'note about app_switches'),
      ]);
      expect(todosCalled, isFalse);
      expect(healthCalled, isFalse);
    });

    test(
      'returns no bullets and calls nothing when sources is empty',
      () async {
        var anyCalled = false;
        final context = GoalContext(
          notesTopK: (query, k) async {
            anyCalled = true;
            return const [];
          },
          todosDueWithin: (now, window) async {
            anyCalled = true;
            return const [];
          },
          activeHealthTargets: () async {
            anyCalled = true;
            return const [];
          },
        );

        final bullets = await context.retrieve(
          triggerSignal: 'unlocks',
          now: now,
          sources: const [],
        );

        expect(bullets, isEmpty);
        expect(anyCalled, isFalse);
      },
    );

    test('formats a todo bullet as "title (due deadline)"', () async {
      final deadline = DateTime(2026, 8, 25, 18);
      final context = GoalContext(
        notesTopK: (query, k) async => const [],
        todosDueWithin: (now, window) async => [
          TodoSummary(title: 'Submit report', deadline: deadline),
        ],
        activeHealthTargets: () async => const [],
      );

      final bullets = await context.retrieve(
        triggerSignal: 'unlocks',
        now: now,
        sources: const [GoalContextSource.todos],
      );

      expect(bullets, [
        ContextBullet(source: 'todo', text: 'Submit report (due $deadline)'),
      ]);
    });

    test(
      'formats a health target bullet as "metric target: threshold"',
      () async {
        final context = GoalContext(
          notesTopK: (query, k) async => const [],
          todosDueWithin: (now, window) async => const [],
          activeHealthTargets: () async => const [
            HealthTargetSummary(metric: 'steps', threshold: '8000'),
          ],
        );

        final bullets = await context.retrieve(
          triggerSignal: 'unlocks',
          now: now,
          sources: const [GoalContextSource.healthTargets],
        );

        expect(bullets, const [
          ContextBullet(source: 'health', text: 'steps target: 8000'),
        ]);
      },
    );

    test('formats a calendar bullet as "title at startTime" when the user has opted in', () async {
      final startTime = DateTime(2026, 8, 25, 10);
      final context = GoalContext(
        notesTopK: (query, k) async => const [],
        todosDueWithin: (now, window) async => const [],
        activeHealthTargets: () async => const [],
        calendarEventsWithin: (now, window) async => [
          CalendarEventSummary(title: 'Standup', startTime: startTime),
        ],
      );

      final bullets = await context.retrieve(
        triggerSignal: 'unlocks',
        now: now,
        sources: const [GoalContextSource.calendar],
      );

      expect(bullets, [
        ContextBullet(source: 'calendar', text: 'Standup at $startTime'),
      ]);
    });

    test(
      'skips calendar silently when requested but the user has not opted in',
      () async {
        final context = GoalContext(
          notesTopK: (query, k) async => const [],
          todosDueWithin: (now, window) async => const [],
          activeHealthTargets: () async => const [],
          // calendarEventsWithin intentionally omitted (null) — no opt-in.
        );

        final bullets = await context.retrieve(
          triggerSignal: 'unlocks',
          now: now,
          sources: const [GoalContextSource.calendar],
        );

        expect(bullets, isEmpty);
      },
    );

    test(
      'captures capture-history bullets as plain summaries when wired up',
      () async {
        final context = GoalContext(
          notesTopK: (query, k) async => const [],
          todosDueWithin: (now, window) async => const [],
          activeHealthTargets: () async => const [],
          captureHistoryWithin: (now, window) async => const [
            CaptureHistoryEntry(summary: 'Timetable, room 204'),
          ],
        );

        final bullets = await context.retrieve(
          triggerSignal: 'unlocks',
          now: now,
          sources: const [GoalContextSource.captureHistory],
        );

        expect(bullets, const [
          ContextBullet(source: 'capture', text: 'Timetable, room 204'),
        ]);
      },
    );

    test('concatenates bullets from multiple requested sources', () async {
      final context = buildContext(
        calendarLookup: (now, window) async => [
          CalendarEventSummary(title: 'Standup', startTime: now),
        ],
      );

      final bullets = await context.retrieve(
        triggerSignal: 'app_switches',
        now: now,
        sources: const [
          GoalContextSource.notes,
          GoalContextSource.todos,
          GoalContextSource.healthTargets,
          GoalContextSource.calendar,
        ],
      );

      expect(bullets.map((b) => b.source).toList(), [
        'note',
        'todo',
        'health',
        'calendar',
      ]);
    });
  });
}
