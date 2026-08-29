import 'dart:ui';
import '../models/capture_result.dart';
import '../models/captured_item.dart';

enum CaptureOrigin { camera, screenshot }

abstract class ICapturePipelineService {
  Future<CaptureResult> capture({
    required List<Offset> scribblePoints,
    required String sourceImagePath,
    required CaptureOrigin origin,
  });
  Future<CapturedItem> parseCapture(CaptureResult result);
}
