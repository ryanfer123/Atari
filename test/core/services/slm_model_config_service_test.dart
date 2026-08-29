import 'package:atari/core/services/slm_model_config_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('atari.dev/slm');
  late List<MethodCall> calls;
  late SlmModelConfigService service;

  setUp(() {
    calls = [];
    service = SlmModelConfigService(channel: channel);
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

  group('SlmModelConfigService', () {
    test('setModelPath passes the path through to the platform', () async {
      mockHandler((call) async => null);
      await service.setModelPath('/sdcard/models/Qwen3-4B-Q4_K_M.gguf');

      expect(calls.single.method, 'setModelPath');
      expect(calls.single.arguments, {
        'path': '/sdcard/models/Qwen3-4B-Q4_K_M.gguf',
      });
    });

    test('getModelPath returns the platform value', () async {
      mockHandler((call) async => '/sdcard/models/Qwen3-4B-Q4_K_M.gguf');
      expect(
        await service.getModelPath(),
        '/sdcard/models/Qwen3-4B-Q4_K_M.gguf',
      );
    });

    test('getModelPath returns null when nothing is configured', () async {
      mockHandler((call) async => null);
      expect(await service.getModelPath(), isNull);
    });

    test(
      'getModelPathStatus maps a looksValid response including file size',
      () async {
        mockHandler(
          (call) async => {'status': 'looksValid', 'fileSizeBytes': 2415919104},
        );

        final result = await service.getModelPathStatus();

        expect(result.status, ModelPathStatus.looksValid);
        expect(result.fileSizeBytes, 2415919104);
      },
    );

    test(
      'getModelPathStatus maps each non-valid status without a file size',
      () async {
        for (final entry in {
          'notConfigured': ModelPathStatus.notConfigured,
          'fileNotFound': ModelPathStatus.fileNotFound,
          'notReadable': ModelPathStatus.notReadable,
          'notGguf': ModelPathStatus.notGguf,
        }.entries) {
          mockHandler((call) async => {'status': entry.key});
          final result = await service.getModelPathStatus();
          expect(result.status, entry.value, reason: entry.key);
          expect(result.fileSizeBytes, isNull, reason: entry.key);
        }
      },
    );

    test('getModelPathStatus falls back to notConfigured for an unrecognized status', () async {
      mockHandler((call) async => {'status': 'somethingUnexpected'});
      final result = await service.getModelPathStatus();
      expect(result.status, ModelPathStatus.notConfigured);
    });
  });
}
