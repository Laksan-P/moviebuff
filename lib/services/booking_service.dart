import 'package:flutter/foundation.dart';

import '../utils/movie_catalog_utils.dart';
import 'api_mappers.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'offline_booking_service.dart';
import 'showtime_service.dart';

class BookingRefreshNotifier extends ChangeNotifier {
  void notifyBookingsChanged() {
    debugPrint('📑 BOOKINGS - refresh signal');
    notifyListeners();
  }
}

/// Unified bookings: Laravel API (primary) + SQLite offline (supplementary).
class BookingService {
  static final BookingRefreshNotifier refresh = BookingRefreshNotifier();

  static void notifyBookingsChanged() => refresh.notifyBookingsChanged();

  static bool isLocalBooking(Map<String, dynamic> booking) {
    return booking['is_local_booking'] == true ||
        booking['bookingSource'] == MovieCatalogUtils.bookingSourceOffline;
  }

  static Map<String, dynamic> _tagApiBooking(Map<String, dynamic> booking) {
    final row = Map<String, dynamic>.from(booking);
    row['bookingSource'] = MovieCatalogUtils.bookingSourceApi;
    row['sourceBadge'] = 'API Booking';
    row['synced'] = true;
    row['is_local_booking'] = false;
    return row;
  }

  static int _bookingSortKey(Map<String, dynamic> booking) {
    for (final field in ['booking_date', 'created_at']) {
      final iso = booking[field]?.toString() ?? '';
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }

    final label = booking['bookingDate']?.toString() ?? '';
    final labelMatch = RegExp(
      r'^([A-Za-z]{3})\s+(\d{2}),\s+(\d{4})$',
    ).firstMatch(label.trim());
    if (labelMatch != null) {
      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final month = months[labelMatch.group(1)!.toLowerCase()] ?? 1;
      final day = int.tryParse(labelMatch.group(2)!) ?? 1;
      final year = int.tryParse(labelMatch.group(3)!) ?? 1970;
      return DateTime(year, month, day).millisecondsSinceEpoch;
    }

    final id = int.tryParse(booking['id']?.toString() ?? '') ?? 0;
    return id;
  }

