import '../models/gamification_state.dart';
import '../models/gamification_event.dart';
import '../models/quest.dart';
import '../models/achievement.dart';

abstract class IGamificationService {
  Stream<GamificationState> get stateStream;
  Future<GamificationState> getCurrentState();
  Future<List<GamificationEvent>> getRecentEvents({int limit = 20});
  Future<List<Quest>> getActiveQuests();
  Future<List<Achievement>> getAllAchievements();
}
