import 'intervention_bandit.dart';

/// ≥5% reduction counts as "worked" — real JITAI effect sizes cluster at
/// 7-17%, not dramatic swings. See RESEARCH.md "Decision justification"
/// (Time2Stop, InteractOut, MindShift) and Plans/IMPLEMENTATION.md §4.4.
const double interventionSuccessThreshold = 0.05;

/// Measures a signal's aggregate raw value over `[start, end)`.
///
/// Implemented by backend-native's real collectors in the shipped app;
/// tests and early integration supply a fake returning canned values — see
/// Plans/IMPLEMENTATION.md §0.2 on frontend/engine building against fakes.
typedef SignalWindowMeasurer = Future<double> Function(
  String signal,
  DateTime start,
  DateTime end,
);

/// Outcome of one [FeedbackLoop.evaluate] call.
class FeedbackResult {
  const FeedbackResult({
    required this.arm,
    required this.signal,
    required this.effectSize,
    required this.worked,
  });

  final String arm;
  final String signal;

  /// Fractional signal drop: `(preValue - postValue) / preValue`. Positive
  /// means the signal went down (good); this is a legitimate outcome even
  /// when negative or zero.
  final double effectSize;

  /// `effectSize >= interventionSuccessThreshold`.
  final bool worked;
}

/// On cooldown end, re-measures the triggering signal over the post-window,
/// computes the pre/post effect size, and updates [InterventionBandit]'s
/// weights over intervention variants.
///
/// See Plans/IMPLEMENTATION.md §4.4.
class FeedbackLoop {
  FeedbackLoop({
    required InterventionBandit bandit,
    required SignalWindowMeasurer measureSignalWindow,
  }) : _bandit = bandit,
       _measureSignalWindow = measureSignalWindow;

  final InterventionBandit _bandit;
  final SignalWindowMeasurer _measureSignalWindow;

  /// Picks which intervention variant to show for a newly detected
  /// overload event.
  String chooseIntervention() => _bandit.choose();

  /// Measures [signal]'s aggregate value over `[start, end)`. Callers use
  /// this both to capture the pre-intervention value (before showing the
  /// intervention) and, via [evaluate], the post-intervention value — the
  /// same measurement method on both ends keeps the comparison meaningful.
  Future<double> measureSignalWindow(
    String signal,
    DateTime start,
    DateTime end,
  ) {
    return _measureSignalWindow(signal, start, end);
  }

  /// Re-measures [signal] over `[postWindowStart, postWindowEnd)`, compares
  /// it to [preValue], and records the resulting effect size against [arm]
  /// in the bandit.
  Future<FeedbackResult> evaluate({
    required String arm,
    required String signal,
    required double preValue,
    required DateTime postWindowStart,
    required DateTime postWindowEnd,
  }) async {
    final postValue = await _measureSignalWindow(
      signal,
      postWindowStart,
      postWindowEnd,
    );
    final effectSize = preValue == 0 ? 0.0 : (preValue - postValue) / preValue;
    _bandit.record(arm, effectSize);
    return FeedbackResult(
      arm: arm,
      signal: signal,
      effectSize: effectSize,
      worked: effectSize >= interventionSuccessThreshold,
    );
  }
}
