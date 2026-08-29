import 'dart:async';
import '../i_feedback_loop_service.dart';
import '../../models/intervention_result.dart';

class FakeFeedbackLoopService implements IFeedbackLoopService {
  final _streamController = StreamController<InterventionResult>.broadcast();

  @override
  Future<List<InterventionResult>> getRecentResults({int limit = 10}) async {
    return [
      InterventionResult(
        interventionType: 'focus_layer',
        preSignalLevel: 2.5,
        postSignalLevel: 1.0,
        effectSize: 0.6,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      )
    ];
  }

  @override
  Stream<InterventionResult> get resultStream => _streamController.stream;
}
