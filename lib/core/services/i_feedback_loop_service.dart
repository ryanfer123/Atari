import '../models/intervention_result.dart';

abstract class IFeedbackLoopService {
  Future<List<InterventionResult>> getRecentResults({int limit = 10});
  Stream<InterventionResult> get resultStream;
}
