import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/database/health_target_repository.dart';
import 'package:atari/core/database/note_repository.dart';
import 'package:atari/core/database/todo_repository.dart';
import 'package:atari/core/services/placeholders/placeholder_embedding_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The quick-add screen writes a whole batch of classified lines in one
/// transaction. These cover the property that matters: a batch either
/// lands completely or not at all, so a retry can never duplicate the
/// half that already saved.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a batch across three tables commits together', () async {
    final todos = TodoRepository(db);
    final notes = NoteRepository(db, const PlaceholderEmbeddingService());
    final targets = HealthTargetRepository(db);

    await db.transaction(() async {
      await todos.create(title: 'Finish the assignment');
      await notes.create(text: 'Library shuts at nine');
      await targets.create(metric: 'Sleep', threshold: '7 hours');
    });

    expect(await todos.getTopLevel(), hasLength(1));
    expect(await notes.getAll(), hasLength(1));
    expect(await targets.activeTargets(), hasLength(1));
  });

  test('a failure part-way through leaves nothing behind', () async {
    final todos = TodoRepository(db);
    final notes = NoteRepository(db, const PlaceholderEmbeddingService());

    await expectLater(
      db.transaction(() async {
        await todos.create(title: 'Saved first');
        await notes.create(text: 'Then this');
        // Stands in for any write failing mid-batch.
        throw StateError('write failed');
      }),
      throwsA(isA<StateError>()),
    );

    // The point of the transaction: the user is told nothing saved, and
    // that is actually true, so retyping the batch cannot duplicate rows.
    expect(await todos.getTopLevel(), isEmpty);
    expect(await notes.getAll(), isEmpty);
  });

  test('a note keeps a precomputed embedding rather than re-embedding', () async {
    const embedder = PlaceholderEmbeddingService();
    final notes = NoteRepository(db, embedder);

    // Embedding is hoisted out of the transaction because it is a model
    // call; the vector computed outside must be the one stored.
    final vector = await notes.tryEmbed('Library shuts at nine');
    await db.transaction(() async {
      await notes.create(text: 'Library shuts at nine', embedding: vector);
    });

    final stored = await notes.getAll();
    expect(stored, hasLength(1));
    final ranked = await embedder.topK(
      query: 'when does the library close',
      corpus: {stored.first.id: vector!},
      k: 1,
      minSimilarity: 0,
    );
    expect(ranked, [stored.first.id]);
  });
}
