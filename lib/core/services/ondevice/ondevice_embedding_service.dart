import 'package:flutter/foundation.dart';

import '../embedding_service.dart';
import '../model_services.dart';
import 'llama_channel.dart';

/// EmbeddingGemma-300M embeddings for notes and captures.
///
/// [dimensions] has to be known synchronously — the database stores it
/// with every vector so vectors from a different embedder can be
/// detected and skipped — so it is read once at startup by
/// [OnDeviceEmbeddingService.create] rather than being discovered on
/// first use.
///
/// A failed embed returns a zero vector rather than throwing: writing a
/// note must not fail because a model didn't load. Cosine similarity
/// against a zero vector is defined as 0 in [cosineSimilarity], so such
/// a row simply never matches a search instead of corrupting rankings.
class OnDeviceEmbeddingService extends EmbeddingService {
  const OnDeviceEmbeddingService({
    required this.dimensions,
    this.channel = const LlamaChannel(),
  });

  final LlamaChannel channel;

  @override
  final int dimensions;

  @override
  ModelBackend get backend => ModelBackend.onDevice;

  /// Loads the model once to learn its vector width, returning null if
  /// it isn't usable — which is the signal to keep the placeholder.
  static Future<OnDeviceEmbeddingService?> create({
    LlamaChannel channel = const LlamaChannel(),
  }) async {
    try {
      if (!await channel.isEmbedderReady()) return null;
      final dimensions = await channel.embeddingDimensions();
      if (dimensions <= 0) return null;
      return OnDeviceEmbeddingService(
        dimensions: dimensions,
        channel: channel,
      );
    } catch (e) {
      debugPrint('Embedding model unavailable: $e');
      return null;
    }
  }

  @override
  Future<List<double>> embed(String text) async {
    try {
      final vector = await channel.embed(text);
      if (vector.length != dimensions) {
        debugPrint(
          'Embedder returned ${vector.length} dimensions, expected $dimensions',
        );
        return List<double>.filled(dimensions, 0);
      }
      return vector;
    } catch (e) {
      debugPrint('Embedding failed, storing a zero vector: $e');
      return List<double>.filled(dimensions, 0);
    }
  }
}
