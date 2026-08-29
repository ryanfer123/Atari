import 'package:flutter/services.dart';

/// Result of validating the configured model path on the native side.
/// Mirrors `ModelPathStatus` in `android/.../SlmModelConfig.kt`.
enum ModelPathStatus {
  notConfigured,
  fileNotFound,
  notReadable,
  notGguf,
  looksValid,
}

class ModelPathStatusResult {
  const ModelPathStatusResult({required this.status, this.fileSizeBytes});

  final ModelPathStatus status;

  /// Only set when [status] is [ModelPathStatus.looksValid].
  final int? fileSizeBytes;
}

/// Dart-side client for `SlmModelConfig` (`android/.../SlmModelConfig.kt`),
/// over the `atari.dev/slm` platform channel.
///
/// Configures which GGUF file the (not-yet-built) on-device SLM runtime
/// should load — path plus a cheap existence/format sanity check, not
/// model loading or inference. See that Kotlin file's doc comment and
/// `native/model/README.md` for the current state of the actual runtime.
class SlmModelConfigService {
  SlmModelConfigService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/slm');

  final MethodChannel _channel;

  Future<void> setModelPath(String path) {
    return _channel.invokeMethod<void>('setModelPath', {'path': path});
  }

  Future<String?> getModelPath() {
    return _channel.invokeMethod<String?>('getModelPath');
  }

  Future<ModelPathStatusResult> getModelPathStatus() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getModelPathStatus',
    );
    final statusName = raw?['status'] as String?;
    final status = ModelPathStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => ModelPathStatus.notConfigured,
    );
    return ModelPathStatusResult(
      status: status,
      fileSizeBytes: raw?['fileSizeBytes'] as int?,
    );
  }
}
