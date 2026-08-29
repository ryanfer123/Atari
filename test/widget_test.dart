import 'package:atari/core/services/unlock_signal_service.dart';
import 'package:atari/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'UnlockTrackerDebugScreen loads and displays counts from the platform channel',
    (tester) async {
      await tester.pumpWidget(const DebugHarnessApp());
      await tester.pumpAndSettle();

      expect(find.text('Unlocks today: 1'), findsOneWidget);
      expect(find.text('Total recorded: 1'), findsOneWidget);
      expect(find.text('Background service: running'), findsOneWidget);
    },
  );

  testWidgets('tapping refresh re-queries the platform channel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UnlockTrackerDebugScreen(
          service: UnlockSignalService(channel: channel),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Unlocks today: 1'), findsOneWidget);
  });
}
