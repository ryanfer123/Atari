import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtariTheme {
  // Brand Colors based on iQOO Hackathon
  static const Color primaryYellow = Color(0xFFFACC15); // Vibrant Yellow
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color lightBackground = Color(0xFFF8FAFC); // Very light grey/white
  
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return GoogleFonts.rajdhaniTextTheme(base).copyWith(
      displayLarge: GoogleFonts.orbitron(textStyle: base.displayLarge, color: color, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.orbitron(textStyle: base.displayMedium, color: color, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.orbitron(textStyle: base.displaySmall, color: color, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.orbitron(textStyle: base.headlineLarge, color: color, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.orbitron(textStyle: base.headlineMedium, color: color, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.orbitron(textStyle: base.headlineSmall, color: color, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.orbitron(textStyle: base.titleLarge, color: color, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.rajdhani(textStyle: base.bodyLarge, color: color, fontWeight: FontWeight.w500, fontSize: 18),
      bodyMedium: GoogleFonts.rajdhani(textStyle: base.bodyMedium, color: color, fontWeight: FontWeight.w500, fontSize: 16),
      labelLarge: GoogleFonts.orbitron(textStyle: base.labelLarge, color: color, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: darkBackground, // Pure Black background
      primaryColor: primaryYellow,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: primaryYellow,
        surface: darkSurface,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent, // Prevents Material 3 from adding a yellowish tint on scroll
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)), // Bottom border for scrolling disappearance
        centerTitle: false,
        iconTheme: const IconThemeData(color: primaryYellow),
        titleTextStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.05), // Glassmorphism base
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: primaryYellow.withOpacity(0.5), width: 1), 
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryYellow,
          side: const BorderSide(color: primaryYellow, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Marble White
      primaryColor: primaryYellow,
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        secondary: primaryYellow,
        surface: lightSurface,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.black87),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent, // Prevents Material 3 from adding a yellowish tint on scroll
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 1)), // Bottom border for scrolling disappearance
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: GoogleFonts.orbitron(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.1), // Glassmorphism base
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: primaryYellow.withOpacity(0.8), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.black87, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}
