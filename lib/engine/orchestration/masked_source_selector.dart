import '../../core/models/context_bullet.dart';

/// Not-yet-validated model output for one source-selection decision.
///
/// [sourceNames] are whatever strings the model returned — even though the
/// model is constrained-decoded against [GoalContextSource]'s enum values
/// (grammar/JSON-schema constrained generation, per RESEARCH.md's "Small
/// Language Models for Agentic Systems" survey finding on guided decoding),
/// [MaskedSourceSelector] re-validates them in code as defense in depth
/// rather than trusting that constraint alone.
class RawSourceSelectionResponse {
  const RawSourceSelectionResponse({
    required this.sourceNames,
    required this.reasoning,
  });
  final List<String> sourceNames;
  final String reasoning;
}

/// One masked, schema-validated decision — `allowed` is always the full
/// [GoalContextSource] enum; the model never sees an open vocabulary.
typedef SourceSelectionModel = Future<RawSourceSelectionResponse> Function(
  String triggerSignal,
  String topSignal,
  List<GoalContextSource> allowed,
);

/// The only five choices the model is ever offered at this decision point —
/// a closed enum, not an open tool name the model generates freely.
/// Function masking is what makes small-model tool selection reliable; an
/// open vocabulary is exactly what the multi-step-orchestration failure
/// numbers (HyperTool, Evoflux, TOBench) were measured on.
///
/// This is the concrete implementation of §0.4's design rule: the model
/// gets genuine autonomy over *what it queries*, bounded by masking,
/// schema validation, and a hard call cap — never a free-form loop that
/// plans its own sequence or decides when to stop. The model never decides
/// to call this selector again and never invokes a source outside this
/// fixed five-option menu.
///
/// See Plans/IMPLEMENTATION.md §4.8.
class MaskedSourceSelector {
  MaskedSourceSelector({required SourceSelectionModel slm, this.maxCalls = 3})
    : _slm = slm;

  final SourceSelectionModel _slm;

  /// Cap hit is one of two guards (with an empty/malformed response) against
  /// the documented "infinite agentic loop" failure mode (RESEARCH.md:
  /// arXiv:2607.01641) — hitting it falls back rather than retrying.
  final int maxCalls;

  static const String fallbackReasoning = 'fallback: query all sources';

  /// Asks the model which sources to query for [triggerSignal] (with
  /// [topSignal] as the highest-severity signal in the current
  /// classification), validates the response, and falls back to querying
  /// every source if validation fails or the model asked for more than
  /// [maxCalls] distinct sources.
  Future<SourceSelection> select({
    required String triggerSignal,
    required String topSignal,
  }) async {
    final raw = await _slm(triggerSignal, topSignal, GoalContextSource.values);

    final validated = <GoalContextSource>[];
    for (final name in raw.sourceNames) {
      final match = GoalContextSource.values.where(
        (source) => source.name == name,
      );
      if (match.isEmpty) {
        continue; // hallucinated/invalid name — dropped, not thrown
      }
      final source = match.first;
      if (!validated.contains(source)) validated.add(source);
    }

    if (validated.isEmpty || validated.length > maxCalls) {
      return const SourceSelection(
        sources: GoalContextSource.values,
        reasoning: fallbackReasoning,
      );
    }
    return SourceSelection(sources: validated, reasoning: raw.reasoning);
  }
}
