import '../models/models.dart';

/// Contract for on-device scribble segmentation, dewarp, and OCR extraction.
abstract class ICapturePipelineService {
  /// Processes a freeform scribble on a captured image and returns cropped/OCR'd results.
  Future<CaptureResult> capture({
    required List<Map<String, double>> scribblePoints,
    required String sourceImagePath,
    required String origin, // "camera" | "screenshot"
  });
}
