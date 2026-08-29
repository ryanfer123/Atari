import 'package:flutter/foundation.dart';

@immutable
class BaselineBucket {
  final String signal;
  final int hourOfDay;
  final int dayOfWeek;
  final int sampleCount;
  final double mean;
  final double standardDeviation;

  const BaselineBucket({
    required this.signal,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.sampleCount,
    required this.mean,
    required this.standardDeviation,
  });
}
