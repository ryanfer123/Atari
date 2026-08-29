import 'package:flutter/foundation.dart';

@immutable
class CaptureResult {
  final String rectifiedImagePath;
  final String ocrText;
  final double ocrConfidence;

  const CaptureResult({
    required this.rectifiedImagePath,
    required this.ocrText,
    required this.ocrConfidence,
  });
}
