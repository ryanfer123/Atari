import 'package:drift/drift.dart';

/// Persisted form of `Note` (`lib/core/models/note.dart`).
@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The note's content. Named `body`, not `text`, because `text` is
  /// Drift's own column-builder method on [Table] and would collide.
  /// The domain model (`Note.text`) keeps the natural name.
  TextColumn get body => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Set when this note came from the capture flow rather than typing.
  IntColumn get sourceCaptureId => integer().nullable()();

  /// Embedding of [body], stored as little-endian float64s. Nullable so
  /// a note is still savable when no embedder is available.
  BlobColumn get embedding => blob().nullable()();

  TextColumn get embeddingModel => text().nullable()();
  IntColumn get embeddingDimensions => integer().nullable()();
}
