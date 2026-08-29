import 'package:flutter/foundation.dart';

/// Point-in-time snapshot of raw behavioural signal observations from Android sensing APIs.
///
/// See Plans/IMPLEMENTATION.md §1 and Plans/frontend_prd.md §4.5.
@immutable
class SignalSnapshot {
  const SignalSnapshot({
    required this.unlockCount,
    required this.appSwitchCount,
    required this.avgNotifLatencyMs,
    required this.windowStart,
    required this.windowEnd,
  });

  factory SignalSnapshot.fromJson(Map<String, dynamic> json) {
    final startMs = json['windowStartMs'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final endMs = json['windowEndMs'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return SignalSnapshot(
      unlockCount: json['unlockCount'] as int? ?? 0,
      appSwitchCount: json['appSwitchCount'] as int? ?? 0,
      avgNotifLatencyMs: (json['avgNotifLatencyMs'] as num?)?.toDouble() ?? 0.0,
      windowStart: DateTime.fromMillisecondsSinceEpoch(startMs),
      windowEnd: DateTime.fromMillisecondsSinceEpoch(endMs),
    );
  }

  final int unlockCount;
  final int appSwitchCount;
  final double avgNotifLatencyMs;
  final DateTime windowStart;
  final DateTime windowEnd;

  Map<String, dynamic> toJson() => {
    'unlockCount': unlockCount,
    'appSwitchCount': appSwitchCount,
    'avgNotifLatencyMs': avgNotifLatencyMs,
    'windowStartMs': windowStart.millisecondsSinceEpoch,
    'windowEndMs': windowEnd.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalSnapshot &&
          runtimeType == other.runtimeType &&
          unlockCount == other.unlockCount &&
          appSwitchCount == other.appSwitchCount &&
          avgNotifLatencyMs == other.avgNotifLatencyMs &&
          windowStart == other.windowStart &&
          windowEnd == other.windowEnd;

  @override
  int get hashCode => Object.hash(
    unlockCount,
    appSwitchCount,
    avgNotifLatencyMs,
    windowStart,
    windowEnd,
  );
}
