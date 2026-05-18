import 'package:flutter/material.dart';

/// MovieBuff cinematic palette — shared by [AppTheme].
class AppColors {
  AppColors._();

  // Accents
  static const Color primaryBlue = Color(0xFF6B9BD1);
  static const Color primaryBlueDeep = Color(0xFF4A7EB5);
  static const Color cinemaGold = Color(0xFFC9A44A);
  static const Color cinemaGoldMuted = Color(0xFF9A7B2D);

  static const Color success = Color(0xFF3D9A6E);
  static const Color warning = Color(0xFFE3A02A);
  static const Color error = Color(0xFFD85C5C);

  // Glow blobs (non-blurred gradients)
  static const Color glowBlue = Color(0xFF2A4A7A);
  static const Color glowNavy = Color(0xFF0F1B32);

  // Light
  static const Color background = Color(0xFFF3F5F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F6);
  static const Color text = Color(0xFF0F1729);
  static const Color textMuted = Color(0xFF5C6B80);
  static const Color borderLight = Color(0xFFC8D4E3);
  static const Color headerLight = Color(0xFF0E1628);

  // Dark — cinematic depth
  static const Color backgroundDark = Color(0xFF050810);
  static const Color surfaceDark = Color(0xFF0C121F);
  static const Color surfaceElevatedDark = Color(0xFF131B2E);
  static const Color textDark = Color(0xFFF4F6FA);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF2A3A52);

  // Glass tint overlays (used without blur on dense lists)
  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0x33141824);

  // Seat (unchanged semantics)
  static const Color seatAvailable = Colors.white;
  static const Color seatSelected = Color(0xFF020617);
  static const Color seatBooked = Color(0xFFE2E8F0);
  static const Color seatBorder = Color(0xFFCBD5E1);
  static const Color seatAvailableDark = Color(0xFF1F2937);
  static const Color seatSelectedDark = cinemaGold;
  static const Color seatBookedDark = Color(0xFF374151);
  static const Color seatBorderDark = Color(0xFF4B5563);

  // Booking / payment highlights
  static const Color bookingSummaryBackground = Color(0xFF5A85B8);
  static const Color bookingSummaryBackgroundDark = Color(0xFF152238);
  static const Color paymentButton = Color(0xFF0E7490);
  static const Color paymentButtonDark = cinemaGold;
}
