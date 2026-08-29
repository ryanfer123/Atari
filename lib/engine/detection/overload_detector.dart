import 'dart:math';

import '../../core/models/models.dart';
import '../baseline/baseline_store.dart';

/// Signal weights used by the composite fragmentation formula.
///
/// App-switching is weighted highest because it is the most reliable
/// real-time proxy for attentional fragmentation on mobile; unlocks
/// and notification latency contribute but are noisier.
const _kWeights = <String, double>{
  'app_switches': 0.50,
  'unlocks': 0.30,
  'notif_latency_ms': 0.20,
};

/// Composite z-score threshold above which the detector transitions
/// from [AgentState.normal] to [AgentState.overloadDetected].
///
/// This is a hand-tuned starting point; the contextual bandit in
/// `lib/engine/feedback/` will adjust it over time.
const double kOverloadThreshold = 1.5;

/// Minimum seconds between consecutive overload detections.
const Duration kCooldownDuration = Duration(minutes: 15);

/// Evaluates multi-signal z-scores from [BaselineStore] and manages
/// the four-state agent lifecycle:
///
/// ```
/// Normal → OverloadDetected → Intervening → Cooldown → Normal
/// ```
///
/// See Plans/IMPLEMENTATION.md §4.2.
class OverloadDetector {
  OverloadDetector(this._baseline);

  final BaselineStore _baseline;

  AgentState _state = AgentState.normal;
  DateTime? _lastTransition;
  OverloadEvent? _currentEvent;

  AgentState get state => _state;
  OverloadEvent? get currentEvent => _currentEvent;

  /// Evaluate a fresh [snapshot] against the personal baseline
  /// and possibly transition to [AgentState.overloadDetected].
  ///
  /// Returns the new [AgentState] after evaluation.
  Future<AgentState> evaluate(SignalSnapshot snapshot) async {
    if (_state == AgentState.cooldown) {
      if (_lastTransition != null &&
          DateTime.now().difference(_lastTransition!) >= kCooldownDuration) {
        _transition(AgentState.normal);
      } else {
        return _state;
      }
    }

    if (_state != AgentState.normal) return _state;

    final now = snapshot.windowEnd;
    final scores = <String, double>{};

    scores['app_switches'] =
        await _baseline.zScoreFor('app_switches', now, snapshot.appSwitchCount.toDouble());
    scores['unlocks'] =
        await _baseline.zScoreFor('unlocks', now, snapshot.unlockCount.toDouble());
    scores['notif_latency_ms'] =
        await _baseline.zScoreFor('notif_latency_ms', now, snapshot.avgNotifLatencyMs);

    final severity = _compositeSeverity(scores);

    if (severity >= kOverloadThreshold) {
      final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final timeBuckets = ['night', 'night', 'night', 'night', 'night', 'morning',
        'morning', 'morning', 'morning', 'morning', 'morning', 'morning',
        'afternoon', 'afternoon', 'afternoon', 'afternoon', 'afternoon', 'afternoon',
        'evening', 'evening', 'evening', 'evening', 'night', 'night'];

      _currentEvent = OverloadEvent(
        timestamp: now,
        signalScores: scores,
        severity: severity,
        topSignal: _topSignalName(scores),
        baselineContext: '${dayNames[now.weekday]} ${timeBuckets[now.hour]}',
      );
      _transition(AgentState.overloadDetected);
    }

    return _state;
  }

  /// Record raw signal values into the baseline for learning.
  Future<void> recordObservation(SignalSnapshot snapshot) async {
    final now = snapshot.windowEnd;
    await _baseline.observe('app_switches', now, snapshot.appSwitchCount.toDouble());
    await _baseline.observe('unlocks', now, snapshot.unlockCount.toDouble());
    await _baseline.observe('notif_latency_ms', now, snapshot.avgNotifLatencyMs);
  }

  /// Called by the orchestrator when the intervention is accepted.
  void beginIntervention() {
    if (_state == AgentState.overloadDetected) {
      _transition(AgentState.intervening);
    }
  }

  /// Called by the orchestrator when the intervention session ends.
  void endIntervention() {
    if (_state == AgentState.intervening) {
      _transition(AgentState.cooldown);
    }
  }

  /// Force-reset to normal (e.g. from settings debug panel).
  void reset() {
    _state = AgentState.normal;
    _currentEvent = null;
    _lastTransition = null;
  }

  /// Force an overload state for manual evaluation/testing.
  void forceOverload(SignalSnapshot snapshot) {
    _transition(AgentState.overloadDetected);
    _currentEvent = OverloadEvent(
      timestamp: DateTime.now(),
      signalScores: const {'app_switches': 9.9},
      severity: 9.9,
      topSignal: 'app_switches',
    );
  }

  double _compositeSeverity(Map<String, double> scores) {
    var severity = 0.0;
    for (final entry in scores.entries) {
      final w = _kWeights[entry.key] ?? 0.0;
      severity += w * max(0.0, entry.value);
    }
    return severity;
  }

  String _topSignalName(Map<String, double> scores) {
    var maxKey = 'app_switches';
    var maxVal = double.negativeInfinity;
    for (final entry in scores.entries) {
      if (entry.value > maxVal) {
        maxVal = entry.value;
        maxKey = entry.key;
      }
    }
    return maxKey;
  }

  void _transition(AgentState next) {
    _state = next;
    _lastTransition = DateTime.now();
  }
}
