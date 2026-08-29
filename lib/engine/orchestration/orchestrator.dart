import '../../core/models/agent_state.dart';
import '../../core/models/overload_event.dart';

/// Intervention state machine and cooldown gate:
/// `normal -> overloadDetected -> intervening -> cooldown -> normal`.
///
/// Deterministic, code-governed control flow — no model decides state
/// transitions. See Plans/IMPLEMENTATION.md §0.4 and §4.2.
class Orchestrator {
  Orchestrator({
    Duration cooldown = const Duration(minutes: 15),
    DateTime Function() now = DateTime.now,
  }) : _cooldown = cooldown,
       _now = now;

  final Duration _cooldown;
  final DateTime Function() _now;

  AgentState _state = AgentState.normal;
  AgentState get state => _state;

  DateTime? _lastInterventionAt;

  /// Call when the classifier (`lib/engine/detection`) produces [event].
  ///
  /// Returns `true` if the caller should trigger `SlmExplainer` and
  /// `FocusOverlay` for this event; `false` if an intervention is already
  /// in flight or the cooldown window from the last one hasn't elapsed
  /// (which also moves the state to [AgentState.cooldown]).
  bool onOverloadEvent(OverloadEvent event) {
    if (_state != AgentState.normal) return false;

    final now = _now();
    final lastAt = _lastInterventionAt;
    if (lastAt != null && now.difference(lastAt) < _cooldown) {
      _state = AgentState.cooldown;
      return false;
    }

    _state = AgentState.overloadDetected;
    _lastInterventionAt = now;
    return true;
  }

  /// Call once the intervention (overlay/explanation) is actually shown.
  void onInterventionShown() {
    _state = AgentState.intervening;
  }

  /// Call once the cooldown window has elapsed, returning to normal so the
  /// next overload event can trigger an intervention.
  void onCooldownElapsed() {
    _state = AgentState.normal;
  }
}
