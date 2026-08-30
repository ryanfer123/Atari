import '../../models/difficulty_tier.dart';
import '../../models/subtask_spec.dart';
import '../../models/task_tool.dart';
import '../model_services.dart';

/// Deterministic stand-in for the on-device SLM's task decomposition.
///
/// Splits on explicit conjunctions/separators the user already wrote
/// ("and", ",", "then") rather than inventing steps — a placeholder that
/// hallucinated plausible-sounding subtasks would be worse than one that
/// admits it can't decompose, since the user would have to undo them.
/// See `README.md` in this directory.
class PlaceholderTaskDecomposer implements TaskDecomposer {
  const PlaceholderTaskDecomposer();

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  static final _separators = RegExp(
    r'\s*(?:,|;|\bthen\b|\band then\b|\band\b)\s*',
    caseSensitive: false,
  );

  @override
  Future<DecompositionResult> decompose({
    required String title,
    String? notes,
  }) async {
    final parts = title
        .split(_separators)
        .map((p) => p.trim())
        .where((p) => p.length >= 3)
        .toList();

    // One part means there was nothing to split on. Returning "no
    // decomposition" is the honest answer, not a failure.
    if (parts.length < 2) {
      return const DecompositionResult.fallback(
        'placeholder: no explicit steps found in the task text',
      );
    }

    if (parts.length > maxSubtasks) {
      // Same cap-then-fall-back rule the real model path uses — see
      // maxSubtasks' doc comment.
      return const DecompositionResult.fallback(
        'placeholder: more than $maxSubtasks steps found',
      );
    }

    return DecompositionResult(
      subtasks: [
        for (final part in parts)
          SubtaskSpec(
            title: _capitalize(part),
            estimatedMinutes: 15,
            tier: DifficultyTier.light,
            suggestedTool: TaskTool.none,
          ),
      ],
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
