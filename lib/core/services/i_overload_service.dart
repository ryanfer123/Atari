import '../models/agent_state.dart';
import '../models/overload_event.dart';

abstract class IOverloadService {
  Stream<AgentState> get stateStream;
  Stream<OverloadEvent?> get latestOverloadEvent;
  Future<void> simulateOverload();
}
