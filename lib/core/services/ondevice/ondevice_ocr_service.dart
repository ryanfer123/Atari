import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../model_services.dart';

/// Real PP-OCRv5 text extraction, over the `atari.dev/models` channel.
///
/// The Kotlin side ([PpOcrEngine]) owns the ONNX sessions and the
/// detection → recognition → CTC-decode pipeline; this is only the
/// boundary.
///
/// Every failure path falls back to [fallback] rather than surfacing an
/// error, because a capture the user just circled must still reach the
/// review screen where they can type the text themselves. The returned
/// [OcrResult.backend] always says which one actually answered, so the
/// UI badge never implies a model ran when it didn't.
class OnDeviceOcrService implements OcrService {
  OnDeviceOcrService({required this.fallback, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/models');

  final MethodChannel _channel;

  /// Used whenever the model can't answer — missing weights, an
  /// undecodable crop, or an image with no text in it.
  final OcrService fallback;

  @override
  ModelBackend get backend => ModelBackend.onDevice;

  /// True when both ONNX files and the charset dictionary are present.
  Future<bool> isReady() async {
    try {
      return await _channel.invokeMethod<bool>('isOcrReady') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OcrResult> extractText(String imagePath) async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('runOcr', {
        'imagePath': imagePath,
      });
      final text = (raw?['text'] as String?)?.trim() ?? '';

      // An empty read is a real outcome — a crop with no text in it —
      // but an empty review screen is useless to the user, so the
      // placeholder still fills it in and the badge stays honest.
      if (text.isEmpty) return await fallback.extractText(imagePath);

      return OcrResult(
        text: text,
        confidence: (raw?['confidence'] as num?)?.toDouble() ?? 0.0,
        backend: ModelBackend.onDevice,
      );
    } catch (e) {
      debugPrint('On-device OCR failed, using the placeholder: $e');
      return fallback.extractText(imagePath);
    }
  }
}
