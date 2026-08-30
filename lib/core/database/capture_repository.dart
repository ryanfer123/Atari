import 'package:drift/drift.dart';

import '../models/capture.dart';
import '../services/embedding_service.dart';
import 'app_database.dart';
import 'embedding_codec.dart';

/// Saved captures and semantic search over them.
///
/// Embedding happens on write: the vector is computed once when a
/// capture is confirmed rather than on every search, which is what keeps
/// search a linear scan over stored vectors instead of re-running the
/// model per query.
class CaptureRepository {
  CaptureRepository(this._db, this._embedder);

  final AppDatabase _db;
  final EmbeddingService _embedder;

  Capture _toDomain(CaptureRow row) => Capture(
    id: row.id,
    imagePath: row.imagePath,
    text: row.extractedText,
    createdAt: row.createdAt,
    hasEmbedding: row.embedding != null,
  );

  Stream<List<Capture>> watchAll() {
    return (_db.select(_db.captures)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Capture>> getAll() async {
    final rows = await (_db.select(
      _db.captures,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map(_toDomain).toList();
  }

  /// Saves a confirmed capture, embedding its text.
  ///
  /// A failure to embed is not a failure to save — the capture is still
  /// worth keeping, it just can't be found semantically until it's
  /// re-embedded.
  Future<int> create({
    required String imagePath,
    required String text,
    DateTime? now,
  }) async {
    List<double>? vector;
    try {
      vector = await _embedder.embed(text);
    } catch (_) {
      vector = null;
    }

    return _db
        .into(_db.captures)
        .insert(
          CapturesCompanion.insert(
            imagePath: imagePath,
            extractedText: text,
            createdAt: now ?? DateTime.now(),
            embedding: Value(
              vector == null ? null : EmbeddingCodec.encode(vector),
            ),
            embeddingModel: Value(
              vector == null ? null : _embedder.runtimeType.toString(),
            ),
            embeddingDimensions: Value(vector?.length),
          ),
        );
  }

  /// Captures most similar to [query], most relevant first.
  Future<List<Capture>> search(String query, {int k = 3}) async {
    final rows = await _db.select(_db.captures).get();

    final corpus = <int, List<double>>{};
    for (final row in rows) {
      final vector = EmbeddingCodec.decode(
        row.embedding,
        expectedDimensions: _embedder.dimensions,
      );
      if (vector != null) corpus[row.id] = vector;
    }

    final ids = await _embedder.topK(query: query, corpus: corpus, k: k);
    // Preserve rank order rather than table order.
    return [
      for (final id in ids) _toDomain(rows.firstWhere((r) => r.id == id)),
    ];
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.captures)..where((t) => t.id.equals(id))).go();
  }
}
