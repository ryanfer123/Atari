import 'package:atari/core/models/models.dart';
import 'package:atari/core/services/platform/platform_capture_service.dart';
import 'package:atari/core/services/platform/platform_sensing_service.dart';
import 'package:atari/core/services/platform/platform_settings_service.dart';
import 'package:atari/core/services/platform/platform_slm_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Services Tests', () {
    const sensingChannel = MethodChannel('test.com.atari/sensing');
    const slmChannel = MethodChannel('test.com.atari/slm');
    const captureChannel = MethodChannel('test.com.atari/capture');

    test('PlatformSensingService queries native snapshot and permissions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sensingChannel, (MethodCall call) async {
        if (call.method == 'getCurrentSnapshot') {
          return {
            'unlockCount': 10,
            'appSwitchCount': 25,
            'avgNotifLatencyMs': 350.0,
            'windowStartMs': 1700000000000,
            'windowEndMs': 1700000900000,
          };
        }
        if (call.method == 'checkPermissions') {
          return {
            'usageAccess': true,
            'notificationAccess': false,
          };
        }
        return null;
      });

      final service = PlatformSensingService(methodChannel: sensingChannel);
      final snapshot = await service.getCurrentSnapshot(windowMinutes: 15);
      expect(snapshot.unlockCount, 10);
      expect(snapshot.appSwitchCount, 25);
      expect(snapshot.avgNotifLatencyMs, 350.0);

      final perms = await service.checkPermissions();
      expect(perms['usageAccess'], true);
      expect(perms['notificationAccess'], false);
    });

    test('PlatformSlmService deserializes mocked SLM channel replies', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(slmChannel, (MethodCall call) async {
        if (call.method == 'explain') {
          return {
            'text': 'Your app-switching is higher than usual.',
            'contextBullets': [
              {'source': 'todo', 'text': 'Study for exam'}
            ],
            'usedModel': true,
          };
        }
        if (call.method == 'selectSources') {
          return {
            'selectedSources': ['todos', 'notes'],
            'reasoning': 'Prioritised todos and notes',
            'usedModel': true,
          };
        }
        return null;
      });

      final service = PlatformSlmService(methodChannel: slmChannel);
      final event = OverloadEvent(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        signalScores: const {'app_switches': 2.5},
        severity: 2.5,
        topSignal: 'app_switches',
        baselineContext: 'Tuesday afternoon',
      );

      final explanation = await service.generateExplanation(event);
      expect(explanation.sentence, 'Your app-switching is higher than usual.');
      expect(explanation.usedModel, true);

      final selection = await service.selectSources(
        triggerSignal: 'app_switches',
        topSignal: 'app_switches',
      );
      expect(selection.sources, [GoalContextSource.todos, GoalContextSource.notes]);
      expect(selection.usedModel, true);
      expect(await service.isReady(), false);
    });

    test('PlatformCaptureService deserializes a mocked capture reply', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(captureChannel, (MethodCall call) async {
        if (call.method == 'capture') {
          return {
            'rectifiedImagePath': '/data/user/0/com.atari/cache/crop.png',
            'ocrText': 'Assignment Due Tomorrow',
            'ocrConfidence': 0.91,
          };
        }
        return null;
      });

      final service = PlatformCaptureService(methodChannel: captureChannel);
      final result = await service.capture(
        scribblePoints: [{'dx': 10.0, 'dy': 20.0}],
        sourceImagePath: '/path/to/img.png',
        origin: 'camera',
      );

      expect(result.rectifiedImagePath, '/data/user/0/com.atari/cache/crop.png');
      expect(result.ocrText, 'Assignment Due Tomorrow');
      expect(result.ocrConfidence, 0.91);
    });

    test('PlatformSettingsService manages essential apps and offline toggles', () async {
      final service = PlatformSettingsService();
      final apps = await service.getEssentialApps();
      expect(apps.isNotEmpty, true);

      await service.setEssentialApps(['com.atari.focus', 'com.google.calc']);
      final updated = await service.getEssentialApps();
      expect(updated, ['com.atari.focus', 'com.google.calc']);

      expect(await service.isTtsEnabled, true);
      await service.setTtsEnabled(false);
      expect(await service.isTtsEnabled, false);
    });
  });
}
