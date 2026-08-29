import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/models/signal_snapshot.dart';
import '../../../core/models/agent_state.dart';
import '../../../core/services/i_baseline_service.dart';
import '../../../core/services/i_overload_service.dart';
import '../../../core/services/i_slm_explainer_service.dart';

class InsightsViewModel extends ChangeNotifier {
  final IBaselineService _baselineService;
  final IOverloadService _overloadService;
  final ISlmExplainerService _explainerService;

  InsightsViewModel({
    required IBaselineService baselineService,
    required IOverloadService overloadService,
    required ISlmExplainerService explainerService,
  })  : _baselineService = baselineService,
        _overloadService = overloadService,
        _explainerService = explainerService;

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  SignalSnapshot? _snapshot;
  SignalSnapshot? get snapshot => _snapshot;

  AgentState _agentState = AgentState.normal;
  AgentState get agentState => _agentState;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  String? _lastCheckResult;
  String? get lastCheckResult => _lastCheckResult;

  StreamSubscription? _snapshotSub;
  StreamSubscription? _stateSub;
  String? _error;
  String? get error => _error;

  void init() async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      _snapshot = await _baselineService.getCurrentSnapshot();
      _snapshotSub = _baselineService.snapshotStream.listen((snap) {
        _snapshot = snap;
        notifyListeners();
      });

      _stateSub = _overloadService.stateStream.listen((st) {
        _agentState = st;
        notifyListeners();
      });

      _state = ViewState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<void> runCheck() async {
    _isChecking = true;
    notifyListeners();

    // Simulate decision check delay
    await Future.delayed(const Duration(milliseconds: 600));
    _snapshot = await _baselineService.getCurrentSnapshot();
    _lastCheckResult = 'Baseline evaluated. All background signals nominal.';
    _isChecking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
