import 'dart:math' as math;

import 'model_services.dart';

/// Turns text into a vector so free-text content can be searched by
/// meaning rather than exact words.
///
/// Only free-text sources are embedded — notes and captures. Todos and
/// health targets stay structured field queries, because a field filter
/// is cheaper and more reliable over a deadline or a threshold than
/// semantic search is (Plans/IMPLEMENTATION.md §2).
///
/// Ranking deliberately lives here as plain cosine arithmetic rather
/// than in an ANN library: at personal-corpus scale (dozens to low
/// hundreds of items) a linear scan is already fast, and an index would
/// be complexity without benefit (§7 item 7).
abstract class EmbeddingService {
  const EmbeddingService();

  ModelBackend get backend;

  /// Length of the vectors this service produces. Stored alongside each
  /// embedding so vectors written by a different model can be detected
  /// and ignored rather than compared nonsensically.
  int get dimensions;

  Future<List<double>> embed(String text);

  /// Ids from [corpus] ranked most-similar to [query] first, at most
  /// [k]. Entries whose vector length doesn't match [dimensions] are
  /// skipped — they came from a different embedder.
  Future<List<int>> topK({
    required String query,
    required Map<int, List<double>> corpus,
    int k = 2,
    double minSimilarity = 0.05,
  }) async {
    if (corpus.isEmpty) return const [];
    final queryVector = await embed(query);

    final scored = <({int id, double score})>[];
    for (final entry in corpus.entries) {
      if (entry.value.length != queryVector.length) continue;
      final score = cosineSimilarity(queryVector, entry.value);
      if (score >= minSimilarity) scored.add((id: entry.key, score: score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      // Stable tiebreak by id so results don't reshuffle between calls.
      return byScore != 0 ? byScore : a.id.compareTo(b.id);
    });
    return scored.take(k).map((e) => e.id).toList();
  }
}

/// Cosine similarity in `[-1, 1]`; 0 when either vector has no
/// magnitude, which avoids a divide-by-zero on empty text.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;
  var dot = 0.0, normA = 0.0, normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}
