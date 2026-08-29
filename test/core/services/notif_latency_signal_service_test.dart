import 'package:atari/core/services/notif_latency_signal_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/signals');
  late List<MethodCall> calls;
  late NotifLatencySignalService service;

  setUp(() {
    calls = [];
    service = NotifLatencySignalService(channel: channel);
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

  group('NotifLatencySignalService', () {
    test('hasNotificationAccess returns the platform value', () async {
      mockHandler((call) async => true);
      expect(await service.hasNotificationAccess(), isTrue);
      expect(calls.single.method, 'hasNotificationAccess');
    });

    test(
      'hasNotificationAccess returns false when the platform returns null',
      () async {
        mockHandler((call) async => null);
        expect(await service.hasNotificationAccess(), isFalse);
      },
    );

    test('getLatenciesSince converts native millis to Durations and passes sinceMillis', () async {
      mockHandler((call) async => [1500, 42000]);
      final since = DateTime(2026, 8, 25, 9);

      final latencies = await service.getLatenciesSince(since);

      expect(latencies, [
        const Duration(milliseconds: 1500),
        const Duration(milliseconds: 42000),
      ]);
      expect(calls.single.method, 'getNotifLatenciesSince');
      expect(calls.single.arguments, {
        'sinceMillis': since.millisecondsSinceEpoch,
      });
    });

    test(
      'getLatenciesSince returns an empty list when the platform returns null',
      () async {
        mockHandler((call) async => null);
        expect(await service.getLatenciesSince(DateTime(2026, 8, 25)), isEmpty);
      },
    );

    test(
      'openNotificationAccessSettings invokes the platform method',
      () async {
        mockHandler((call) async => null);
        await service.openNotificationAccessSettings();
        expect(calls.single.method, 'openNotificationAccessSettings');
      },
    );
  });
}
