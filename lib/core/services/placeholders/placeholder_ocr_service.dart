import '../model_services.dart';

/// Deterministic stand-in for the on-device OCR model (PP-OCRv5/6).
///
/// Returns canned, realistic-looking schedule text so the full capture →
/// parse → review → save → reminder flow is demoable and testable with
/// no model on the device. It deliberately does **not** claim high
/// confidence: the review screen must stay a real editing step, not a
/// formality, because real OCR will get things wrong
/// (Plans/IMPLEMENTATION.md §4.6). See `README.md` in this directory.
class PlaceholderOcrService implements OcrService {
  const PlaceholderOcrService({this.cannedText = _defaultCannedText});

  /// Overridable so tests and demo rehearsals can pin an exact string.
  final String cannedText;

  static const _defaultCannedText = 'Submit OS assignment\nDue 5:00pm tomorrow';

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  @override
  Future<OcrResult> extractText(String imagePath) async {
    return OcrResult(
      text: cannedText,
      confidence: 0.6,
      backend: ModelBackend.placeholder,
    );
  }
}
