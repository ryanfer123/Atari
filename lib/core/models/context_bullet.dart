/// One flat, source-attributed line of goal context assembled by
/// `GoalContext` (`lib/engine/orchestration`) for the SLM's explanation
/// prompt.
///
/// Bullets from different sources are concatenated as plain text and never
/// combined in a joint embedding space — see Plans/IMPLEMENTATION.md §0.1,
/// §4.5 and RESEARCH.md §Expansion: goal-context layer.
class ContextBullet {
  const ContextBullet({required this.source, required this.text});

  factory ContextBullet.fromJson(Map<String, dynamic> json) {
    return ContextBullet(
      source: json['source'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  /// Origin of this bullet, e.g. `note`, `todo`, `health`, `calendar`.
  final String source;

  final String text;

  Map<String, dynamic> toJson() => {
    'source': source,
    'text': text,
  };

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
enum GoalContextSource {
  notes,
  todos,
  healthTargets,
  calendar,
  captureHistory;

  String get wireName {
    switch (this) {
      case GoalContextSource.notes:
        return 'notes';
      case GoalContextSource.todos:
        return 'todos';
      case GoalContextSource.healthTargets:
        return 'health_targets';
      case GoalContextSource.calendar:
        return 'calendar';
      case GoalContextSource.captureHistory:
        return 'capture_history';
    }
  }

  static GoalContextSource? fromWireName(String name) {
    switch (name.toLowerCase()) {
      case 'notes':
        return GoalContextSource.notes;
      case 'todos':
        return GoalContextSource.todos;
      case 'health_targets':
      case 'health':
        return GoalContextSource.healthTargets;
      case 'calendar':
        return GoalContextSource.calendar;
      case 'capture_history':
      case 'capture':
        return GoalContextSource.captureHistory;
      default:
        return null;
    }
  }
}

/// Result of one masked, schema-validated source-selection decision.
///
/// See Plans/IMPLEMENTATION.md §4.8.
class SourceSelection {
  const SourceSelection({
    required this.sources,
    required this.reasoning,
    this.usedModel = false,
  });

  factory SourceSelection.fromJson(Map<String, dynamic> json) {
    final rawSources = json['selectedSources'] as List<dynamic>? ?? [];
    final parsed = rawSources
        .map((s) => GoalContextSource.fromWireName(s.toString()))
        .whereType<GoalContextSource>()
        .toList();

    return SourceSelection(
      sources: parsed.isNotEmpty ? parsed : GoalContextSource.values.take(3).toList(),
      reasoning: json['reasoning'] as String? ?? 'Masked source selection fallback',
      usedModel: json['usedModel'] as bool? ?? false,
    );
  }

  final List<GoalContextSource> sources;
  final String reasoning;
  final bool usedModel;

  Map<String, dynamic> toJson() => {
    'selectedSources': sources.map((s) => s.wireName).toList(),
    'reasoning': reasoning,
    'usedModel': usedModel,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceSelection &&
          runtimeType == other.runtimeType &&
          reasoning == other.reasoning &&
          usedModel == other.usedModel &&
          _listEquals(sources, other.sources);

  @override
  int get hashCode => Object.hash(reasoning, usedModel, Object.hashAll(sources));

  @override
  String toString() =>
      'SourceSelection(sources: $sources, reasoning: $reasoning, usedModel: $usedModel)';
}

bool _listEquals(List<GoalContextSource> a, List<GoalContextSource> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
