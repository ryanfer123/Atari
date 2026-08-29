import '../../core/models/captured_item.dart';

/// Turns raw OCR text (from backend-native's capture pipeline: EdgeSAM crop
/// → DocScanner dewarp → PP-OCRv5/6) into a candidate structured item.
///
/// Deliberately simple heuristics, not a second LLM call — see
/// Plans/IMPLEMENTATION.md §4.6: OCR text already goes through the existing
/// `GoalContext` note pipeline, a dedicated parsing model is out of scope
/// for MVP. The UI always shows the result in an editable review screen
/// before saving — OCR and this heuristic will both be wrong sometimes.
class CapturedItemParser {
  CapturedItemParser({DateTime Function() now = DateTime.now}) : _now = now;

  final DateTime Function() _now;

  /// Matches the hardcoded confidence in the §4.6 skeleton — a fixed
  /// heuristic-confidence marker, not a calibrated probability.
  static const double _heuristicConfidence = 0.6;

  static final RegExp _lineBreak = RegExp(r'\r\n|\r|\n');

  static final RegExp _relativeDayPattern = RegExp(
    r'\b(today|tonight|tomorrow)\b',
    caseSensitive: false,
  );

  // month/day(/year), e.g. "8/25", "08-25-2026".
  static final RegExp _numericDatePattern = RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
  );

  // Month name + day[, year], e.g. "Aug 25", "August 25, 2026".
  static final RegExp _monthNamePattern = RegExp(
    r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+(\d{1,2})(?:,?\s*(\d{4}))?\b',
    caseSensitive: false,
  );

  // e.g. "3:00pm", "15:00".
  static final RegExp _timePattern = RegExp(
    r'\b(\d{1,2}):(\d{2})\s*(am|pm)?\b',
    caseSensitive: false,
  );

  static const Map<String, int> _monthNumbers = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parses [ocrText] into a [CapturedItem]. A date/time pattern found in
  /// the text suggests [ItemType.todo] with that deadline; otherwise
  /// suggests [ItemType.note] with no deadline.
  CapturedItem parse(String ocrText) {
    final deadline = _extractDeadline(ocrText);
    return CapturedItem(
      rawText: ocrText,
      suggestedType: deadline != null ? ItemType.todo : ItemType.note,
      suggestedTitle: ocrText.split(_lineBreak).first,
      suggestedDeadline: deadline,
      confidence: _heuristicConfidence,
    );
  }

  DateTime? _extractDeadline(String text) {
    final date = _extractDate(text);
    if (date == null) return null;

    final time = _extractTime(text);
    if (time == null) return DateTime(date.year, date.month, date.day);
    return DateTime(date.year, date.month, date.day, time.$1, time.$2);
  }

  DateTime? _extractDate(String text) {
    final relative = _relativeDayPattern.firstMatch(text);
    if (relative != null) {
      final now = _now();
      final today = DateTime(now.year, now.month, now.day);
      return relative.group(1)!.toLowerCase() == 'tomorrow'
          ? today.add(const Duration(days: 1))
          : today;
    }

    final monthMatch = _monthNamePattern.firstMatch(text);
    if (monthMatch != null) {
      final month = _monthNumbers[monthMatch.group(1)!.toLowerCase()]!;
      final day = int.parse(monthMatch.group(2)!);
      final yearText = monthMatch.group(3);
      final year = yearText == null ? _now().year : int.parse(yearText);
      return _validDateOrNull(year, month, day);
    }

    final numericMatch = _numericDatePattern.firstMatch(text);
    if (numericMatch != null) {
      final month = int.parse(numericMatch.group(1)!);
      final day = int.parse(numericMatch.group(2)!);
      final yearText = numericMatch.group(3);
      final year = switch (yearText) {
        null => _now().year,
        final y when y.length == 2 => 2000 + int.parse(y),
        final y => int.parse(y),
      };
      return _validDateOrNull(year, month, day);
    }

    return null;
  }

  /// `(hour, minute)` in 24-hour time, or `null` if no time pattern is
  /// found or the matched numbers aren't a valid time.
  (int, int)? _extractTime(String text) {
    final match = _timePattern.firstMatch(text);
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toLowerCase();
    if (minute > 59) return null;

    if (meridiem == null) {
      if (hour > 23) return null;
    } else {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'pm' && hour != 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
    }
    return (hour, minute);
  }

  DateTime? _validDateOrNull(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    // DateTime normalizes overflow (e.g. Feb 30 -> Mar 2) instead of
    // throwing; reject anything that didn't round-trip.
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}
