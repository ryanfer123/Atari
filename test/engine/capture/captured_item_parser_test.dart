import 'package:atari/core/models/captured_item.dart';
import 'package:atari/engine/capture/captured_item_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapturedItemParser', () {
    final fixedNow = DateTime(2026, 8, 20, 10);
    late CapturedItemParser parser;

    setUp(() {
      parser = CapturedItemParser(now: () => fixedNow);
    });

    test('text with no date pattern suggests a note with no deadline', () {
      final item = parser.parse('Grocery list\nMilk\nEggs\nBread');

      expect(item.suggestedType, ItemType.note);
      expect(item.suggestedDeadline, isNull);
      expect(item.suggestedTitle, 'Grocery list');
      expect(item.rawText, 'Grocery list\nMilk\nEggs\nBread');
      expect(item.confidence, 0.6);
    });

    test('title is exactly the first line, even if blank', () {
      final item = parser.parse('\nSecond line is the real content');
      expect(item.suggestedTitle, '');
    });

    test('splits on \\r\\n as well as \\n', () {
      final item = parser.parse('First line\r\nSecond line');
      expect(item.suggestedTitle, 'First line');
    });

    test(
      'a numeric date with no year suggests a todo using the current year',
      () {
        final item = parser.parse('Submit report 8/25');

        expect(item.suggestedType, ItemType.todo);
        expect(item.suggestedDeadline, DateTime(2026, 8, 25));
      },
    );

    test('a numeric date with a 2-digit year resolves to 20YY', () {
      final item = parser.parse('Due 8/25/27');
      expect(item.suggestedDeadline, DateTime(2027, 8, 25));
    });

    test('a numeric date with a 4-digit year is used as-is', () {
      final item = parser.parse('Due 8/25/2030');
      expect(item.suggestedDeadline, DateTime(2030, 8, 25));
    });

    test('a month-name date with no year uses the current year', () {
      final item = parser.parse('Assignment due Aug 25');
      expect(item.suggestedDeadline, DateTime(2026, 8, 25));
    });

    test('a month-name date with a year is used as given', () {
      final item = parser.parse('Assignment due August 25, 2027');
      expect(item.suggestedDeadline, DateTime(2027, 8, 25));
    });

    test('"today" resolves to the current date with no time component', () {
      final item = parser.parse('Pay rent today');
      expect(item.suggestedDeadline, DateTime(2026, 8, 20));
    });

    test('"tomorrow" resolves to one day after the current date', () {
      final item = parser.parse('Call back tomorrow');
      expect(item.suggestedDeadline, DateTime(2026, 8, 21));
    });

    test('a trailing 24-hour time is combined with the detected date', () {
      final item = parser.parse('Standup 8/25 15:00');
      expect(item.suggestedDeadline, DateTime(2026, 8, 25, 15));
    });

    test('a trailing 12-hour PM time is converted correctly', () {
      final item = parser.parse('Standup 8/25 3:00pm');
      expect(item.suggestedDeadline, DateTime(2026, 8, 25, 15));
    });

    test('12:00am is midnight and 12:00pm is noon', () {
      final midnight = parser.parse('Reset at 8/25 12:00am');
      final noon = parser.parse('Reset at 8/25 12:00pm');

      expect(midnight.suggestedDeadline, DateTime(2026, 8, 25));
      expect(noon.suggestedDeadline, DateTime(2026, 8, 25, 12));
    });

    test(
      'a time pattern with no accompanying date does not suggest a deadline',
      () {
        final item = parser.parse('Call the dentist at 3:00pm');

        expect(item.suggestedType, ItemType.note);
        expect(item.suggestedDeadline, isNull);
      },
    );

    test('an out-of-range date (e.g. month 13) is rejected, falling back to a note', () {
      final item = parser.parse('Reference code 13/45');

      expect(item.suggestedType, ItemType.note);
      expect(item.suggestedDeadline, isNull);
    });

    test('an invalid calendar date (e.g. Feb 30) is rejected rather than silently rolled over', () {
      final item = parser.parse('Due 2/30');

      expect(item.suggestedType, ItemType.note);
      expect(item.suggestedDeadline, isNull);
    });

    test('empty OCR text does not throw', () {
      final item = parser.parse('');
      expect(item.suggestedTitle, '');
      expect(item.suggestedType, ItemType.note);
    });
  });
}
