import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../i_capture_pipeline_service.dart';
import 'platform_channels.dart';

/// Concrete implementation of [ICapturePipelineService] invoking native EdgeSAM + DocScanner + PP-OCR.
class PlatformCaptureService implements ICapturePipelineService {
  PlatformCaptureService({MethodChannel? methodChannel})
      : _methodChannel = methodChannel ?? PlatformChannels.capture;

  final MethodChannel _methodChannel;

  @override
  Future<CaptureResult> capture({
    required List<Map<String, double>> scribblePoints,
    required String sourceImagePath,
    required String origin,
  }) async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'capture',
        {
          'scribblePoints': scribblePoints,
          'sourceImagePath': sourceImagePath,
          'origin': origin,
        },
      );

      if (result == null) {
        return CaptureResult(
          rectifiedImagePath: sourceImagePath,
          ocrText: '',
          ocrConfidence: 0.0,
        );
      }

      return CaptureResult.fromJson(result);
    } catch (_) {
      return CaptureResult(
        rectifiedImagePath: sourceImagePath,
        ocrText: '',
        ocrConfidence: 0.0,
      );
    }
  }
}
