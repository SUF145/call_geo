import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpaceTheme {
  // Primary Colors
  static const Color deepSpaceNavy = Color(0xFF0F0B30); // Darker purple-blue
  static const Color cosmicPurple = Color(0xFF6A3DE8); // Brighter purple
  static const Color nebulaPink = Color(0xFFFF6B97); // Softer pink

  // Secondary Colors
  static const Color starlightSilver = Color(0xFFFFFFFF); // Pure white for text
  static const Color asteroidGray =
      Color(0xFF2A2550); // Darker purple for cards
  static const Color pulsarBlue = Color(0xFF4F9BFF); // Bright blue for accents

  // Accent Colors
  static const Color marsRed = Color(0xFFFF5757); // Red for alerts
  static const Color saturnGold = Color(0xFFFFAC4B); // Orange for planets
  static const Color auroraGreen = Color(0xFF39D98A); // Green for success

  // Gradients
  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepSpaceNavy, Color(0xFF1E0B40)],
  );

  static const LinearGradient nebulaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cosmicPurple, nebulaPink],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pulsarBlue, auroraGreen],
  );

  // Button Gradients
  static const LinearGradient adminButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A56FF),
      Color(0xFF4A25B5)
    ], // Purple gradient for admin button
  );

  static const LinearGradient userButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F9BFF),
      Color(0xFF2B68E0)
    ], // Blue gradient for user button
  );

  static const LinearGradient actionButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9747FF),
      Color(0xFF7030A0)
    ], // Purple gradient for action buttons
  );

  // Typography
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.rajdhani(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: starlightSilver,
    ),
    displayMedium: GoogleFonts.rajdhani(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: starlightSilver,
    ),
    displaySmall: GoogleFonts.rajdhani(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: starlightSilver,
    ),
    headlineMedium: GoogleFonts.rajdhani(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: starlightSilver,
    ),
    headlineSmall: GoogleFonts.rajdhani(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: starlightSilver,
    ),
    titleLarge: GoogleFonts.rajdhani(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: starlightSilver,
    ),
    bodyLarge: GoogleFonts.montserrat(
      fontSize: 16,
      color: starlightSilver,
    ),
    bodyMedium: GoogleFonts.montserrat(
      fontSize: 14,
      color: starlightSilver,
    ),
    labelLarge: GoogleFonts.rajdhani(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: starlightSilver,
    ),
  );

  // Special numerical font
  static TextStyle orbitronStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = starlightSilver,
  }) {
    return GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Theme data
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: deepSpaceNavy,
    primaryColor: cosmicPurple,
    colorScheme: const ColorScheme.dark(
      primary: cosmicPurple,
      secondary: nebulaPink,
      surface: deepSpaceNavy,
      // Using surface instead of deprecated background
      error: marsRed,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: deepSpaceNavy,
      elevation: 0,
      titleTextStyle: textTheme.headlineMedium,
      iconTheme: const IconThemeData(color: starlightSilver),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cosmicPurple,
        foregroundColor: starlightSilver,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: starlightSilver,
        side: const BorderSide(color: starlightSilver, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor:
          asteroidGray.withAlpha(76), // Using withAlpha instead of withOpacity
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: starlightSilver, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: pulsarBlue, width: 2),
      ),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
          color: starlightSilver
              .withAlpha(128)), // Using withAlpha instead of withOpacity
    ),
    cardTheme: CardTheme(
      color:
          asteroidGray.withAlpha(76), // Using withAlpha instead of withOpacity
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: asteroidGray,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: starlightSilver,
      size: 24,
    ),
  );
}
