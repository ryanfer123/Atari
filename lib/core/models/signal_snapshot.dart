import 'package:flutter/foundation.dart';

@immutable
class SignalSnapshot {
  final int unlockCount;
  final int appSwitchCount;
  final double avgNotifLatencyMs;
  final Map<String, double> zScores;
  final DateTime windowStart;
  final DateTime windowEnd;

  const SignalSnapshot({
    required this.unlockCount,
    required this.appSwitchCount,
    required this.avgNotifLatencyMs,
    required this.zScores,
    required this.windowStart,
    required this.windowEnd,
  });
}
