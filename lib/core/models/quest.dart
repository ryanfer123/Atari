import 'package:flutter/foundation.dart';

@immutable
class Quest {
  final String id;
  final String title;
  final String description;
  final int currentProgress;
  final int targetProgress;
  final int xpReward;
  final bool isCompleted;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    required this.xpReward,
    required this.isCompleted,
  });
}
