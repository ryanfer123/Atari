import 'dart:math' as math;

import '../embedding_service.dart';
import '../model_services.dart';

/// Deterministic stand-in for EmbeddingGemma-300M.
///
/// Projects words into a fixed-width vector by hashing each into a
/// bucket (the "hashing trick"), with sub-linear term weighting so one
/// repeated word can't dominate. That gives real cosine geometry —
/// documents sharing vocabulary genuinely score higher — so the whole
/// embed/store/search path exercises the same code a real embedder
/// will.
///
/// It is honestly weaker than a real embedder in the way that matters
/// most: it has no notion of *meaning*, so "gym" and "workout" score
/// zero against each other. That gap is exactly what filling the
/// embedder slot fixes. See `README.md` in this directory.
class PlaceholderEmbeddingService extends EmbeddingService {
  /// Const so `const PlaceholderEmbeddingService()` is canonicalised to
  /// one instance — the default is constructed in several places and
  /// they should all be the same object.
  const PlaceholderEmbeddingService({this.dimensions = 128});

  @override
  final int dimensions;

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  static final _wordPattern = RegExp(r"[a-z0-9']+");

  /// Words carrying no topical signal. Kept short on purpose — an
  /// aggressive list would strip meaning from already-short notes.
  static const _stopWords = {
    'the',
    'and',
    'for',
    'you',
    'your',
    'with',
    'this',
    'that',
    'from',
    'have',
    'has',
    'are',
    'was',
    'were',
    'but',
    'not',
    'all',
    'any',
    'can',
    'will',
    'just',
    'out',
    'get',
    'got',
  };

  @override
  Future<List<double>> embed(String text) async {
    final vector = List<double>.filled(dimensions, 0);
    final counts = <String, int>{};

    for (final match in _wordPattern.allMatches(text.toLowerCase())) {
      final word = match[0]!;
      if (word.length < 3 || _stopWords.contains(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }
    if (counts.isEmpty) return vector;

    for (final entry in counts.entries) {
      final bucket = entry.key.hashCode.abs() % dimensions;
      // Sub-linear weighting: a word repeated ten times is more
      // significant than one used once, but not ten times so.
      final weight = 1 + math.log(entry.value);
      // A second hash decides the sign, so different words landing in
      // the same bucket tend to cancel rather than always reinforce.
      final sign = (entry.key.hashCode ~/ dimensions).isEven ? 1 : -1;
      vector[bucket] += weight * sign;
    }

    return vector;
  }
}
