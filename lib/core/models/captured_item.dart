/// Kind of record a captured item is heuristically parsed into. The user
/// always confirms/edits this before it is saved — see
/// Plans/IMPLEMENTATION.md §4.6.
enum ItemType { note, todo, healthTarget }

/// A candidate structured item produced by `CapturedItemParser`
/// (`lib/engine/capture`) from backend-native's raw OCR output.
///
/// Deliberately the output of simple heuristics, not a second LLM call —
/// see Plans/IMPLEMENTATION.md §4.6.
class CapturedItem {
  const CapturedItem({
    required this.rawText,
    required this.suggestedType,
    required this.suggestedTitle,
    required this.suggestedDeadline,
    required this.confidence,
  });

  final String rawText;

  /// Heuristic guess; the user confirms/corrects it in the review UI.
  final ItemType suggestedType;

  final String suggestedTitle;

  /// Parsed if a date/time pattern was found in [rawText], else null.
  final DateTime? suggestedDeadline;

  /// Heuristic confidence in `[0, 1]`, not a calibrated probability.
  final double confidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapturedItem &&
          runtimeType == other.runtimeType &&
          rawText == other.rawText &&
          suggestedType == other.suggestedType &&
          suggestedTitle == other.suggestedTitle &&
          suggestedDeadline == other.suggestedDeadline &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(
    rawText,
    suggestedType,
    suggestedTitle,
    suggestedDeadline,
    confidence,
  );

  @override
  String toString() =>
      'CapturedItem(suggestedType: $suggestedType, '
      'suggestedTitle: $suggestedTitle, '
      'suggestedDeadline: $suggestedDeadline, confidence: $confidence)';
}
