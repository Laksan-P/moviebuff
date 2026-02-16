import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.cinemaGold,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
        secondaryContainer: AppColors.cardGray,
        onSecondaryContainer: AppColors.text,
        tertiaryContainer: AppColors.cardGray,
        onTertiaryContainer: AppColors.text,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primaryBlue),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: _inputDecorationTheme(AppColors.borderGray),
      timePickerTheme: _timePickerTheme(
        backgroundColor: Colors.white,
        textColor: Colors.black,
        dialHandColor: AppColors.primaryBlue,
        dialBackgroundColor: AppColors.surface,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.cinemaGold,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
        secondaryContainer: AppColors.cardGrayDark,
        onSecondaryContainer: AppColors.textDark,
        tertiaryContainer: AppColors.cardGrayDark,
        onTertiaryContainer: AppColors.textDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(AppColors.primaryBlue),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: _inputDecorationTheme(AppColors.borderGrayDark),
      timePickerTheme: _timePickerTheme(
        backgroundColor: AppColors.surfaceDark,
        textColor: Colors.white,
        dialHandColor: AppColors.primaryBlue,
        dialBackgroundColor: AppColors.cardGrayDark,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color color) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color borderColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }

  static TimePickerThemeData _timePickerTheme({
    required Color backgroundColor,
    required Color textColor,
    required Color dialHandColor,
    required Color dialBackgroundColor,
  }) {
    return TimePickerThemeData(
      backgroundColor: backgroundColor,
      hourMinuteTextColor: textColor,
      hourMinuteColor: dialBackgroundColor,
      dayPeriodTextColor: textColor,
      dayPeriodColor: dialBackgroundColor,
      dialHandColor: dialHandColor,
      dialBackgroundColor: dialBackgroundColor,
      dialTextColor: textColor,
      entryModeIconColor: textColor,
      helpTextStyle: GoogleFonts.outfit(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      hourMinuteTextStyle: GoogleFonts.outfit(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      dayPeriodTextStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}
