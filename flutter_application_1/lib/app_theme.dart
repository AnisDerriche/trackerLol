import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralise toutes les couleurs et styles de l'application.
class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    const primaryColor = Color(0xFF9C27B0); // violet
    const secondaryColor = Color(0xFFE040FB); // violet clair

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: secondaryColor,
      ),
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1D1F33),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0E21),
        elevation: 0,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
    );
  }
}
