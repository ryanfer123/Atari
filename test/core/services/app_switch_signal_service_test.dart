import 'package:atari/core/services/app_switch_signal_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/signals');
  late List<MethodCall> calls;
  late AppSwitchSignalService service;

  setUp(() {
    calls = [];
    service = AppSwitchSignalService(channel: channel);
  });

  void mockHandler(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AppSwitchSignalService', () {
    test('hasUsageAccess returns the platform value', () async {
      mockHandler((call) async => true);
      expect(await service.hasUsageAccess(), isTrue);
      expect(calls.single.method, 'hasUsageAccess');
    });

    test(
      'hasUsageAccess returns false when the platform returns null',
      () async {
        mockHandler((call) async => null);
        expect(await service.hasUsageAccess(), isFalse);
      },
    );

    test(
      'getAppSwitchCountSince passes sinceMillis and returns the native count',
      () async {
        mockHandler((call) async => 7);
        final since = DateTime(2026, 8, 25, 9);

        final count = await service.getAppSwitchCountSince(since);

        expect(count, 7);
        expect(calls.single.method, 'getAppSwitchCountSince');
        expect(calls.single.arguments, {
          'sinceMillis': since.millisecondsSinceEpoch,
        });
      },
    );

    test(
      'getAppSwitchCountSince returns zero when the platform returns null',
      () async {
        mockHandler((call) async => null);
        expect(await service.getAppSwitchCountSince(DateTime(2026, 8, 25)), 0);
      },
    );

    test('openUsageAccessSettings invokes the platform method', () async {
      mockHandler((call) async => null);
      await service.openUsageAccessSettings();
      expect(calls.single.method, 'openUsageAccessSettings');
    });
  });
}
