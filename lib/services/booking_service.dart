import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  static const String _bookingsKey = 'movie_bookings';

  // Unified storage helpers using SharedPreferences
  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    debugPrint('💾 BOOKING STORAGE - Set $key: $value');
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    debugPrint('💾 BOOKING STORAGE - Get $key: $value');
    return value;
  }

  // Save a new booking
  static Future<void> saveBooking(Map<String, dynamic> booking) async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> bookings = jsonDecode(bookingsJson);

    // Add current timestamp for "Booking Date"
    final now = DateTime.now();
    booking['bookingDate'] =
        '${_getMonth(now.month)} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
    booking['status'] = 'Confirmed';
    booking['id'] = DateTime.now().millisecondsSinceEpoch.toString();

    bookings.add(booking);

    final jsonString = jsonEncode(bookings);
    await _setString(_bookingsKey, jsonString);

    // Immediate verification
    final verify = await _getString(_bookingsKey);
    debugPrint(
      '💾 BOOKING STORAGE - Save Status: ${verify == jsonString ? "OK" : "ERROR"}',
    );
  }

  // Get all bookings
  static Future<List<Map<String, dynamic>>> getBookings() async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(bookingsJson);
    return decoded.map((b) => Map<String, dynamic>.from(b)).toList();
  }

  // Request a cancellation (moves to Pending)
  static Future<void> requestCancellation(
    String bookingId,
    String reason,
    String comment,
  ) async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> bookings = jsonDecode(bookingsJson);

    for (var b in bookings) {
      if (b['id'] == bookingId) {
        b['status'] = 'Cancellation Requested';
        b['cancellationReason'] = reason;
        b['cancellationComment'] = comment;
        b['cancellationRequestedDate'] = DateTime.now().toIso8601String();

        // Calculate refund and fee (50/50 rule)
        String rawAmt = b['amount'].toString().replaceAll(
          RegExp(r'[^0-9.]'),
          '',
        );
        double amount = double.tryParse(rawAmt) ?? 0.0;
        b['refundAmount'] = (amount * 0.5).toStringAsFixed(2);
        b['cancellationFee'] = (amount * 0.5).toStringAsFixed(2);
        break;
      }
    }

    await _setString(_bookingsKey, jsonEncode(bookings));
  }

  // Approve a cancellation
  static Future<void> approveCancellation(String bookingId) async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> bookings = jsonDecode(bookingsJson);

    for (var b in bookings) {
      if (b['id'] == bookingId) {
        b['status'] = 'Cancelled';
        b['cancellationApprovedDate'] = DateTime.now().toIso8601String();
        break;
      }
    }

    await _setString(_bookingsKey, jsonEncode(bookings));
  }

  // Reject a cancellation
  static Future<void> rejectCancellation(String bookingId) async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> bookings = jsonDecode(bookingsJson);

    for (var b in bookings) {
      if (b['id'] == bookingId) {
        b['status'] = 'Confirmed'; // Revert to confirmed
        break;
      }
    }

    await _setString(_bookingsKey, jsonEncode(bookings));
  }

  // Legacy cancel (direct to cancelled)
  static Future<void> cancelBooking(String bookingId) async {
    final bookingsJson = await _getString(_bookingsKey) ?? '[]';
    final List<dynamic> bookings = jsonDecode(bookingsJson);

    for (var b in bookings) {
      if (b['id'] == bookingId) {
        b['status'] = 'Cancelled';
        break;
      }
    }

    await _setString(_bookingsKey, jsonEncode(bookings));
  }

  // Get occupied seats for a specific movie/theatre/time
  static Future<List<String>> getBookedSeats(
    String movie,
    String theatre,
    String time,
  ) async {
    final bookings = await getBookings();
    final List<String> occupied = [];

    for (var b in bookings) {
      if (b['movie'] == movie &&
          b['theatre'] == theatre &&
          b['time'] == time &&
          b['status'] == 'Confirmed') {
        final seats = b['seats'] as String;
        occupied.addAll(seats.split(', ').map((e) => e.trim()));
      }
    }

    return occupied;
  }

  static String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
