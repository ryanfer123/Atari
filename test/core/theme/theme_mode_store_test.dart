import 'package:atari/core/theme/theme_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseThemeMode', () {
    test('round-trips light and dark', () {
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test('tolerates surrounding whitespace', () {
      expect(parseThemeMode('  light\n'), ThemeMode.light);
    });

    test('falls back to dark for empty content', () {
      expect(parseThemeMode(''), ThemeMode.dark);
    });

    test('falls back to dark for unrecognized content', () {
      expect(parseThemeMode('not a theme mode'), ThemeMode.dark);
    });

    test(
      'falls back to dark for "system" -- no longer an offered choice, '
      'even though ThemeMode still defines it',
      () {
        expect(parseThemeMode('system'), ThemeMode.dark);
      },
    );
  });
}
