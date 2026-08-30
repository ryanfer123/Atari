import 'package:drift/drift.dart';

/// A saved capture: the cropped image, the text read out of it, and its
/// embedding.
///
/// This is what makes `GoalContextSource.captureHistory` a real source —
/// something circled last week can ground an explanation today.
@DataClassName('CaptureRow')
class Captures extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Path to the cropped PNG the overlay produced.
  TextColumn get imagePath => text()();

  /// Text extracted by OCR, as the user confirmed it. Named
  /// `extractedText`, not `text`, because `text` is Drift's own
  /// column-builder method on [Table] and would collide.
  TextColumn get extractedText => text()();

  /// Embedding of [extractedText], stored as little-endian float64s.
  ///
  /// Nullable because a capture is still worth keeping if the embedder
  /// wasn't available — it just can't be searched semantically until
  /// it's re-embedded.
  BlobColumn get embedding => blob().nullable()();

  /// Which embedder produced [embedding]. Vectors from a different model
  /// aren't comparable, so this is what lets stale ones be detected
  /// rather than silently compared.
  TextColumn get embeddingModel => text().nullable()();

  IntColumn get embeddingDimensions => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
