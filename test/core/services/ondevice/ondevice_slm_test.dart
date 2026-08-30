import 'package:atari/core/models/difficulty_tier.dart';
import 'package:atari/core/models/subtask_spec.dart';
import 'package:atari/core/models/task_tool.dart';
import 'package:atari/core/models/todo.dart';
import 'package:atari/core/services/ondevice/llama_channel.dart';
import 'package:atari/core/services/ondevice/ondevice_difficulty_scorer.dart';
import 'package:atari/core/services/ondevice/ondevice_slm_explainer.dart';
import 'package:atari/core/services/ondevice/ondevice_task_decomposer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the half of the defence-in-depth that a grammar cannot
/// provide: what these services do with output that is well-formed but
/// wrong, and with a model that fails outright.
///
/// The model itself is never loaded — the platform channel is mocked, so
/// these run in CI with no weights present.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/models');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Makes `slmGenerate` return [reply], or throw when it is null.
  void mockGenerate(String? reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'slmGenerate') return null;
      if (reply == null) {
        throw PlatformException(code: 'llama_failed', message: 'no model');
      }
      return reply;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('OnDeviceDifficultyScorer', () {
    test('maps a tier name the grammar allows', () async {
      mockGenerate('heavy');
      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      expect(
        await scorer.score(title: 'Write the dissertation'),
        DifficultyTier.heavy,
      );
    });

    test('tolerates surrounding whitespace and casing', () async {
      mockGenerate('  Moderate\n');
      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      expect(await scorer.score(title: 'Tidy the desk'), DifficultyTier.moderate);
    });

    test('falls back rather than throwing when the model fails', () async {
      mockGenerate(null);
      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      expect(await scorer.score(title: 'Anything'), fallbackDifficultyTier);
    });

    test('falls back on a value outside the enum', () async {
      mockGenerate('impossible');
      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      expect(await scorer.score(title: 'Anything'), fallbackDifficultyTier);
    });

    test('includes nearby-deadline tasks as context, not as the answer', () async {
      String? seenPrompt;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'slmGenerate') return null;
        seenPrompt = (call.arguments as Map)['prompt'] as String;
        return 'moderate';
      });

      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      await scorer.score(
        title: 'Submit the visa application',
        deadline: DateTime(2026, 9, 1),
        nearbyTasks: [
          Todo(
            id: 1,
            title: 'Dentist appointment',
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
      );

      expect(seenPrompt, isNotNull);
      expect(seenPrompt, contains('Also due around then'));
      expect(seenPrompt, contains('Dentist appointment'));
    });

    test('omits the nearby-tasks section when there is nothing to show', () async {
      String? seenPrompt;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'slmGenerate') return null;
        seenPrompt = (call.arguments as Map)['prompt'] as String;
        return 'light';
      });

      const scorer = OnDeviceDifficultyScorer(channel: LlamaChannel());
      await scorer.score(title: 'Water the plants');

      expect(seenPrompt, isNotNull);
      expect(seenPrompt, isNot(contains('Also due around then')));
    });
  });

  group('OnDeviceTaskDecomposer', () {
    const decomposer = OnDeviceTaskDecomposer(channel: LlamaChannel());

    test('parses a well-formed decomposition', () async {
      mockGenerate('''
[{"title":"Draft the outline","minutes":30,"tier":"light","tool":"none"},
 {"title":"Write section one","minutes":90,"tier":"moderate","tool":"startTimer"}]
''');
      final result = await decomposer.decompose(title: 'Write the report');

      expect(result.usedModel, isTrue);
      expect(result.subtasks, hasLength(2));
      expect(
        result.subtasks.first,
        const SubtaskSpec(
          title: 'Draft the outline',
          estimatedMinutes: 30,
          tier: DifficultyTier.light,
        ),
      );
      expect(result.subtasks[1].suggestedTool, TaskTool.startTimer);
    });

    test('drops the whole answer when it exceeds the subtask cap', () async {
      final items = List.generate(
        maxSubtasks + 1,
        (i) => '{"title":"Step $i","minutes":5,"tier":"light","tool":"none"}',
      ).join(',');
      mockGenerate('[$items]');

      final result = await decomposer.decompose(title: 'Overlong');
      // Truncating would hide that the model misread the task.
      expect(result.usedModel, isFalse);
      expect(result.subtasks, isEmpty);
    });

    test('falls back on unparseable output instead of retrying', () async {
      mockGenerate('not json at all');
      final result = await decomposer.decompose(title: 'Anything');
      expect(result.usedModel, isFalse);
      expect(result.fallbackReason, isNotNull);
    });

    test('skips entries with no title, keeping the usable ones', () async {
      mockGenerate(
        '[{"title":"","minutes":5,"tier":"light","tool":"none"},'
        '{"title":"Real step","minutes":5,"tier":"light","tool":"none"}]',
      );
      final result = await decomposer.decompose(title: 'Mixed');
      expect(result.subtasks.map((s) => s.title), ['Real step']);
    });
  });

  group('OnDeviceSlmExplainer', () {
    const explainer = OnDeviceSlmExplainer(channel: LlamaChannel());

    Future<String> explain() => explainer.explain(
      signalZScores: const {'app_switches': 2.4},
      topSignal: 'app_switches',
      timeBucket: 'weekday evening',
    );

    test('passes through a plain descriptive sentence', () async {
      mockGenerate(
        'Your app switching is well above your usual weekday evening pattern.',
      );
      expect(
        await explain(),
        'Your app switching is well above your usual weekday evening pattern.',
      );
    });

    test(
      'accepts a decimal figure and a second sentence — the grammar '
      'these used to be impossible under',
      () async {
        const detailed =
            'You switched apps 50.0 times a day over the last 5 days, '
            'versus 30.0 a day before that. You also have Submit the report '
            'due tomorrow at 5pm.';
        mockGenerate(detailed);
        expect(await explain(), detailed);
      },
    );

    test('rejects advice and uses the deterministic template', () async {
      mockGenerate('You should try to put your phone down for a while.');
      final result = await explain();
      expect(result, isNot(contains('should')));
      expect(result, contains('switching apps'));
    });

    test('rejects anything that reads as a diagnosis', () async {
      mockGenerate('Your app switching suggests anxiety about work.');
      expect(await explain(), isNot(contains('anxiety')));
    });

    test('falls back to the template when the model fails', () async {
      mockGenerate(null);
      expect(await explain(), contains('switching apps'));
    });

    test('includes the recent-activity comparison in the prompt', () async {
      String? seenPrompt;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'slmGenerate') return null;
        seenPrompt = (call.arguments as Map)['prompt'] as String;
        return 'Your app switching is a little above usual lately.';
      });

      await explainer.explain(
        signalZScores: const {'app_switches': 1.2},
        topSignal: 'app_switches',
        timeBucket: '',
        recentActivityNote:
            '50.0 app_switches a day over the last 5 days, versus 30.0 a day the 5 days before that',
      );

      expect(seenPrompt, isNotNull);
      expect(seenPrompt, contains('Recent pattern:'));
      expect(seenPrompt, contains('50.0 app_switches a day'));
    });

    test('describes a negative z-score as below usual, not above', () async {
      String? seenPrompt;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'slmGenerate') return null;
        seenPrompt = (call.arguments as Map)['prompt'] as String;
        return 'Your app switching is calmer than usual.';
      });

      await explainer.explain(
        signalZScores: const {'app_switches': -2.0},
        topSignal: 'app_switches',
        timeBucket: '',
      );

      expect(seenPrompt, contains('less than usual'));
      expect(seenPrompt, isNot(contains('more than usual')));
    });
  });
}
