import 'package:flutter/material.dart';

/// ATARI Cyberpunk / Deep Focus dark theme.
///
/// Premium aesthetic designed for a device-wellness agent: deep slate
/// backgrounds, cyber violet accents, neon emerald status indicators,
/// and crisp geometric typography with high contrast and readable
/// line heights.
class AtariTheme {
  AtariTheme._();

  // ── Palette ──────────────────────────────────────────────────────

  static const deepSlate       = Color(0xFF0B0F19);
  static const surface         = Color(0xFF131B2E);
  static const surfaceHigh     = Color(0xFF1E293B);
  static const surfaceCard     = Color(0xFF1A2332);
  static const borderSubtle    = Color(0xFF2D3B50);

  static const cyberViolet     = Color(0xFF6C63FF);
  static const cyberVioletDim  = Color(0xFF4A44B2);
  static const neonEmerald     = Color(0xFF10B981);
  static const amberAlert      = Color(0xFFF59E0B);
  static const electricCyan    = Color(0xFF38BDF8);
  static const roseWarning     = Color(0xFFF43F5E);

  static const textPrimary     = Color(0xFFE2E8F0);
  static const textSecondary   = Color(0xFF94A3B8);
  static const textMuted       = Color(0xFF64748B);

  // ── Typography ───────────────────────────────────────────────────

  static const _fontFamily = 'sans-serif';

  static const headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const subtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 1.2,
    height: 1.4,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const statNumber = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    height: 1.1,
  );

  // ── Decorations ──────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSubtle, width: 1),
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: surfaceCard.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderSubtle.withValues(alpha: 0.5), width: 1),
  );

  static BoxDecoration accentCardDecoration(Color accent) => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
    boxShadow: [
      BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 2),
    ],
  );

  // ── Buttons ──────────────────────────────────────────────────────

  static ButtonStyle primaryButton({Color? color}) => ElevatedButton.styleFrom(
    backgroundColor: color ?? cyberViolet,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    textStyle: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  );

  static ButtonStyle outlineButton({Color? color}) => OutlinedButton.styleFrom(
    foregroundColor: color ?? cyberViolet,
    side: BorderSide(color: (color ?? cyberViolet).withValues(alpha: 0.5)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  // ── ThemeData ────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepSlate,
    canvasColor: deepSlate,
    cardColor: surfaceCard,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: cyberViolet,
      secondary: neonEmerald,
      error: roseWarning,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: deepSlate,
      foregroundColor: textPrimary,
      elevation: 0,
      titleTextStyle: title,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: cyberViolet,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: headline,
      titleLarge: title,
      titleSmall: subtitle,
      bodyLarge: body,
      bodySmall: bodySmall,
      labelSmall: caption,
    ),
  );
}
