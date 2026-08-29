import 'dart:async';
import '../i_overload_service.dart';
import '../../models/agent_state.dart';
import '../../models/overload_event.dart';

class FakeOverloadService implements IOverloadService {
  final _stateController = StreamController<AgentState>.broadcast();
  final _eventController = StreamController<OverloadEvent?>.broadcast();
  AgentState _currentState = AgentState.normal;

  @override
  Stream<AgentState> get stateStream => _stateController.stream;

  @override
  Stream<OverloadEvent?> get latestOverloadEvent => _eventController.stream;

  @override
  Future<void> simulateOverload() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentState = AgentState.overloadDetected;
    _stateController.add(_currentState);
    
    _eventController.add(OverloadEvent(
      timestamp: DateTime.now(),
      signalScores: {'app_switches': 2.5},
      severity: 2.1,
      topSignal: 'app_switches',
      baselineContext: 'Tuesday afternoon'
    ));

    Future.delayed(const Duration(seconds: 2), () {
      _currentState = AgentState.intervening;
      _stateController.add(_currentState);
    });
  }
}
