import 'package:atari/core/services/app_switch_signal_service.dart';
import 'package:atari/core/services/notif_latency_signal_service.dart';
import 'package:atari/core/services/slm_model_config_service.dart';
import 'package:atari/core/services/unlock_signal_service.dart';
import 'package:atari/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// This debug screen's content is taller than the default test viewport,
/// which would otherwise leave the lower sections un-built (Sliver lazily
/// realizes only children within the viewport + cache extent) and
/// invisible to `find.text`. Widen the viewport instead of scrolling.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  const signalsChannel = MethodChannel('atari.dev/signals');
  const slmChannel = MethodChannel('atari.dev/slm');

  void setDefaultMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(signalsChannel, (call) async {
          switch (call.method) {
            case 'getUnlockTimestamps':
              return [1756108800000];
            case 'getUnlockCountSince':
              return 1;
            case 'isCollectionServiceRunning':
              return true;
            case 'hasUsageAccess':
              return true;
            case 'getAppSwitchCountSince':
              return 4;
            case 'hasNotificationAccess':
              return true;
            case 'getNotifLatenciesSince':
              return [1500, 42000];
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(slmChannel, (call) async {
          switch (call.method) {
            case 'getModelPath':
              return null;
            case 'getModelPathStatus':
              return {'status': 'notConfigured'};
            default:
              return null;
          }
        });
  }

  setUp(setDefaultMocks);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(signalsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(slmChannel, null);
  });

  testWidgets(
    'SignalTrackerDebugScreen loads and displays counts from the platform channel',
    (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(const DebugHarnessApp());
      await tester.pumpAndSettle();

      expect(find.text('Background service: running'), findsOneWidget);
      expect(find.text('Unlocks today: 1'), findsOneWidget);
      expect(find.text('Total recorded: 1'), findsOneWidget);
      expect(find.text('Usage access: granted'), findsOneWidget);
      expect(find.text('App switches today: 4'), findsOneWidget);
      expect(find.text('Grant usage access'), findsNothing);
      expect(find.text('Notification access: granted'), findsOneWidget);
      expect(find.text('Notification latencies today: 2'), findsOneWidget);
      expect(find.text('Grant notification access'), findsNothing);
      expect(find.text('Configured path: (none)'), findsOneWidget);
      expect(find.text('No path configured'), findsOneWidget);
    },
  );

  testWidgets('shows grant-access buttons when access has not been granted', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(signalsChannel, (call) async {
          switch (call.method) {
            case 'hasUsageAccess':
              return false;
            case 'hasNotificationAccess':
              return false;
            case 'getUnlockTimestamps':
              return <int>[];
            default:
              return null;
          }
        });

    _useTallViewport(tester);
    await tester.pumpWidget(const DebugHarnessApp());
    await tester.pumpAndSettle();

    expect(find.text('Usage access: NOT granted'), findsOneWidget);
    expect(find.text('Grant usage access'), findsOneWidget);
    // Access wasn't granted, so the counts shouldn't have been queried.
    expect(find.text('App switches today: 0'), findsOneWidget);

    expect(find.text('Notification access: NOT granted'), findsOneWidget);
    expect(find.text('Grant notification access'), findsOneWidget);
    expect(find.text('Notification latencies today: 0'), findsOneWidget);
  });

  testWidgets('displays a configured, valid model path with its size', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(slmChannel, (call) async {
          switch (call.method) {
            case 'getModelPath':
              return '/sdcard/Android/data/com.atari.atari/files/model.gguf';
            case 'getModelPathStatus':
              return {'status': 'looksValid', 'fileSizeBytes': 2097152};
            default:
              return null;
          }
        });

    _useTallViewport(tester);
    await tester.pumpWidget(const DebugHarnessApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Configured path: /sdcard/Android/data/com.atari.atari/files/model.gguf',
      ),
      findsOneWidget,
    );
    expect(find.text('Looks like a valid GGUF file (2.0 MB)'), findsOneWidget);
  });

  testWidgets('setting a model path calls setModelPath and refreshes status', (
    tester,
  ) async {
    final setCalls = <MethodCall>[];
    var status = 'notConfigured';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(slmChannel, (call) async {
          switch (call.method) {
            case 'setModelPath':
              setCalls.add(call);
              status = 'fileNotFound';
              return null;
            case 'getModelPath':
              return status == 'fileNotFound' ? '/tmp/missing.gguf' : null;
            case 'getModelPathStatus':
              return {'status': status};
            default:
              return null;
          }
        });

    _useTallViewport(tester);
    await tester.pumpWidget(const DebugHarnessApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '/tmp/missing.gguf');
    await tester.tap(find.text('Set model path'));
    await tester.pumpAndSettle();

    expect(setCalls.single.arguments, {'path': '/tmp/missing.gguf'});
    expect(find.text('File not found at that path'), findsOneWidget);
  });

  testWidgets('tapping refresh re-queries the platform channel', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SignalTrackerDebugScreen(
          unlockService: UnlockSignalService(channel: signalsChannel),
          appSwitchService: AppSwitchSignalService(channel: signalsChannel),
          notifService: NotifLatencySignalService(channel: signalsChannel),
          slmModelConfigService: SlmModelConfigService(channel: slmChannel),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Unlocks today: 1'), findsOneWidget);
    expect(find.text('App switches today: 4'), findsOneWidget);
    expect(find.text('Notification latencies today: 2'), findsOneWidget);
  });
}
