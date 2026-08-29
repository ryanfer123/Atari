import 'package:flutter/foundation.dart';
import 'quest.dart';
import 'achievement.dart';

@immutable
class GamificationState {
  final int totalXp;
  final int level;
  final int xpToNextLevel;
  final int currentStreak;
  final List<Quest> activeQuests;
  final List<Achievement> unlockedAchievements;

  const GamificationState({
    required this.totalXp,
    required this.level,
    required this.xpToNextLevel,
    required this.currentStreak,
    required this.activeQuests,
    required this.unlockedAchievements,
  });
}
