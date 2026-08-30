/// A free-text note. Typed directly, or saved from a confirmed capture.
///
/// Notes are the one source that would use semantic (embedding-based)
/// retrieval in `GoalContext` — see Plans/IMPLEMENTATION.md §0.1. Until
/// an embedder is wired in, retrieval falls back to keyword matching
/// (`lib/core/services/placeholders/`).
class Note {
  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    this.sourceCaptureId,
  });

  final int id;
  final String text;
  final DateTime createdAt;

  /// Set when this note came from the capture flow rather than typing.
  final int? sourceCaptureId;

  /// First line, for list display.
  String get title {
    final firstLine = text.split(RegExp(r'\r\n|\r|\n')).first.trim();
    return firstLine.isEmpty ? '(empty note)' : firstLine;
  }
}
