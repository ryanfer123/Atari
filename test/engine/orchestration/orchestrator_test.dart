import 'package:atari/core/models/agent_state.dart';
import 'package:atari/core/models/overload_event.dart';
import 'package:atari/engine/orchestration/orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mutable fake clock so tests can control elapsed time deterministically
/// instead of racing the real system clock against a cooldown [Duration].
class _FakeClock {
  _FakeClock(this.current);
  DateTime current;
  DateTime now() => current;
}

OverloadEvent _event(DateTime at) => OverloadEvent(
  timestamp: at,
  signalScores: const {'unlocks': 3.0},
  severity: 3,
);

void main() {
  group('Orchestrator', () {
    test('starts in the normal state', () {
      final orchestrator = Orchestrator();
      expect(orchestrator.state, AgentState.normal);
    });

    test('the first overload event triggers an intervention', () {
      final clock = _FakeClock(DateTime(2026, 8, 25, 9));
      final orchestrator = Orchestrator(now: clock.now);

      final triggered = orchestrator.onOverloadEvent(_event(clock.current));

      expect(triggered, isTrue);
      expect(orchestrator.state, AgentState.overloadDetected);
    });

    test('a second overload event while already intervening is ignored', () {
      final clock = _FakeClock(DateTime(2026, 8, 25, 9));
      final orchestrator = Orchestrator(now: clock.now);

      orchestrator.onOverloadEvent(_event(clock.current));
      orchestrator.onInterventionShown();
      expect(orchestrator.state, AgentState.intervening);

      final triggeredAgain = orchestrator.onOverloadEvent(
        _event(clock.current),
      );

      expect(triggeredAgain, isFalse);
      expect(orchestrator.state, AgentState.intervening);
    });

    test('an overload event within the cooldown window after returning to normal is suppressed', () {
      final clock = _FakeClock(DateTime(2026, 8, 25, 9));
      final orchestrator = Orchestrator(
        cooldown: const Duration(minutes: 15),
        now: clock.now,
      );

      orchestrator.onOverloadEvent(_event(clock.current));
      orchestrator.onInterventionShown();
      orchestrator.onCooldownElapsed(); // back to normal, but only 0 minutes have passed
      expect(orchestrator.state, AgentState.normal);

      clock.current = clock.current.add(const Duration(minutes: 5));
      final triggered = orchestrator.onOverloadEvent(_event(clock.current));

      expect(triggered, isFalse);
      expect(orchestrator.state, AgentState.cooldown);
    });

    test(
      'an overload event after the cooldown window has elapsed triggers again',
      () {
        final clock = _FakeClock(DateTime(2026, 8, 25, 9));
        final orchestrator = Orchestrator(
          cooldown: const Duration(minutes: 15),
          now: clock.now,
        );

        orchestrator.onOverloadEvent(_event(clock.current));
        orchestrator.onInterventionShown();
        orchestrator.onCooldownElapsed();

        clock.current = clock.current.add(const Duration(minutes: 16));
        final triggered = orchestrator.onOverloadEvent(_event(clock.current));

        expect(triggered, isTrue);
        expect(orchestrator.state, AgentState.overloadDetected);
      },
    );

    test('a stuck cooldown state ignores further overload events until onCooldownElapsed is called', () {
      final clock = _FakeClock(DateTime(2026, 8, 25, 9));
      final orchestrator = Orchestrator(
        cooldown: const Duration(minutes: 15),
        now: clock.now,
      );

      orchestrator.onOverloadEvent(_event(clock.current));
      orchestrator.onInterventionShown();
      orchestrator.onCooldownElapsed();
      clock.current = clock.current.add(const Duration(minutes: 1));
      orchestrator.onOverloadEvent(
        _event(clock.current),
      ); // enters AgentState.cooldown
      expect(orchestrator.state, AgentState.cooldown);

      // Even though plenty of wall-clock time passes, the state machine
      // only leaves cooldown via an explicit onCooldownElapsed() call.
      clock.current = clock.current.add(const Duration(hours: 1));
      final triggered = orchestrator.onOverloadEvent(_event(clock.current));
      expect(triggered, isFalse);
      expect(orchestrator.state, AgentState.cooldown);

      orchestrator.onCooldownElapsed();
      final triggeredAfterElapsed = orchestrator.onOverloadEvent(
        _event(clock.current),
      );
      expect(triggeredAfterElapsed, isTrue);
    });
  });
}
