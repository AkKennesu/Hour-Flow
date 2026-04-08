import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGravity = Color(0xFF6C63FF); // Deep Purple
  static const Color electricAccent = Color(0xFF00E5FF); // Electric Blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGravity,
        brightness: Brightness.light,
        surface: const Color(0xFFF7F8FA),
        onSurface: Colors.black87,
        primary: primaryGravity,
        secondary: electricAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: primaryGravity.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primaryGravity, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: Colors.black54);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const IconThemeData(color: primaryGravity);
          return const IconThemeData(color: Colors.black54);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGravity,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E2C),
        onSurface: Colors.white,
        primary: primaryGravity,
        secondary: electricAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFF12121A),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primaryGravity.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: Colors.white54);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const IconThemeData(color: primaryGravity);
          return const IconThemeData(color: Colors.white54);
        }),
      ),
    );
  }
}
