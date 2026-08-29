import 'package:atari/core/models/context_bullet.dart';
import 'package:atari/engine/orchestration/masked_source_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaskedSourceSelector', () {
    test('passes the validated subset and the model reasoning through when within the cap', () async {
      final selector = MaskedSourceSelector(
        slm: (triggerSignal, topSignal, allowed) async =>
            const RawSourceSelectionResponse(
              sourceNames: ['todos', 'notes'],
              reasoning: 'user mentioned a deadline recently',
            ),
      );

      final result = await selector.select(
        triggerSignal: 'app_switches',
        topSignal: 'app_switches',
      );

      expect(result.sources, [
        GoalContextSource.todos,
        GoalContextSource.notes,
      ]);
      expect(result.reasoning, 'user mentioned a deadline recently');
    });

    test(
      'drops a hallucinated/invalid source name rather than throwing',
      () async {
        final selector = MaskedSourceSelector(
          slm: (triggerSignal, topSignal, allowed) async =>
              const RawSourceSelectionResponse(
                sourceNames: ['notes', 'weather'],
                reasoning: 'checking notes',
              ),
        );

        final result = await selector.select(
          triggerSignal: 'unlocks',
          topSignal: 'unlocks',
        );

        expect(result.sources, [GoalContextSource.notes]);
        expect(result.reasoning, 'checking notes');
      },
    );

    test('deduplicates a repeated valid source name', () async {
      final selector = MaskedSourceSelector(
        slm: (triggerSignal, topSignal, allowed) async =>
            const RawSourceSelectionResponse(
              sourceNames: ['notes', 'notes'],
              reasoning: 'checking notes',
            ),
      );

      final result = await selector.select(
        triggerSignal: 'unlocks',
        topSignal: 'unlocks',
      );

      expect(result.sources, [GoalContextSource.notes]);
    });

    test('falls back to every source when validation leaves nothing (empty or all-invalid)', () async {
      final selector = MaskedSourceSelector(
        slm: (triggerSignal, topSignal, allowed) async =>
            const RawSourceSelectionResponse(
              sourceNames: ['weather', 'sports'],
              reasoning: 'irrelevant',
            ),
      );

      final result = await selector.select(
        triggerSignal: 'unlocks',
        topSignal: 'unlocks',
      );

      expect(result.sources, GoalContextSource.values);
      expect(result.reasoning, MaskedSourceSelector.fallbackReasoning);
    });

    test(
      'falls back to every source when the model exceeds the call cap',
      () async {
        final selector = MaskedSourceSelector(
          maxCalls: 3,
          slm: (triggerSignal, topSignal, allowed) async =>
              const RawSourceSelectionResponse(
                sourceNames: ['notes', 'todos', 'healthTargets', 'calendar'],
                reasoning: 'querying everything just in case',
              ),
        );

        final result = await selector.select(
          triggerSignal: 'unlocks',
          topSignal: 'unlocks',
        );

        expect(result.sources, GoalContextSource.values);
        expect(result.reasoning, MaskedSourceSelector.fallbackReasoning);
      },
    );

    test('exactly maxCalls valid sources is accepted, not treated as exceeding the cap', () async {
      final selector = MaskedSourceSelector(
        maxCalls: 3,
        slm: (triggerSignal, topSignal, allowed) async =>
            const RawSourceSelectionResponse(
              sourceNames: ['notes', 'todos', 'healthTargets'],
              reasoning: 'three sources',
            ),
      );

      final result = await selector.select(
        triggerSignal: 'unlocks',
        topSignal: 'unlocks',
      );

      expect(result.sources, [
        GoalContextSource.notes,
        GoalContextSource.todos,
        GoalContextSource.healthTargets,
      ]);
      expect(result.reasoning, 'three sources');
    });

    test('passes triggerSignal, topSignal, and the full allowed enum through to the model', () async {
      String? capturedTrigger;
      String? capturedTop;
      List<GoalContextSource>? capturedAllowed;

      final selector = MaskedSourceSelector(
        slm: (triggerSignal, topSignal, allowed) async {
          capturedTrigger = triggerSignal;
          capturedTop = topSignal;
          capturedAllowed = allowed;
          return const RawSourceSelectionResponse(
            sourceNames: ['notes'],
            reasoning: 'ok',
          );
        },
      );

      await selector.select(
        triggerSignal: 'notif_latency_ms',
        topSignal: 'app_switches',
      );

      expect(capturedTrigger, 'notif_latency_ms');
      expect(capturedTop, 'app_switches');
      expect(capturedAllowed, GoalContextSource.values);
    });
  });
}
