import '../models/models.dart';

/// Contract for on-device SLM explanation generation and masked agentic tool selection.
abstract class ISlmExplainerService {
  /// Generates a single-sentence supportive explanation grounded in structured evidence.
  Future<Explanation> generateExplanation(
    OverloadEvent event, {
    List<ContextBullet> contextBullets = const [],
  });

  /// Constrained masked agentic source selection over the closed 5-source enum (§4.8).
  Future<SourceSelection> selectSources({
    required String triggerSignal,
    required String topSignal,
    List<GoalContextSource> allowedSources = GoalContextSource.values,
    int maxCalls = 3,
  });

  /// Returns true when on-device model weights are loaded and ready for inference.
  Future<bool> isReady();
}
