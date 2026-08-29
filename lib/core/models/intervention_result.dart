import 'package:flutter/foundation.dart';

@immutable
class InterventionResult {
  final String interventionType;
  final double preSignalLevel;
  final double postSignalLevel;
  final double effectSize;
  final DateTime timestamp;

  const InterventionResult({
    required this.interventionType,
    required this.preSignalLevel,
    required this.postSignalLevel,
    required this.effectSize,
    required this.timestamp,
  });
}
