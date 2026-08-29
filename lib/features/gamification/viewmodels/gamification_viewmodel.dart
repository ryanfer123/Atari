import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/models/gamification_state.dart';
import '../../../core/services/i_gamification_service.dart';

class GamificationViewModel extends ChangeNotifier {
  final IGamificationService _gamificationService;

  GamificationViewModel({
    required IGamificationService gamificationService,
  }) : _gamificationService = gamificationService;

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  GamificationState? _gamificationState;
  GamificationState? get gamificationState => _gamificationState;

  // Active days & flame animation properties
  int get totalActiveDays => _gamificationState?.currentStreak ?? 0;
  
  // 0 means active today, >0 represents gap days
  int get daysSinceLastActive => 0;

  int get level => _gamificationState?.level ?? 1;
  int get totalXp => _gamificationState?.totalXp ?? 0;
  int get xpToNextLevel => _gamificationState?.xpToNextLevel ?? 100;
  double get progressToNextLevel {
    if (xpToNextLevel <= 0) return 1.0;
    return (totalXp % xpToNextLevel) / xpToNextLevel;
  }

  StreamSubscription? _stateSub;
  String? _error;
  String? get error => _error;

  void init() async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      _gamificationState = await _gamificationService.getCurrentState();
      _stateSub = _gamificationService.stateStream.listen((newState) {
        _gamificationState = newState;
        notifyListeners();
      });
      _state = ViewState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = ViewState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }
}
