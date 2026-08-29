import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/models/agent_state.dart';
import '../../../core/models/signal_snapshot.dart';
import '../../../core/models/gamification_state.dart';
import '../../../core/models/intervention_result.dart';
import '../../../core/services/i_overload_service.dart';
import '../../../core/services/i_baseline_service.dart';
import '../../../core/services/i_gamification_service.dart';
import '../../../core/services/i_feedback_loop_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final IOverloadService _overloadService;
  final IBaselineService _baselineService;
  final IGamificationService _gamificationService;
  final IFeedbackLoopService _feedbackLoopService;

  DashboardViewModel({
    required IOverloadService overloadService,
    required IBaselineService baselineService,
    required IGamificationService gamificationService,
    required IFeedbackLoopService feedbackLoopService,
  })  : _overloadService = overloadService,
        _baselineService = baselineService,
        _gamificationService = gamificationService,
        _feedbackLoopService = feedbackLoopService;

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  AgentState _agentState = AgentState.normal;
  AgentState get agentState => _agentState;

  SignalSnapshot? _snapshot;
  SignalSnapshot? get snapshot => _snapshot;
  
  GamificationState? _gamification;
  GamificationState? get gamification => _gamification;

  List<InterventionResult> _recentInterventions = [];
  List<InterventionResult> get recentInterventions => _recentInterventions;

  String? _error;
  String? get error => _error;

  StreamSubscription? _stateSub;
  StreamSubscription? _snapshotSub;
  StreamSubscription? _gamificationSub;

  void init() async {
    _state = ViewState.loading;
    notifyListeners();

    _gamification = await _gamificationService.getCurrentState();
    _recentInterventions = await _feedbackLoopService.getRecentResults();
    _snapshot = await _baselineService.getCurrentSnapshot();

    _stateSub = _overloadService.stateStream.listen((s) {
      _agentState = s;
      notifyListeners();
    });

    _snapshotSub = _baselineService.snapshotStream.listen((snap) {
      _snapshot = snap;
      _state = ViewState.loaded;
      notifyListeners();
    });
    
    _gamificationSub = _gamificationService.stateStream.listen((g) {
      _gamification = g;
      notifyListeners();
    });
    
    _state = ViewState.loaded;
    notifyListeners();
  }

  void simulateOverload() {
    _overloadService.simulateOverload();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _snapshotSub?.cancel();
    _gamificationSub?.cancel();
    super.dispose();
  }
}
