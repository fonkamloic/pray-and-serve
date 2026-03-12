import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bgDark = Color(0xFF1A1714);
  static const Color bgCard = Color(0xFF23201B);
  static const Color bgHeader = Color(0xFF211E19);
  static const Color bgInput = Color(0xFF1A1714);
  static const Color bgSubtle = Color(0xFF1E1B17);
  static const Color bgChip = Color(0xFF2A2520);

  static const Color border = Color(0xFF3D3529);
  static const Color borderLight = Color(0xFF2A2520);

  static const Color gold = Color(0xFFC4A469);
  static const Color textPrimary = Color(0xFFE8E0D4);
  static const Color textSecondary = Color(0xFFA89880);
  static const Color textMuted = Color(0xFF8A7D6B);
  static const Color textDim = Color(0xFF6B5F52);

  static const Color green = Color(0xFF7DA87D);
  static const Color greenBg = Color(0xFF1E2A1E);
  static const Color greenText = Color(0xFFA8C4A8);

  static const Color coral = Color(0xFFC4785A);

  static const Color olive = Color(0xFF6B7C6B);
}

class AppTheme {
  static TextStyle get serif => GoogleFonts.cormorantGaramond();
  static TextStyle get sansSerif => GoogleFonts.sourceSans3();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        surface: AppColors.bgCard,
        onPrimary: AppColors.bgDark,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 2,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 1,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.cormorantGaramond(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.gold,
        ),
        bodyLarge: GoogleFonts.sourceSans3(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.sourceSans3(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.sourceSans3(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        labelSmall: GoogleFonts.sourceSans3(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        hintStyle: GoogleFonts.sourceSans3(
          fontSize: 14,
          color: AppColors.textDim,
        ),
        labelStyle: GoogleFonts.sourceSans3(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          textStyle: GoogleFonts.sourceSans3(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }
}
