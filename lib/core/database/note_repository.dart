import 'package:drift/drift.dart';

import '../models/note.dart';
import '../services/embedding_service.dart';
import 'app_database.dart';
import 'embedding_codec.dart';

class NoteRepository {
  NoteRepository(this._db, this._embedder);

  final AppDatabase _db;
  final EmbeddingService _embedder;

  Note _toDomain(NoteRow row) => Note(
    id: row.id,
    text: row.body,
    createdAt: row.createdAt,
    sourceCaptureId: row.sourceCaptureId,
  );

  Stream<List<Note>> watchAll() {
    return (_db.select(_db.notes)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Note>> getAll() async {
    final rows = await (_db.select(
      _db.notes,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map(_toDomain).toList();
  }

  /// Embeds on write so search stays a linear scan over stored vectors
  /// rather than re-running the model per query. A failure to embed
  /// doesn't block saving — the note just isn't semantically findable
  /// until it's edited again.
  /// Public so a caller writing several notes at once can embed them
  /// *before* opening a transaction. Embedding is a model call, and
  /// under the one-model-at-a-time rule (Plans/PIVOT_PLAN.md §2.2) it
  /// can trigger a multi-second model load — holding a write lock across
  /// that would block every other query in the app.
  Future<List<double>?> tryEmbed(String text) => _tryEmbed(text);

  Future<List<double>?> _tryEmbed(String text) async {
    try {
      return await _embedder.embed(text);
    } catch (_) {
      return null;
    }
  }

  /// Pass [embedding] to reuse a vector already computed by [tryEmbed];
  /// omit it and the text is embedded here.
  Future<int> create({
    required String text,
    int? sourceCaptureId,
    DateTime? now,
    List<double>? embedding,
  }) async {
    final vector = embedding ?? await _tryEmbed(text);
    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            body: text,
            createdAt: now ?? DateTime.now(),
            sourceCaptureId: Value(sourceCaptureId),
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

  Future<void> updateText(int id, String text) async {
    final vector = await _tryEmbed(text);
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        body: Value(text),
        embedding: Value(vector == null ? null : EmbeddingCodec.encode(vector)),
        embeddingModel: Value(
          vector == null ? null : _embedder.runtimeType.toString(),
        ),
        embeddingDimensions: Value(vector?.length),
      ),
    );
  }

  /// Notes most similar to [query] — the cosine top-k that
  /// `GoalContext`'s notes source uses (Plans/IMPLEMENTATION.md §4.5).
  Future<List<Note>> search(String query, {int k = 2}) async {
    final rows = await _db.select(_db.notes).get();

    final corpus = <int, List<double>>{};
    for (final row in rows) {
      final vector = EmbeddingCodec.decode(
        row.embedding,
        expectedDimensions: _embedder.dimensions,
      );
      if (vector != null) corpus[row.id] = vector;
    }

    final ids = await _embedder.topK(query: query, corpus: corpus, k: k);
    return [
      for (final id in ids) _toDomain(rows.firstWhere((r) => r.id == id)),
    ];
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }
}
