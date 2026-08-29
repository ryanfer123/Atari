import 'package:flutter/foundation.dart';

enum GamificationTrigger {
  interventionWorked,
  todoCompleted,
  healthTargetMet,
  captureOrganized,
}

@immutable
class GamificationEvent {
  final GamificationTrigger trigger;
  final int xpAwarded;
  final DateTime timestamp;

  const GamificationEvent({
    required this.trigger,
    required this.xpAwarded,
    required this.timestamp,
  });
}
