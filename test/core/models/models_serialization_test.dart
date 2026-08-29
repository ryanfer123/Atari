import 'package:atari/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models Serialization Tests', () {
    test('Explanation serializes and deserializes correctly', () {
      final explanation = Explanation(
        sentence: 'Your app-switching is higher than usual.',
        contextBullets: [
          ContextBullet(source: 'todo', text: 'Finish lab report (due 4pm)'),
          ContextBullet(source: 'health', text: 'Steps target: 8000'),
        ],
        generatedAt: DateTime.parse('2026-08-29T12:00:00.000Z'),
        usedModel: true,
      );

      final json = explanation.toJson();
      final reconstructed = Explanation.fromJson(json);

      expect(reconstructed.sentence, explanation.sentence);
      expect(reconstructed.contextBullets.length, 2);
      expect(reconstructed.contextBullets[0].source, 'todo');
      expect(reconstructed.usedModel, true);
    });

    test('CaptureResult serializes and deserializes correctly', () {
      const capture = CaptureResult(
        rectifiedImagePath: '/data/user/0/com.atari/cache/rectified.png',
        ocrText: 'MATH 201 Homework Assignment #4',
        ocrConfidence: 0.94,
      );

      final json = capture.toJson();
      final reconstructed = CaptureResult.fromJson(json);

      expect(reconstructed.rectifiedImagePath, capture.rectifiedImagePath);
      expect(reconstructed.ocrText, capture.ocrText);
      expect(reconstructed.ocrConfidence, capture.ocrConfidence);
    });

    test('SignalSnapshot serializes and deserializes correctly', () {
      final snapshot = SignalSnapshot(
        unlockCount: 14,
        appSwitchCount: 42,
        avgNotifLatencyMs: 420.5,
        windowStart: DateTime.parse('2026-08-29T11:45:00.000Z'),
        windowEnd: DateTime.parse('2026-08-29T12:00:00.000Z'),
      );

      final json = snapshot.toJson();
      final reconstructed = SignalSnapshot.fromJson(json);

      expect(reconstructed.unlockCount, 14);
      expect(reconstructed.appSwitchCount, 42);
      expect(reconstructed.avgNotifLatencyMs, 420.5);
      expect(reconstructed.windowStart.millisecondsSinceEpoch, snapshot.windowStart.millisecondsSinceEpoch);
    });

    test('SourceSelection serializes and deserializes correctly with enum mapping', () {
      const selection = SourceSelection(
        sources: [GoalContextSource.todos, GoalContextSource.healthTargets],
        reasoning: 'Prioritised todos and health based on app_switches',
        usedModel: true,
      );

      final json = selection.toJson();
      final reconstructed = SourceSelection.fromJson(json);

      expect(reconstructed.sources, [GoalContextSource.todos, GoalContextSource.healthTargets]);
      expect(reconstructed.reasoning, selection.reasoning);
      expect(reconstructed.usedModel, true);
    });
  });
}
