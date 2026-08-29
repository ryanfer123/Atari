/// A single detected overload episode, produced by `OverloadClassifier`
/// (`lib/engine/detection`) from a set of per-signal z-scores.
///
/// See Plans/IMPLEMENTATION.md §4.2.
class OverloadEvent {
  const OverloadEvent({
    required this.timestamp,
    required this.signalScores,
    required this.severity,
  });

  /// When the event was classified.
  final DateTime timestamp;

  /// Signal name (e.g. `unlocks`, `app_switches`, `notif_latency_ms`) to its
  /// z-score at classification time.
  final Map<String, double> signalScores;

  /// Weighted sum of positive z-scores that crossed the classifier threshold.
  final double severity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverloadEvent &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          severity == other.severity &&
          _mapEquals(signalScores, other.signalScores);

  @override
  int get hashCode => Object.hash(
    timestamp,
    severity,
    Object.hashAllUnordered(
      signalScores.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'OverloadEvent(timestamp: $timestamp, severity: $severity, '
      'signalScores: $signalScores)';
}

bool _mapEquals(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
