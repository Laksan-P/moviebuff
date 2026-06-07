import 'package:flutter/foundation.dart';

import 'api_mappers.dart';
import 'api_service.dart';
import 'showtime_service.dart';

class BookingRefreshNotifier extends ChangeNotifier {
  void notifyBookingsChanged() {
    debugPrint('📑 BOOKINGS - refresh signal');
    notifyListeners();
  }
}

/// Bookings loaded and mutated exclusively through the Laravel API.
class BookingService {
  static final BookingRefreshNotifier refresh = BookingRefreshNotifier();

  static void notifyBookingsChanged() => refresh.notifyBookingsChanged();

  /// Customer UI only — hides bookings whose showtime date/time has passed.
  static bool isPastShowtimeBooking(Map<String, dynamic> booking) {
    final date = booking['date']?.toString().trim() ?? '';
    final time = booking['time']?.toString().trim() ?? '';
    if (date.isEmpty) return false;
    return ShowtimeService.isShowtimePassed(time, date);
  }

  static List<Map<String, dynamic>> _visibleCustomerBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final visible = <Map<String, dynamic>>[];
    var hidden = 0;
    for (final booking in bookings) {
      if (isPastShowtimeBooking(booking)) {
        hidden++;
        debugPrint(
          '📑 BOOKINGS - hidden past showtime id=${booking['id']} '
          '${booking['movie']} ${booking['date']} ${booking['time']}',
        );
        continue;
      }
      visible.add(booking);
    }
    if (hidden > 0) {
      debugPrint('📑 BOOKINGS - hid $hidden past-showtime booking(s)');
    }
    return visible;
  }

  static Future<List<Map<String, dynamic>>> getBookings({
    String? userEmail,
    bool admin = false,
  }) async {
    var bookings = admin
        ? await ApiService.fetchAllBookings()
        : await ApiService.fetchMyBookings();

    for (final booking in bookings) {
      ApiMappers.logBookingStatus(booking);
    }

    if (userEmail != null && userEmail.isNotEmpty && userEmail != 'Unknown') {
      bookings = bookings
          .where(
            (b) =>
                (b['email'] ?? '').toString().toLowerCase() ==
                userEmail.toLowerCase(),
          )
          .toList();
    }

    if (admin) return bookings;
    return _visibleCustomerBookings(bookings);
  }

  static Future<Map<String, dynamic>> saveBooking(
    Map<String, dynamic> booking, {
    String? clientBookingId,
  }) async {
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
    return confirmed;
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
    String comment,
  ) async {
    final updated = await ApiService.requestCancellation(
      int.parse(bookingId),
      reason: reason,
      comments: comment,
    );
    ApiMappers.logBookingStatus(updated);
    debugPrint(
      '🚫 BOOKING CANCEL - booking $bookingId → '
      'status=${updated['_api_status']}',
    );
    notifyBookingsChanged();
    return updated;
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
  }) async {
    if (showtimeId != null) {
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
