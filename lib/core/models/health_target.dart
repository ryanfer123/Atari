import 'package:flutter/foundation.dart';

@immutable
class HealthTarget {
  final String id;
  final String metric;
  final double threshold;
  final double? current;
  final bool isMet;

  const HealthTarget({
    required this.id,
    required this.metric,
    required this.threshold,
    this.current,
    required this.isMet,
  });
}
