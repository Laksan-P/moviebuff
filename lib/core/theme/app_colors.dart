import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color primaryBlue = Color(0xFF6D8DB1);
  static const Color cinemaRed = Color(0xFFDC2626);
  static const Color cinemaGold = Color(0xFFD4AF37);
  static const Color cinemaGoldLight = Color(0xFFE5C158);
  static const Color cinemaGoldDark = Color(0xFFB08D28);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  // Light Mode Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color cardGray = Color(0xFFD1D6D3); // Sage/Grey from screenshot
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color headerBackground = Color(0xFF010B13);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF01080E);
  static const Color surfaceDark = Color(0xFF0A1622);
  static const Color textDark = Color(0xFFF3F4F6);
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color cardGrayDark = Color(
    0xFF1E293B,
  ); // Slate Dark for dark theme visibility
  static const Color borderGrayDark = Color(0xFF334155);

  // Seat Colors
  static const Color seatAvailable = Colors.white;
  static const Color seatSelected = Color(0xFF020617); // Dark from image
  static const Color seatBooked = Color(0xFFE2E8F0); // Light grey
  static const Color seatBorder = Color(0xFFCBD5E1);

  static const Color seatAvailableDark = Color(0xFF1F2937);
  static const Color seatSelectedDark = cinemaGold;
  static const Color seatBookedDark = Color(0xFF374151);
  static const Color seatBorderDark = Color(0xFF4B5563);

  // Booking UI
  static const Color bookingSummaryBackground = Color(
    0xFF6D8DB1,
  ); // Blue from image
  static const Color bookingSummaryBackgroundDark = Color(0xFF1E293B);
  static const Color paymentButton = Color(0xFF0E7490); // Teal from image
  static const Color paymentButtonDark = cinemaGold;
}
