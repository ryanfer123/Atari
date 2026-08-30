import 'package:atari/core/models/context_bullet.dart';
import 'package:atari/core/models/difficulty_tier.dart';
import 'package:atari/core/models/subtask_spec.dart';
import 'package:atari/core/services/model_services.dart';
import 'package:atari/core/services/placeholders/placeholder_difficulty_scorer.dart';
import 'package:atari/core/services/embedding_service.dart';
import 'package:atari/core/services/placeholders/placeholder_embedding_service.dart';
import 'package:atari/core/services/placeholders/placeholder_ocr_service.dart';
import 'package:atari/core/services/placeholders/placeholder_slm_explainer.dart';
import 'package:atari/core/services/placeholders/placeholder_task_decomposer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('every placeholder reports itself honestly', () {
    test('none of them claim to be an on-device model', () {
      const implementations = [
        PlaceholderDifficultyScorer(),
        PlaceholderTaskDecomposer(),
        PlaceholderSlmExplainer(),
        PlaceholderOcrService(),
        PlaceholderEmbeddingService(),
      ];
      for (final impl in implementations) {
        final backend = switch (impl) {
          DifficultyScorer() => impl.backend,
          TaskDecomposer() => impl.backend,
          SlmExplainer() => impl.backend,
          OcrService() => impl.backend,
          EmbeddingService() => impl.backend,
          _ => fail('unhandled placeholder type ${impl.runtimeType}'),
        };
        expect(
          backend,
          ModelBackend.placeholder,
          reason: '${impl.runtimeType} must not claim to be a real model',
        );
      }
    });
  });

  group('PlaceholderDifficultyScorer', () {
    const scorer = PlaceholderDifficultyScorer();

    test('rates plain learning/effort keywords as moderate', () async {
      // No high-stakes word alongside it, so this is real effort but not
      // treated as if it were make-or-break — see the heavy case below
      // for the distinction this heuristic is trying to approximate.
      expect(
        await scorer.score(title: 'Write the OS report'),
        DifficultyTier.moderate,
      );
    });

    test('bumps a learning task to heavy when it is high-stakes', () async {
      expect(
        await scorer.score(title: 'Study for the exam'),
        DifficultyTier.heavy,
      );
    });

    test(
      'a mechanically-easy chore stays light on its own, but heavy when '
      'it is clearly important for the future',
      () async {
        expect(
          await scorer.score(title: 'Fill in the expense form'),
          DifficultyTier.light,
        );
        expect(
          await scorer.score(title: 'Submit the scholarship application form'),
          DifficultyTier.heavy,
        );
      },
    );

    test('rates quick-action keywords as trivial', () async {
      expect(
        await scorer.score(title: 'Call the dentist'),
        DifficultyTier.trivial,
      );
      expect(await scorer.score(title: 'Buy milk'), DifficultyTier.trivial);
    });

    test('falls back to length when no keyword matches', () async {
      expect(await scorer.score(title: 'Sort it'), DifficultyTier.light);
      expect(
        await scorer.score(
          title: 'Sort out the whole situation with the landlord about parking',
        ),
        DifficultyTier.moderate,
      );
    });

    test('never throws on empty input', () async {
      expect(await scorer.score(title: ''), isA<DifficultyTier>());
    });

    test('considers notes as well as the title', () async {
      expect(
        await scorer.score(title: 'Thing', notes: 'need to write an essay'),
        DifficultyTier.moderate,
      );
    });
  });

  group('PlaceholderTaskDecomposer', () {
    const decomposer = PlaceholderTaskDecomposer();

    test('splits on conjunctions the user actually wrote', () async {
      final result = await decomposer.decompose(
        title: 'Buy milk and post the letter',
      );

      expect(result.usedModel, isTrue);
      expect(result.subtasks.map((s) => s.title), [
        'Buy milk',
        'Post the letter',
      ]);
    });

    test('declines rather than inventing steps for a single action', () async {
      final result = await decomposer.decompose(title: 'Write the report');

      // Fabricating plausible steps would be worse than declining: the
      // user would have to undo them.
      expect(result.subtasks, isEmpty);
      expect(result.usedModel, isFalse);
      expect(result.fallbackReason, contains('no explicit steps'));
    });

    test('falls back rather than truncating when over the cap', () async {
      final result = await decomposer.decompose(
        title: 'One, two, three, four, five, six',
      );

      expect(result.subtasks, isEmpty);
      expect(result.fallbackReason, contains('more than $maxSubtasks'));
    });

    test('accepts exactly maxSubtasks steps', () async {
      final result = await decomposer.decompose(title: 'One, two, three, four');
      expect(result.subtasks, hasLength(maxSubtasks));
    });
  });

  group('PlaceholderSlmExplainer', () {
    const explainer = PlaceholderSlmExplainer();

    test(
      'produces exactly one sentence naming the signal and time bucket',
      () async {
        final text = await explainer.explain(
          signalZScores: const {'app_switches': 3.1},
          topSignal: 'app_switches',
          timeBucket: 'Tuesday afternoon',
        );

        expect(
          text,
          "You've been switching apps more than usual, compared to your usual Tuesday afternoon.",
        );
      },
    );

    test('appends at most one context clause', () async {
      final text = await explainer.explain(
        signalZScores: const {'unlocks': 2.0},
        topSignal: 'unlocks',
        timeBucket: 'Monday morning',
        contextBullets: const [
          ContextBullet(source: 'todo', text: 'a report due at 5pm'),
          ContextBullet(source: 'todo', text: 'a second thing'),
        ],
      );

      expect(text, contains('a report due at 5pm'));
      // Up to two upcoming items are now included, not just the first.
      expect(text, contains('a second thing'));
    });

    test('reports a negative z-score as lower, not higher', () async {
      final text = await explainer.explain(
        signalZScores: const {'unlocks': -1.4},
        topSignal: 'unlocks',
        timeBucket: 'Sunday evening',
      );
      expect(
        text,
        "You've been unlocking your phone less than usual, compared to your usual Sunday evening.",
      );
    });

    test('reports a near-zero z-score as about the same, not a direction', () async {
      final text = await explainer.explain(
        signalZScores: const {'unlocks': 0.1},
        topSignal: 'unlocks',
        timeBucket: '',
      );
      expect(text, "You've been unlocking your phone about the same as usual right now.");
    });

    test('includes the recent-activity comparison when given one', () async {
      final text = await explainer.explain(
        signalZScores: const {'unlocks': 1.0},
        topSignal: 'unlocks',
        timeBucket: '',
        recentActivityNote:
            '42.0 unlocks a day over the last 5 days, versus 28.0 a day the 5 days before that',
      );
      expect(text, contains('42.0 unlocks a day'));
    });

    test('handles an unknown signal without producing nonsense', () async {
      final text = await explainer.explain(
        signalZScores: const {},
        topSignal: 'something_new',
        timeBucket: '',
      );
      // No z-score means no direction to claim — "different from", not
      // a guessed "higher than".
      expect(text, 'Your phone activity has been differently than usual right now.');
    });
  });

  group('PlaceholderEmbeddingService', () {
    const embedder = PlaceholderEmbeddingService();

    Future<Map<int, List<double>>> corpusOf(Map<int, String> texts) async {
      final corpus = <int, List<double>>{};
      for (final e in texts.entries) {
        corpus[e.key] = await embedder.embed(e.value);
      }
      return corpus;
    }

    test('produces a fixed-width vector', () async {
      expect(await embedder.embed('anything'), hasLength(embedder.dimensions));
    });

    test(
      'is deterministic — the same text always embeds identically',
      () async {
        expect(
          await embedder.embed('Gym at 6pm'),
          await embedder.embed('Gym at 6pm'),
        );
      },
    );

    test('empty text embeds to a zero vector rather than throwing', () async {
      final vector = await embedder.embed('');
      expect(vector, hasLength(embedder.dimensions));
      expect(vector.every((v) => v == 0), isTrue);
    });

    test('shared vocabulary scores higher than unrelated text', () async {
      final gym = await embedder.embed('Gym session in the evening');
      final similar = await embedder.embed('Evening gym plan');
      final unrelated = await embedder.embed('Submarine engineering manual');

      expect(
        cosineSimilarity(gym, similar),
        greaterThan(cosineSimilarity(gym, unrelated)),
      );
    });

    test('ranks the most similar entry first', () async {
      final ids = await embedder.topK(
        query: 'gym evening',
        corpus: await corpusOf({
          1: 'Buy groceries',
          2: 'Gym in the evening',
          3: 'Submarine manual',
        }),
      );
      expect(ids.first, 2);
    });

    test('respects k', () async {
      final ids = await embedder.topK(
        query: 'evening',
        corpus: await corpusOf({
          1: 'Evening one',
          2: 'Evening two',
          3: 'Evening three',
        }),
        k: 2,
      );
      expect(ids, hasLength(2));
    });

    test(
      'skips vectors of a different width, which came from another model',
      () async {
        final ids = await embedder.topK(
          query: 'evening',
          corpus: {1: List<double>.filled(7, 1)},
        );
        expect(
          ids,
          isEmpty,
          reason: 'vectors from a different embedder are not comparable',
        );
      },
    );
  });

  group('cosineSimilarity', () {
    test('is 1 for identical vectors and 0 when either is empty', () {
      expect(cosineSimilarity([1, 2, 3], [1, 2, 3]), closeTo(1, 1e-9));
      expect(cosineSimilarity([0, 0], [1, 1]), 0);
      expect(cosineSimilarity(const [], const []), 0);
    });

    test('is 0 for orthogonal vectors', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0, 1e-9));
    });
  });

  group('PlaceholderOcrService', () {
    test(
      'does not claim high confidence, keeping review a real step',
      () async {
        const ocr = PlaceholderOcrService();
        final result = await ocr.extractText('/any/path.jpg');

        expect(result.text, isNotEmpty);
        expect(result.confidence, lessThan(1.0));
        expect(result.backend, ModelBackend.placeholder);
      },
    );
  });
}
