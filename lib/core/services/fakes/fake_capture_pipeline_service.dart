import 'dart:async';
import 'dart:ui';
import '../i_capture_pipeline_service.dart';
import '../../models/capture_result.dart';
import '../../models/captured_item.dart';

class FakeCapturePipelineService implements ICapturePipelineService {
  @override
  Future<CaptureResult> capture({
    required List<Offset> scribblePoints,
    required String sourceImagePath,
    required CaptureOrigin origin,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const CaptureResult(
      rectifiedImagePath: '/fake/path.png',
      ocrText: 'Buy groceries by 5 PM',
      ocrConfidence: 0.95,
    );
  }

  @override
  Future<CapturedItem> parseCapture(CaptureResult result) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const CapturedItem(
      rawText: 'Buy groceries by 5 PM',
      suggestedType: ItemType.todo,
      suggestedTitle: 'Buy groceries',
      suggestedDeadline: null,
      confidence: 0.88,
    );
  }
}
