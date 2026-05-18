import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.surface,
      onSurface: AppColors.text,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.cinemaGold,
      onSecondary: AppColors.text,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight.withValues(alpha: 0.6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: _inputDecorationTheme(scheme, false),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : AppColors.textMuted,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.text,
        ),
        secondaryLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: scheme.onPrimary,
        ),
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        checkmarkColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      iconTheme: IconThemeData(color: AppColors.text.withValues(alpha: 0.85)),
      timePickerTheme: _timePickerTheme(
        backgroundColor: AppColors.surface,
        textColor: AppColors.text,
        dialHandColor: AppColors.primaryBlue,
        dialBackgroundColor: AppColors.surfaceMuted,
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.cinemaGold,
      onSecondary: AppColors.backgroundDark,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDark.withValues(alpha: 0.7),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primaryBlue,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevatedDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: _inputDecorationTheme(scheme, true),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevatedDark,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.textDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        elevation: 12,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : AppColors.textMutedDark,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
      ),
      iconTheme: IconThemeData(color: AppColors.textDark.withValues(alpha: 0.9)),
      timePickerTheme: _timePickerTheme(
        backgroundColor: AppColors.surfaceElevatedDark,
        textColor: AppColors.textDark,
        dialHandColor: AppColors.primaryBlue,
        dialBackgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadowColor: Colors.transparent,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    ColorScheme scheme,
    bool isDark,
  ) {
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.14) : scheme.outline;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : scheme.surface.withValues(alpha: 0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.outfit(
        color: scheme.onSurface.withValues(alpha: 0.38),
        fontSize: 15,
      ),
      labelStyle: GoogleFonts.outfit(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85)),
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
