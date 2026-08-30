import 'difficulty_tier.dart';
import 'task_tool.dart';

/// Hard cap on how many subtasks a decomposition may produce.
///
/// Exceeding it is treated as a malformed response and falls back to "no
/// decomposition" rather than truncating — a model that wanted 9 steps
/// probably misunderstood the task, and silently keeping the first 4
/// would hide that. Same cap-then-fall-back rule as
/// `MaskedSourceSelector.maxCalls` (Plans/IMPLEMENTATION.md §4.8);
/// see Plans/PIVOT_PLAN.md §2.3.
const int maxSubtasks = 4;

/// One proposed step of a decomposed task. Never persisted directly —
/// the user confirms it first (Plans/PIVOT_PLAN.md §2.4).
class SubtaskSpec {
  const SubtaskSpec({
    required this.title,
    required this.estimatedMinutes,
    required this.tier,
    this.suggestedTool = TaskTool.none,
  });

  final String title;
  final int estimatedMinutes;
  final DifficultyTier tier;

  /// What the model proposes doing about this step. Requires a user tap
  /// before it becomes real — see [TaskTool].
  final TaskTool suggestedTool;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtaskSpec &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          estimatedMinutes == other.estimatedMinutes &&
          tier == other.tier &&
          suggestedTool == other.suggestedTool;

  @override
  int get hashCode => Object.hash(title, estimatedMinutes, tier, suggestedTool);

  @override
  String toString() =>
      'SubtaskSpec(title: $title, estimatedMinutes: $estimatedMinutes, '
      'tier: $tier, suggestedTool: $suggestedTool)';
}

/// Result of one decomposition attempt.
///
/// An empty [subtasks] list with a non-null [fallbackReason] is the
/// deterministic "couldn't decompose safely, leave the task as-is"
/// outcome — a legitimate result, not an error to retry.
class DecompositionResult {
  const DecompositionResult({required this.subtasks, this.fallbackReason});

  const DecompositionResult.fallback(String reason)
    : subtasks = const [],
      fallbackReason = reason;

  final List<SubtaskSpec> subtasks;
  final String? fallbackReason;

  bool get usedModel => fallbackReason == null;
}
