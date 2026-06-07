import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'local_db_service.dart';

/// SQLite offline bookings for external JSON movies (supplementary to Laravel API).
///
/// SQLite demonstrates CREATE / READ / UPDATE / DELETE for local booking data.
/// Laravel remains authoritative for API bookings, auth, payments, cancellations.
class OfflineBookingService {
  OfflineBookingService._();

  static Future<List<Map<String, dynamic>>> getBookings({
    String? userEmail,
  }) async {
    final email =
        userEmail ?? (await AuthService.getUserEmail())?.trim() ?? '';
    if (email.isEmpty) return [];

    final rows = await LocalDbService.getBookingsByUser(email);
    debugPrint('🗄️ OFFLINE BOOKINGS - loaded ${rows.length} for $email');
    return rows;
  }

  static Future<int> count({String? userEmail}) async {
    final email =
        userEmail ?? (await AuthService.getUserEmail())?.trim() ?? '';
    if (email.isEmpty) return LocalDbService.countAllBookings();
    return LocalDbService.countBookingsForUser(email);
  }

  static Future<Map<String, dynamic>> create(
    Map<String, dynamic> booking,
  ) async {
    final rowId = await LocalDbService.insertBooking({
      ...booking,
      'status': booking['status']?.toString() ?? 'Confirmed',
      'booking_source': 'sqlite',
    });
    final saved = await LocalDbService.getBookingById(rowId);
    debugPrint('✅ OFFLINE BOOKING CREATE id=$rowId');
    return saved ?? {'id': rowId.toString()};
  }

  static Future<Map<String, dynamic>?> read(int id) =>
      LocalDbService.getBookingById(id);

  /// UPDATE — e.g. Confirmed → Cancelled (offline_cancelled).
  static Future<void> updateStatus(int id, String status) =>
      LocalDbService.updateBookingStatus(id, status);

  /// DELETE — permanently remove offline booking row.
  static Future<void> delete(int id) => LocalDbService.deleteBooking(id);
}
