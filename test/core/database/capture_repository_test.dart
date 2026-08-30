import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/database/capture_repository.dart';
import 'package:atari/core/database/embedding_codec.dart';
import 'package:atari/core/database/note_repository.dart';
import 'package:atari/core/services/embedding_service.dart';
import 'package:atari/core/services/model_services.dart';
import 'package:atari/core/services/placeholders/placeholder_embedding_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Embedder that always fails, to prove a broken model doesn't cost the
/// user their data.
class _FailingEmbedder extends EmbeddingService {
  const _FailingEmbedder();

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  @override
  int get dimensions => 128;

  @override
  Future<List<double>> embed(String text) async =>
      throw StateError('model unavailable');
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('EmbeddingCodec', () {
    test('round-trips a vector exactly', () {
      const vector = [0.5, -1.25, 0.0, 3.75];
      expect(EmbeddingCodec.decode(EmbeddingCodec.encode(vector)), vector);
    });

    test(
      'rejects a blob whose width disagrees with the expected dimensions',
      () {
        final blob = EmbeddingCodec.encode(const [1, 2, 3]);
        // A vector from a different model must be ignored, not compared.
        expect(EmbeddingCodec.decode(blob, expectedDimensions: 128), isNull);
      },
    );

    test('rejects a truncated blob rather than decoding garbage', () {
      final blob = EmbeddingCodec.encode(const [1, 2]);
      expect(EmbeddingCodec.decode(blob.sublist(0, 9)), isNull);
    });

    test('treats null and empty as absent', () {
      expect(EmbeddingCodec.decode(null), isNull);
    });
  });

  group('CaptureRepository', () {
    test('stores a capture and embeds it', () async {
      final repo = CaptureRepository(db, const PlaceholderEmbeddingService());
      await repo.create(
        imagePath: '/tmp/a.png',
        text: 'Submit OS assignment by Friday',
      );

      final saved = (await repo.getAll()).single;
      expect(saved.text, 'Submit OS assignment by Friday');
      expect(saved.imagePath, '/tmp/a.png');
      expect(saved.hasEmbedding, isTrue);
    });

    test('finds a stored capture by meaning, not exact wording', () async {
      final repo = CaptureRepository(db, const PlaceholderEmbeddingService());
      await repo.create(
        imagePath: '/tmp/a.png',
        text: 'Gym session Thursday evening',
      );
      await repo.create(
        imagePath: '/tmp/b.png',
        text: 'Submarine engineering manual',
      );

      final hits = await repo.search('evening gym', k: 1);
      expect(hits, hasLength(1));
      expect(hits.single.text, contains('Gym'));
    });

    test(
      'search returns nothing rather than throwing on an empty store',
      () async {
        final repo = CaptureRepository(db, const PlaceholderEmbeddingService());
        expect(await repo.search('anything'), isEmpty);
      },
    );

    test(
      'a failing embedder still saves the capture, just unsearchable',
      () async {
        final repo = CaptureRepository(db, const _FailingEmbedder());
        await repo.create(
          imagePath: '/tmp/a.png',
          text: 'Something worth keeping',
        );

        final saved = (await repo.getAll()).single;
        expect(
          saved.text,
          'Something worth keeping',
          reason: 'a broken model must not lose user data',
        );
        expect(saved.hasEmbedding, isFalse);
        expect(await repo.search('something'), isEmpty);
      },
    );
  });

  group('NoteRepository embedding', () {
    test('embeds on write and finds notes by meaning', () async {
      final repo = NoteRepository(db, const PlaceholderEmbeddingService());
      await repo.create(text: 'Gym session Thursday evening');
      await repo.create(text: 'Submarine engineering manual');

      final hits = await repo.search('evening gym', k: 1);
      expect(hits.single.text, contains('Gym'));
    });

    test('re-embeds when the text is edited', () async {
      final repo = NoteRepository(db, const PlaceholderEmbeddingService());
      final id = await repo.create(text: 'Gym session Thursday evening');

      await repo.updateText(id, 'Submarine engineering manual');

      // The old vector must not still match the old wording.
      expect(await repo.search('evening gym', k: 1), isEmpty);
      expect((await repo.search('submarine manual', k: 1)).single.id, id);
    });
  });
}
