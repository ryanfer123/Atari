import 'package:atari/core/services/unlock_signal_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/signals');
  late List<MethodCall> calls;
  late UnlockSignalService service;

  setUp(() {
    calls = [];
    service = UnlockSignalService(channel: channel);
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

  group('UnlockSignalService', () {
    test(
      'getUnlockTimestamps converts native epoch-millis ints to DateTimes',
      () async {
        mockHandler((call) async => [1756108800000, 1756112400000]);

        final timestamps = await service.getUnlockTimestamps();

        expect(calls.single.method, 'getUnlockTimestamps');
        expect(timestamps, [
          DateTime.fromMillisecondsSinceEpoch(1756108800000),
          DateTime.fromMillisecondsSinceEpoch(1756112400000),
        ]);
      },
    );

    test('getUnlockTimestamps returns an empty list when the platform returns null', () async {
      mockHandler((call) async => null);
      expect(await service.getUnlockTimestamps(), isEmpty);
    });

    test(
      'getUnlockCountSince passes sinceMillis and returns the native count',
      () async {
        mockHandler((call) async => 3);
        final since = DateTime(2026, 8, 25, 9);

        final count = await service.getUnlockCountSince(since);

        expect(count, 3);
        expect(calls.single.method, 'getUnlockCountSince');
        expect(calls.single.arguments, {
          'sinceMillis': since.millisecondsSinceEpoch,
        });
      },
    );

    test(
      'getUnlockCountSince returns zero when the platform returns null',
      () async {
        mockHandler((call) async => null);
        expect(await service.getUnlockCountSince(DateTime(2026, 8, 25)), 0);
      },
    );
  });
}
