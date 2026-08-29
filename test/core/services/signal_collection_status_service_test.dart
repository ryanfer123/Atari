import 'package:atari/core/services/signal_collection_status_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/signals');
  late SignalCollectionStatusService service;

  setUp(() {
    service = SignalCollectionStatusService(channel: channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SignalCollectionStatusService', () {
    test(
      'isRunning returns true when the platform reports the service is running',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              channel,
              (call) async =>
                  call.method == 'isCollectionServiceRunning' ? true : null,
            );

        expect(await service.isRunning(), isTrue);
      },
    );

    test('isRunning returns false when the platform reports the service is not running', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);

      expect(await service.isRunning(), isFalse);
    });

    test('isRunning returns false when the platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      expect(await service.isRunning(), isFalse);
    });
  });
}