  static void _logBookingRow(Map<String, dynamic> booking, {String? stage}) {
    final prefix = stage == null ? '' : '[$stage] ';
    final showtime = booking['showtime']?.toString() ??
        '${booking['date'] ?? ''} ${booking['time'] ?? ''}'.trim();
    debugPrint(
      '${prefix}Booking ${booking['id']} '
      'status=${booking['_api_status'] ?? booking['status']} '
      'offline=${isLocalBooking(booking)} '
      'showtime=$showtime',
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchApiBookings({
    required bool admin,
    required String email,
  }) async {
    try {
      var apiBookings = admin
          ? await ApiService.fetchAllBookings()
          : await ApiService.fetchMyBookings();

      debugPrint(
        'API bookings fetched (raw): ${apiBookings.length} admin=$admin',
      );

      apiBookings = apiBookings.map(_tagApiBooking).toList();

      // /api/bookings is already scoped to the authenticated user.
      // /admin/bookings returns all customers — never filter by logged-in email.
      if (!admin) {
        debugPrint(
          'API email filter skipped (fetchMyBookings is already user-scoped)',
        );
      }

      for (final booking in apiBookings) {
        ApiMappers.logBookingStatus(booking);
        _logBookingRow(booking, stage: 'api');
      }

      return apiBookings;
    } catch (e, st) {
      debugPrint('❌ API BOOKINGS ERROR: $e');
      debugPrint('$st');
      return [];
    }
  }

  /// Merges Laravel API bookings + SQLite offline bookings (newest first).
  static Future<List<Map<String, dynamic>>> getBookings({
    String? userEmail,
    bool admin = false,
  }) async {
    final email =
        userEmail ?? (await AuthService.getUserEmail())?.trim() ?? '';

    if (admin) {
      return _fetchApiBookings(admin: true, email: email);
    }

    final apiBookings = await _fetchApiBookings(admin: false, email: email);
    final offlineBookings =
        await OfflineBookingService.getBookings(userEmail: email);

    debugPrint('API bookings fetched: ${apiBookings.length}');
    debugPrint('Offline bookings fetched: ${offlineBookings.length}');

    for (final booking in offlineBookings) {
      _logBookingRow(booking, stage: 'offline');
    }

    final allBookings = [...apiBookings, ...offlineBookings]
      ..sort((a, b) => _bookingSortKey(b).compareTo(_bookingSortKey(a)));

    debugPrint('Merged bookings: ${allBookings.length}');

    for (final booking in allBookings) {
      _logBookingRow(booking, stage: 'merged');
      final date = booking['date']?.toString() ?? '';
      final time = booking['time']?.toString() ?? '';
      if (date.isNotEmpty &&
          ShowtimeService.isShowtimePassed(time, date)) {
        debugPrint(
          '  ↳ past-showtime (not filtered): id=${booking['id']} $date $time',
        );
      }
    }

    return allBookings;
  }

  static Future<int> countLocalBookings({String? userEmail}) =>
      OfflineBookingService.count(userEmail: userEmail);

  static Future<int> countAllBookings({String? userEmail}) async {
    final merged = await getBookings(userEmail: userEmail);
    return merged.length;
  }

  /// Routes to SQLite for external JSON; Laravel API otherwise.
  static Future<Map<String, dynamic>> saveBooking(
    Map<String, dynamic> booking, {
    String? clientBookingId,
  }) async {
    if (booking['is_external_json'] == true ||
        booking['booking_source'] ==
            MovieCatalogUtils.catalogSourceExternalJson) {
      return saveLocalBooking(booking);
    }

    final showtimeId = int.parse(
      (booking['showtime_id'] ?? booking['showtimeId']).toString(),
    );
    final seats = booking['seats']?.toString() ?? '';
    final tickets = int.tryParse(booking['tickets']?.toString() ?? '') ??
        seats.split(',').where((s) => s.trim().isNotEmpty).length;

    final created = await ApiService.createBooking(
      showtimeId: showtimeId,
      seats: seats,
      numberOfTickets: tickets,
    );

    final confirmed = await ApiService.confirmBookingPayment(
      int.parse(created['id'].toString()),
      paymentMethod: booking['payment_method']?.toString() ?? 'credit_card',
      cardNumber: booking['card_number']?.toString(),
    );

    notifyBookingsChanged();
    return _tagApiBooking(confirmed);
  }

  static Future<Map<String, dynamic>> saveLocalBooking(
    Map<String, dynamic> booking,
  ) async {
    final saved = await OfflineBookingService.create(booking);
    notifyBookingsChanged();
    return saved;
  }

  static Future<List<Map<String, dynamic>>> reloadBookings({
    String? userEmail,
    bool admin = false,
  }) async {
    final bookings = await getBookings(userEmail: userEmail, admin: admin);
    notifyBookingsChanged();
    return bookings;
  }

  static Future<Map<String, dynamic>> requestCancellation(
    String bookingId,
    String reason,
    String comment, {
    Map<String, dynamic>? booking,
  }) async {
    if (booking != null && isLocalBooking(booking)) {
      await OfflineBookingService.updateStatus(
        int.parse(bookingId),
        'Cancelled',
      );
      final updated = await OfflineBookingService.read(int.parse(bookingId));
      debugPrint('🚫 OFFLINE BOOKING UPDATE id=$bookingId → offline_cancelled');
      notifyBookingsChanged();
      return updated ?? booking;
    }

    final updated = await ApiService.requestCancellation(
      int.parse(bookingId),
      reason: reason,
      comments: comment,
    );
    ApiMappers.logBookingStatus(updated);
    notifyBookingsChanged();
    return updated;
  }

  static Future<void> deleteLocalBooking(String bookingId) async {
    await OfflineBookingService.delete(int.parse(bookingId));
    notifyBookingsChanged();
  }

  static Future<void> approveCancellation(String bookingId) async {
    await ApiService.approveCancellation(int.parse(bookingId));
    notifyBookingsChanged();
  }

  static Future<void> rejectCancellation(String bookingId) async {
    await ApiService.rejectCancellation(int.parse(bookingId));
    notifyBookingsChanged();
  }

  static Future<void> cancelBooking(String bookingId) async {
    await ApiService.requestCancellation(
      int.parse(bookingId),
      reason: 'Cancelled by user',
    );
    notifyBookingsChanged();
  }

  static Future<List<String>> getBookedSeats(
    String movie,
    String theatre,
    String date,
    String time, {
    int? showtimeId,
    bool isExternalJsonShowtime = false,
  }) async {
    if (isExternalJsonShowtime) {
      return _localBookedSeats(movie, theatre, date, time);
    }

    if (showtimeId != null && showtimeId > 0) {
      return ApiService.fetchBookedSeats(showtimeId);
    }

    final showtimes = await ApiService.fetchShowtimes();
    final match = showtimes.where((st) {
      return (st['movie'] ?? '').toString() == movie &&
          (st['theatre'] ?? '').toString() == theatre &&
          (st['date'] ?? '').toString() == date &&
          (st['time'] ?? '').toString() == time;
    }).toList();

    if (match.isEmpty) return [];
    final id = int.parse(match.first['id'].toString());
    return ApiService.fetchBookedSeats(id);
  }

  static Future<List<String>> _localBookedSeats(
    String movie,
    String theatre,
    String date,
    String time,
  ) async {
    final email = (await AuthService.getUserEmail())?.trim() ?? '';
    if (email.isEmpty) return [];

    final bookings = await OfflineBookingService.getBookings(userEmail: email);
    final seats = <String>[];
    for (final b in bookings) {
      if ((b['movie'] ?? '').toString() != movie) continue;
      if ((b['theatre'] ?? '').toString() != theatre) continue;
      if ((b['date'] ?? '').toString() != date) continue;
      if ((b['time'] ?? '').toString() != time) continue;
      if (ApiMappers.isCancelledBooking(b)) continue;
      for (final seat in (b['seats'] ?? '').toString().split(',')) {
        final s = seat.trim();
        if (s.isNotEmpty && !seats.contains(s)) seats.add(s);
      }
    }
    return seats;
  }

  static Future<List<Map<String, dynamic>>> getPendingCancellations() async {
    final pending = await ApiService.fetchPendingCancellations();
    debugPrint(
      '🛠️ BOOKINGS - pending cancellations from API: ${pending.length}',
    );
    for (final booking in pending) {
      ApiMappers.logBookingStatus(booking);
    }
    return pending;
  }
}
