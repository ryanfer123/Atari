import 'package:flutter/material.dart';

/// ATARI's visual language — the "Atari" brand look (black/yellow,
/// Orbitron + Rajdhani, glass surfaces), ported from the `frontend`
/// branch's design system so this build gets the same look without
/// pulling in that branch's MVVM scaffold or fake services.
///
/// Deliberately calm about *warning* colour even though the brand
/// accent is bold: the product exists to reduce agitation, so nothing
/// here repurposes red/orange as a motivator. Loss- and urgency-framing
/// is what §4.7's dark-patterns self-audit explicitly forbids — warning
/// colours stay reserved for genuine system state (a permission
/// missing, an overdue deadline the user set themselves), same as
/// before this reskin. The brand yellow is used for identity, not for
/// urgency.
class AppTheme {
  const AppTheme._();

  static const primaryYellow = Color(0xFFFACC15);
  static const _darkBackground = Color(0xFF000000);
  static const _lightBackground = Color(0xFFF8FAFC);
  static const _darkSurface = Color(0xFF1E293B);
  static const _lightSurface = Color(0xFFFFFFFF);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static const _orbitron = 'Orbitron';
  static const _rajdhani = 'Rajdhani';

  /// Orbitron for anything that reads as a heading or label, Rajdhani
  /// for everything else — the same split the frontend branch used, so
  /// the app has one display face and one body face rather than
  /// Material's default per-role mismatch.
  ///
  /// Both are bundled as local font files (`assets/fonts/`) rather than
  /// fetched via the `google_fonts` package, which downloads over the
  /// network on first use — this app makes no network calls at all, so
  /// the fonts ship in the APK like any other asset.
  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    final rajdhani = base.apply(fontFamily: _rajdhani, bodyColor: color, displayColor: color);
    TextStyle? orbitron(TextStyle? style, {FontWeight weight = FontWeight.bold}) =>
        style?.copyWith(fontFamily: _orbitron, color: color, fontWeight: weight);

    return rajdhani.copyWith(
      displayLarge: orbitron(rajdhani.displayLarge),
      displayMedium: orbitron(rajdhani.displayMedium),
      displaySmall: orbitron(rajdhani.displaySmall),
      headlineLarge: orbitron(rajdhani.headlineLarge),
      headlineMedium: orbitron(rajdhani.headlineMedium),
      headlineSmall: orbitron(rajdhani.headlineSmall, weight: FontWeight.w600),
      titleLarge: orbitron(rajdhani.titleLarge, weight: FontWeight.w600),
      titleMedium: orbitron(rajdhani.titleMedium, weight: FontWeight.w600),
      titleSmall: orbitron(rajdhani.titleSmall, weight: FontWeight.w600),
      labelLarge: orbitron(
        rajdhani.labelLarge?.copyWith(letterSpacing: 1.2),
        weight: FontWeight.w600,
      ),
      bodyLarge: rajdhani.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: rajdhani.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final background = isDark ? _darkBackground : _lightBackground;
    final surface = isDark ? _darkSurface : _lightSurface;

    // A full Material 3 tonal palette derived from the brand yellow, so
    // every role the rest of the app already reads off `ColorScheme`
    // (secondaryContainer, tertiaryContainer, outlineVariant, ...) stays
    // yellow-harmonious instead of falling back to Material's default
    // purple — only the roles the brand actually pins down are
    // overridden on top.
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryYellow,
      brightness: brightness,
    ).copyWith(primary: primaryYellow, secondary: primaryYellow, surface: surface);

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    // Yellow reads fine as a border or as text/icons *on* a filled
    // yellow surface (FAB, FilledButton) in either theme — but as bare
    // text or an icon directly on the near-white light background, it's
    // a real contrast problem. The frontend branch's source used black
    // for these roles in light mode specifically; textColor recovers
    // that distinction here instead of yellow everywhere.
    final accentForeground = isDark ? primaryYellow : textColor;

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(base.textTheme, textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: accentForeground),
        titleTextStyle: TextStyle(
          fontFamily: _orbitron,
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryYellow.withValues(alpha: isDark ? 0.4 : 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryYellow.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black,
          // Height only — see the note this replaced: `Size.fromHeight`
          // sets an *infinite* minimum width, which breaks any button
          // placed in a constrained slot such as `ListTile.trailing`.
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentForeground,
          side: BorderSide(color: accentForeground, width: 1.5),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentForeground),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: Colors.black,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

/// Spacing scale — keeps padding consistent without magic numbers
/// scattered through every screen.
class Gap {
  const Gap._();
  static const xs = SizedBox(height: 4, width: 4);
  static const s = SizedBox(height: 8, width: 8);
  static const m = SizedBox(height: 16, width: 16);
  static const l = SizedBox(height: 24, width: 24);
  static const xl = SizedBox(height: 32, width: 32);
}
