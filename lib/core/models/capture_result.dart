import 'package:flutter/foundation.dart';

/// Output of the native on-device capture pipeline (EdgeSAM crop + DocScanner dewarp + PP-OCR).
///
/// See Plans/IMPLEMENTATION.md §4.6 and Plans/frontend_prd.md §4.3.
@immutable
class CaptureResult {
  const CaptureResult({
    required this.rectifiedImagePath,
    required this.ocrText,
    required this.ocrConfidence,
  });

  factory CaptureResult.fromJson(Map<String, dynamic> json) {
    return CaptureResult(
      rectifiedImagePath: json['rectifiedImagePath'] as String? ?? '',
      ocrText: json['ocrText'] as String? ?? '',
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String rectifiedImagePath;
  final String ocrText;
  final double ocrConfidence;

  Map<String, dynamic> toJson() => {
    'rectifiedImagePath': rectifiedImagePath,
    'ocrText': ocrText,
    'ocrConfidence': ocrConfidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptureResult &&
          runtimeType == other.runtimeType &&
          rectifiedImagePath == other.rectifiedImagePath &&
          ocrText == other.ocrText &&
          ocrConfidence == other.ocrConfidence;

  @override
  int get hashCode => Object.hash(rectifiedImagePath, ocrText, ocrConfidence);
}
