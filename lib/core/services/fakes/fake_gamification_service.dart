import 'dart:async';
import '../i_gamification_service.dart';
import '../../models/gamification_state.dart';
import '../../models/gamification_event.dart';
import '../../models/quest.dart';
import '../../models/achievement.dart';

class FakeGamificationService implements IGamificationService {
  final _stateController = StreamController<GamificationState>.broadcast();

  @override
  Stream<GamificationState> get stateStream => _stateController.stream;

  @override
  Future<GamificationState> getCurrentState() async {
    return const GamificationState(
      totalXp: 1200,
      level: 4,
      xpToNextLevel: 300,
      currentStreak: 5,
      activeQuests: [],
      unlockedAchievements: [],
    );
  }

  @override
  Future<List<GamificationEvent>> getRecentEvents({int limit = 20}) async => [];
  
  @override
  Future<List<Quest>> getActiveQuests() async => [];
  
  @override
  Future<List<Achievement>> getAllAchievements() async => [];
}
