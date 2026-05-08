import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Green Theme
  static const Color primaryColor = Color(0xFF4ADE80); // Light Green
  static const Color primaryDark = Color(0xFF16A34A); // Darker Green
  static const Color accentColor = Color(0xFF22C55E); 
  static const Color backgroundColor = Color(0xFFF8FAFC); // Very Light Gray/White
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color warningColor = Color(0xFFFACC15);
  static const Color errorColor = Color(0xFFF87171);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );

  static LinearGradient headerGradient = const LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
