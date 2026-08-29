import 'package:flutter/foundation.dart';

@immutable
class OverloadEvent {
  final DateTime timestamp;
  final Map<String, double> signalScores;
  final double severity;
  final String topSignal;
  final String baselineContext;

  const OverloadEvent({
    required this.timestamp,
    required this.signalScores,
    required this.severity,
    required this.topSignal,
    required this.baselineContext,
  });
}
