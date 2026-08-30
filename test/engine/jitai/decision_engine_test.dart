import 'package:atari/core/models/agent_state.dart';
import 'package:atari/core/models/todo.dart';
import 'package:atari/core/services/placeholders/placeholder_slm_explainer.dart';
import 'package:atari/engine/feedback/intervention_bandit.dart';
import 'package:atari/engine/jitai/decision_engine.dart';
import 'package:atari/engine/jitai/decision_point.dart';
import 'package:atari/engine/jitai/intervention_option.dart';
import 'package:atari/engine/jitai/tailoring_variables.dart';
import 'package:atari/engine/orchestration/orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mutable clock so cooldown behaviour is deterministic.
class _Clock {
  _Clock(this.current);
  DateTime current;
  DateTime now() => current;
}

void main() {
  late _Clock clock;
  late Orchestrator orchestrator;
  late DecisionEngine engine;

  DecisionEngine build({
    Duration cooldown = const Duration(minutes: 15),
    List<String>? arms,
  }) {
    orchestrator = Orchestrator(cooldown: cooldown, now: clock.now);
    return DecisionEngine(
      orchestrator: orchestrator,
      bandit: InterventionBandit(
        arms: arms ?? [banditArmFor(InterventionOption.showOverlay)],
      ),
      explainer: const PlaceholderSlmExplainer(),
      now: clock.now,
    );
  }

  setUp(() {
    clock = _Clock(DateTime(2026, 8, 25, 14));
    engine = build();
  });

  group('capture completion (decision point A)', () {
    test('proposes a reminder for the captured task', () async {
      final todo = Todo(
        id: 7,
        title: 'Submit assignment',
        createdAt: clock.current,
        deadline: clock.current.add(const Duration(hours: 3)),
      );

      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.captureCompleted,
          now: clock.current,
          relatedTodo: todo,
        ),
      );

      expect(spec.option, InterventionOption.setReminder);
      expect(spec.relatedTodoId, 7);
      expect(spec.suggestedTitle, 'Submit assignment');
      expect(spec.isDeferred, isFalse);
    });

    test('is not gated by the interruption cooldown', () async {
      // Burn the cooldown with an overload event first.
      await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 5,
        ),
      );
      engine.onInterventionShown();
      engine.onCooldownElapsed();

      final todo = Todo(id: 1, title: 'Task', createdAt: clock.current);
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.captureCompleted,
          now: clock.current,
          relatedTodo: todo,
        ),
      );

      // The user just asked for this, so it continues their action
      // rather than interrupting them.
      expect(spec.isDeferred, isFalse);
    });
  });

  group('overload signal (decision point C)', () {
    test('defers when no event crossed the threshold', () async {
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
        ),
      );

      expect(spec.isDeferred, isTrue);
      expect(spec.deferReason, contains('under threshold'));
    });

    test('proposes an overlay with an explanation on a real event', () async {
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 4.2,
          signalZScores: const {'app_switches': 3.1},
          topSignal: 'app_switches',
          timeBucket: 'Tuesday afternoon',
        ),
      );

      expect(spec.option, InterventionOption.showOverlay);
      expect(spec.explanation, contains('switching apps'));
      expect(orchestrator.state, AgentState.overloadDetected);
    });

    test('defers a second event inside the cooldown window', () async {
      await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 4.0,
        ),
      );
      engine.onInterventionShown();
      engine.onCooldownElapsed();

      clock.current = clock.current.add(const Duration(minutes: 5));
      final second = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 9.0,
        ),
      );

      // The deterministic guard runs before any model is consulted.
      expect(second.isDeferred, isTrue);
      expect(second.deferReason, contains('cooldown'));
    });

    test('allows a new intervention once the cooldown has elapsed', () async {
      await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 4.0,
        ),
      );
      engine.onInterventionShown();
      engine.onCooldownElapsed();

      clock.current = clock.current.add(const Duration(minutes: 16));
      final second = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 4.0,
        ),
      );

      expect(second.isDeferred, isFalse);
    });
  });

  group('manual check (decision point D)', () {
    test('always answers, so it works as the demo fallback trigger', () async {
      // Put the orchestrator into a state that would veto an unsolicited
      // interruption.
      await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.overloadSignal,
          now: clock.current,
          severity: 4.0,
        ),
      );
      engine.onInterventionShown();

      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.manualCheck,
          now: clock.current,
          topSignal: 'unlocks',
          timeBucket: 'Tuesday afternoon',
        ),
      );

      expect(spec.option, InterventionOption.showOverlay);
      expect(spec.explanation, isNotNull);
    });

    test('passes the recent-activity comparison through to the explanation', () async {
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.manualCheck,
          now: clock.current,
          topSignal: 'unlocks',
          signalZScores: const {'unlocks': 1.0},
          recentActivityNote:
              '50.0 unlocks a day over the last 5 days, versus 30.0 a day the 5 days before that',
        ),
      );

      expect(spec.explanation, contains('50.0 unlocks a day'));
    });
  });

  group('outcome logging closes the loop', () {
    test('records the effect size against the arm that was chosen', () async {
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.manualCheck,
          now: clock.current,
          topSignal: 'unlocks',
        ),
      );

      engine.recordOutcome(spec, 0.12);

      // The bandit is what makes interventions falsifiable rather than
      // just a rule-based nag.
      expect(spec.banditArm, banditArmFor(InterventionOption.showOverlay));
    });

    test('a negative effect size is legitimate signal, not an error', () async {
      final spec = await engine.decide(
        TailoringVariables(
          decisionPoint: DecisionPoint.manualCheck,
          now: clock.current,
          topSignal: 'unlocks',
        ),
      );

      expect(() => engine.recordOutcome(spec, -0.2), returnsNormally);
    });
  });

  group('intervention options', () {
    test(
      'every real-world action requires confirmation; only defer does not',
      () {
        for (final option in InterventionOption.values) {
          expect(
            requiresConfirmation(option),
            option != InterventionOption.defer,
            reason: '$option must be gated unless it does nothing',
          );
        }
      },
    );
  });
}
