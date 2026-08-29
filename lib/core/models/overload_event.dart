/// A single detected overload episode, produced by `OverloadClassifier`
/// (`lib/engine/detection`) from a set of per-signal z-scores.
///
/// See Plans/IMPLEMENTATION.md §4.2 / §4.3 and Plans/frontend_prd.md §4.1.
class OverloadEvent {
  const OverloadEvent({
    required this.timestamp,
    required this.signalScores,
    required this.severity,
    String? topSignal,
    String? baselineContext,
  })  : _topSignal = topSignal,
        _baselineContext = baselineContext;

  /// When the event was classified.
  final DateTime timestamp;

  /// Signal name (e.g. `unlocks`, `app_switches`, `notif_latency_ms`) to its
  /// z-score at classification time.
  final Map<String, double> signalScores;

  /// Weighted sum of positive z-scores that crossed the classifier threshold.
  final double severity;

  final String? _topSignal;
  final String? _baselineContext;

  /// Highest contributing signal name (e.g. `app_switches`, `unlocks`, `notif_latency_ms`).
  String get topSignal {
    if (_topSignal != null && _topSignal!.isNotEmpty) return _topSignal!;
    if (signalScores.isEmpty) return 'app_switches';
    var maxKey = 'app_switches';
    var maxVal = double.negativeInfinity;
    for (final entry in signalScores.entries) {
      if (entry.value > maxVal) {
        maxVal = entry.value;
        maxKey = entry.key;
      }
    }
    return maxKey;
  }

  /// Contextual baseline time description (e.g. `Tuesday afternoon`).
  String get baselineContext => _baselineContext ?? 'afternoon';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverloadEvent &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          severity == other.severity &&
          topSignal == other.topSignal &&
          baselineContext == other.baselineContext &&
          _mapEquals(signalScores, other.signalScores);

  @override
  int get hashCode => Object.hash(
    timestamp,
    severity,
    topSignal,
    baselineContext,
    Object.hashAllUnordered(
      signalScores.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'OverloadEvent(timestamp: $timestamp, severity: $severity, '
      'topSignal: $topSignal, baselineContext: $baselineContext, '
      'signalScores: $signalScores)';
}

bool _mapEquals(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
