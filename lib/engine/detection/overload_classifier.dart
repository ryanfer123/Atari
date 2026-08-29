import 'dart:math' as math;

import '../../core/models/overload_event.dart';

/// Tier 1, rule-based overload detection: a weighted sum of per-signal
/// z-scores against a fixed threshold.
///
/// Chosen over a learned classifier for this project's data volume — see
/// Plans/IMPLEMENTATION.md §2 ("Classifier" row) and RESEARCH.md
/// "Decision justification". Code skeleton per §4.2.
class OverloadClassifier {
  OverloadClassifier({
    required this.weights,
    required this.threshold,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  /// Signal name to its weight in the severity sum. A signal with no entry
  /// contributes zero.
  final Map<String, double> weights;

  /// `severity` must exceed this for [classify] to return an event.
  final double threshold;

  final DateTime Function() _now;

  /// Classifies one snapshot of per-signal z-scores ([zScores]) and returns
  /// the resulting [OverloadEvent], or `null` if severity did not cross
  /// [threshold].
  ///
  /// Only the positive part of each z-score counts toward severity — a
  /// signal running *below* its baseline should never help trigger an
  /// intervention.
  OverloadEvent? classify(Map<String, double> zScores) {
    var severity = 0.0;
    for (final entry in zScores.entries) {
      final weight = weights[entry.key] ?? 0.0;
      severity += weight * math.max(entry.value, 0.0);
    }
    if (severity <= threshold) return null;
    return OverloadEvent(
      timestamp: _now(),
      signalScores: Map.unmodifiable(zScores),
      severity: severity,
    );
  }
}
