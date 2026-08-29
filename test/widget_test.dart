import 'package:atari/core/services/app_switch_signal_service.dart';
import 'package:atari/core/services/notif_latency_signal_service.dart';
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
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  const channel = MethodChannel('atari.dev/signals');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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
    },
  );

  testWidgets('shows grant-access buttons when access has not been granted', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
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

  testWidgets('tapping refresh re-queries the platform channel', (
    tester,
  ) async {
    _useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SignalTrackerDebugScreen(
          unlockService: UnlockSignalService(channel: channel),
          appSwitchService: AppSwitchSignalService(channel: channel),
          notifService: NotifLatencySignalService(channel: channel),
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
