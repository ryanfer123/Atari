/// A saved capture: the cropped region the user circled, the text read
/// out of it, and whether it was successfully embedded.
///
/// Captures feed `GoalContextSource.captureHistory`, so something
/// circled last week can ground an explanation today.
class Capture {
  const Capture({
    required this.id,
    required this.imagePath,
    required this.text,
    required this.createdAt,
    required this.hasEmbedding,
  });

  final int id;

  /// Path to the cropped image on device.
  final String imagePath;

  final String text;
  final DateTime createdAt;

  /// False when the embedder was unavailable at save time — the capture
  /// is kept, but it can't be found by semantic search until it's
  /// re-embedded.
  final bool hasEmbedding;

  /// First line, for list display.
  String get title {
    final firstLine = text.split(RegExp(r'\r\n|\r|\n')).first.trim();
    return firstLine.isEmpty ? '(no text found)' : firstLine;
  }
}
