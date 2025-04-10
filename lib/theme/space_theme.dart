import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpaceTheme {
  // Primary Colors
  static const Color deepSpaceNavy = Color(0xFF0B1026);
  static const Color cosmicPurple = Color(0xFF4A1E9E);
  static const Color nebulaPink = Color(0xFFFF4E8A);
  
  // Secondary Colors
  static const Color starlightSilver = Color(0xFFE0E7FF);
  static const Color asteroidGray = Color(0xFF3D4663);
  static const Color pulsarBlue = Color(0xFF00D1FF);
  
  // Accent Colors
  static const Color marsRed = Color(0xFFFF5757);
  static const Color saturnGold = Color(0xFFFFB800);
  static const Color auroraGreen = Color(0xFF39D98A);
  
  // Gradients
  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
      background: deepSpaceNavy,
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
      fillColor: asteroidGray.withOpacity(0.3),
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
      hintStyle: textTheme.bodyMedium?.copyWith(color: starlightSilver.withOpacity(0.5)),
    ),
    cardTheme: CardTheme(
      color: asteroidGray.withOpacity(0.3),
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
