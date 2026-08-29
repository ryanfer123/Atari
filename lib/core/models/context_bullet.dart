/// One flat, source-attributed line of goal context assembled by
/// `GoalContext` (`lib/engine/orchestration`) for the SLM's explanation
/// prompt.
///
/// Bullets from different sources are concatenated as plain text and never
/// combined in a joint embedding space — see Plans/IMPLEMENTATION.md §0.1,
/// §4.5 and RESEARCH.md §Expansion: goal-context layer.
class ContextBullet {
  const ContextBullet({required this.source, required this.text});

  /// Origin of this bullet, e.g. `note`, `todo`, `health`, `calendar`.
  final String source;

  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextBullet &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          text == other.text;

  @override
  int get hashCode => Object.hash(source, text);

  @override
  String toString() => 'ContextBullet(source: $source, text: $text)';
}

/// The closed set of sources `MaskedSourceSelector` may choose among.
///
/// A closed enum, not an open tool name the model generates freely —
/// function masking is what makes small-model tool selection reliable.
/// See Plans/IMPLEMENTATION.md §4.8.
enum GoalContextSource { notes, todos, healthTargets, calendar, captureHistory }

/// Result of one masked, schema-validated source-selection decision.
///
/// See Plans/IMPLEMENTATION.md §4.8.
class SourceSelection {
  const SourceSelection({required this.sources, required this.reasoning});

  final List<GoalContextSource> sources;
  final String reasoning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceSelection &&
          runtimeType == other.runtimeType &&
          reasoning == other.reasoning &&
          _listEquals(sources, other.sources);

  @override
  int get hashCode => Object.hash(reasoning, Object.hashAll(sources));

  @override
  String toString() =>
      'SourceSelection(sources: $sources, reasoning: $reasoning)';
}

bool _listEquals(List<GoalContextSource> a, List<GoalContextSource> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
