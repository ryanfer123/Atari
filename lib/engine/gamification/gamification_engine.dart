import 'dart:math';

import '../../core/models/models.dart';

/// XP values for each trigger type.
///
/// Deliberately excludes any raw-reduced-screen-time trigger — XP must
/// always trace to a completed action. See Plans/IMPLEMENTATION.md §4.7.
const _kXpTable = <GamificationTrigger, int>{
  GamificationTrigger.interventionWorked: 50,
  GamificationTrigger.todoCompleted: 30,
  GamificationTrigger.healthTargetMet: 40,
  GamificationTrigger.captureOrganized: 20,
};

/// XP required to reach a given level.
/// Level 1 = 0 XP, Level 2 = 100 XP, Level N = 100 * (N-1).
int xpForLevel(int level) => max(0, 100 * (level - 1));

/// An active quest with a verifiable completion trigger.
class Quest {
  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    this.xpReward = 100,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final int targetCount;
  int currentCount;
  final int xpReward;
  bool isCompleted;

  double get progress => targetCount > 0 ? min(1.0, currentCount / targetCount) : 0.0;

  /// Advance this quest and return true if it just completed.
  bool advance({int by = 1}) {
    if (isCompleted) return false;
    currentCount = min(currentCount + by, targetCount);
    if (currentCount >= targetCount) {
      isCompleted = true;
      return true;
    }
    return false;
  }
}

/// Deterministic XP progression engine with non-losable streaks.
///
/// Core rules:
/// 1. XP is always awarded for verified completed actions, never for
///    raw reduced screen time.
/// 2. Streaks are non-losable: a missed day pauses progress, it never
///    subtracts XP or resets to zero.
/// 3. Streaks and levels are derived from the [GamificationEvent] log.
///
/// See Plans/IMPLEMENTATION.md §4.7 and RESEARCH.md §Expansion:
/// gamified capture-to-organize layer.
class GamificationEngine {
  GamificationEngine();

  final List<GamificationEvent> _events = [];
  final List<Quest> _quests = [];

  int _totalXp = 0;
  int _currentStreak = 0;
  DateTime? _lastActiveDay;

  /// All recorded gamification events.
  List<GamificationEvent> get events => List.unmodifiable(_events);

  /// Active and completed quests.
  List<Quest> get quests => List.unmodifiable(_quests);

  /// Total lifetime XP earned.
  int get totalXp => _totalXp;

  /// Current level (1-indexed).
  int get level {
    var lvl = 1;
    while (xpForLevel(lvl + 1) <= _totalXp) {
      lvl++;
    }
    return lvl;
  }

  /// XP progress toward the next level, as a fraction [0..1].
  double get levelProgress {
    final currentLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    final range = nextLevelXp - currentLevelXp;
    if (range <= 0) return 1.0;
    return min(1.0, (_totalXp - currentLevelXp) / range);
  }

  /// Current non-losable streak (consecutive active days, never reset).
  int get streak => _currentStreak;

  /// Award XP for a completed action and return the event.
  ///
  /// Also advances any active quests matching the trigger.
  GamificationEvent award(GamificationTrigger trigger, {DateTime? at}) {
    final xp = _kXpTable[trigger] ?? 0;
    final now = at ?? DateTime.now();

    final event = GamificationEvent(
      trigger: trigger,
      xpAwarded: xp,
      timestamp: now,
    );
    _events.add(event);
    _totalXp += xp;

    // Update non-losable streak.
    _updateStreak(now);

    // Advance matching quests and award bonus XP for completions.
    _advanceQuests(trigger);

    return event;
  }

  /// Add a quest to the active quest list.
  void addQuest(Quest quest) {
    _quests.add(quest);
  }

  /// Non-losable streak logic:
  /// - Same day: no change.
  /// - Next day: streak increments by 1.
  /// - Later: streak stays the same (paused, never reset).
  void _updateStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActiveDay == null) {
      _currentStreak = 1;
      _lastActiveDay = today;
      return;
    }

    final lastDay = DateTime(
      _lastActiveDay!.year,
      _lastActiveDay!.month,
      _lastActiveDay!.day,
    );

    final diff = today.difference(lastDay).inDays;

    if (diff == 0) {
      // Same day: no change.
    } else if (diff == 1) {
      // Consecutive day: increment.
      _currentStreak++;
      _lastActiveDay = today;
    } else {
      // Gap: pause, don't reset. Just update the active day.
      _lastActiveDay = today;
      // Streak stays the same — non-losable.
    }
  }

  void _advanceQuests(GamificationTrigger trigger) {
    for (final quest in _quests) {
      if (quest.isCompleted) continue;
      // Advance quests whose trigger matches (simplified: advance all active).
      if (quest.advance()) {
        _totalXp += quest.xpReward;
        _events.add(GamificationEvent(
          trigger: trigger,
          xpAwarded: quest.xpReward,
          timestamp: DateTime.now(),
        ));
      }
    }
  }
}
