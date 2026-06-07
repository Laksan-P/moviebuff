import 'package:flutter/material.dart';

/// Normalizes Laravel JSON payloads into maps the Flutter UI already expects.
class ApiMappers {
  ApiMappers._();

  static String _httpImageOnly(dynamic value) {
    final url = value?.toString().trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '';
  }

  static Map<String, dynamic> movieFromApi(Map<String, dynamic> raw) {
    final formats = raw['formats'];
    final languages = raw['languages'];
    final image = _httpImageOnly(raw['image']);
    return {
      'id': raw['id'],
      'title': raw['title']?.toString() ?? '',
      'genre': raw['genre']?.toString() ?? 'Action',
      'rating': raw['rating']?.toString() ?? 'PG-13',
      'duration': raw['duration'] ?? 0,
      'image': image,
      'posterUrl': image,
      'description': raw['description']?.toString() ?? '',
      'trailerUrl': raw['trailer_url']?.toString() ?? '',
      'releaseDate': _formatDate(raw['release_date']),
      'formats': _stringList(formats, fallback: const ['2D']),
      'languages': _stringList(languages, fallback: const ['English']),
      'is_active': raw['is_active'] ?? true,
    };
  }

  static Map<String, dynamic> movieToApi(Map<String, dynamic> movie) {
    return {
      if (movie['title'] != null) 'title': movie['title'],
      if (movie['genre'] != null) 'genre': movie['genre'],
      if (movie['rating'] != null) 'rating': movie['rating'],
      if (movie['duration'] != null) 'duration': movie['duration'],
      if (movie['image'] != null) 'image': movie['image'],
      if (movie['posterUrl'] != null && movie['image'] == null)
        'image': movie['posterUrl'],
      if (movie['description'] != null) 'description': movie['description'],
      if (movie['trailerUrl'] != null) 'trailer_url': movie['trailerUrl'],
      if (movie['releaseDate'] != null) 'release_date': movie['releaseDate'],
      if (movie['formats'] != null) 'formats': movie['formats'],
      if (movie['languages'] != null) 'languages': movie['languages'],
      'is_active': movie['is_active'] ?? true,
    };
  }

  static Map<String, dynamic> theatreFromApi(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'name': raw['name']?.toString() ?? '',
      'location': raw['location']?.toString() ?? '',
      'address': raw['location']?.toString() ?? '',
      'total_seats': raw['total_seats'] ?? 0,
      'description': raw['description']?.toString() ?? '',
      'is_active': raw['is_active'] ?? true,
    };
  }

  static Map<String, dynamic> theatreToApi(Map<String, dynamic> theatre) {
    return {
      if (theatre['name'] != null) 'name': theatre['name'],
      if (theatre['location'] != null) 'location': theatre['location'],
      if (theatre['address'] != null && theatre['location'] == null)
        'location': theatre['address'],
      if (theatre['total_seats'] != null) 'total_seats': theatre['total_seats'],
      if (theatre['description'] != null) 'description': theatre['description'],
      'is_active': theatre['is_active'] ?? true,
    };
  }

  static Map<String, dynamic> showtimeFromApi(Map<String, dynamic> raw) {
    final movie = raw['movie'] is Map
        ? Map<String, dynamic>.from(raw['movie'] as Map)
        : null;
    final theatre = raw['theatre'] is Map
        ? Map<String, dynamic>.from(raw['theatre'] as Map)
        : null;

    final dt = _parseDateTime(raw['showtime']);
    final dateStr =
        dt != null ? _isoDate(dt) : (raw['date']?.toString() ?? '');
    final timeStr =
        dt != null ? _formatTime12h(dt) : (raw['time']?.toString() ?? '');

    final movieId = raw['movie_id'] ?? movie?['id'];
    final theatreId = raw['theatre_id'] ?? theatre?['id'];

    return {
      'id': raw['id']?.toString(),
      'movie_id': movieId,
      'movieId': movieId,
      'theatre_id': theatreId,
      'theatreId': theatreId,
      'movie': movie?['title']?.toString() ?? raw['movie']?.toString() ?? '',
      'theatre':
          theatre?['name']?.toString() ?? raw['theatre']?.toString() ?? '',
      'date': dateStr,
      'time': timeStr,
      'format': raw['format']?.toString() ?? '2D',
      'language': raw['language']?.toString() ?? 'English',
      'label': raw['format']?.toString() ?? '2D',
      'price': _parseDouble(raw['ticket_price'] ?? raw['price']) ?? 750.0,
      'available_seats': raw['available_seats'],
      'showtime_iso': dt?.toIso8601String(),
    };
  }

  static Map<String, dynamic> showtimeToApi(Map<String, dynamic> row) {
    final date = row['date']?.toString() ?? '';
    final time = row['time']?.toString() ?? '';
    final showtime = row['showtime_iso']?.toString() ??
        _combineDateAndTime(date, time);

    return {
      if (row['movie_id'] != null) 'movie_id': row['movie_id'],
      if (row['theatre_id'] != null) 'theatre_id': row['theatre_id'],
      if (showtime.isNotEmpty) 'showtime': showtime,
      if (row['price'] != null) 'ticket_price': row['price'],
      if (row['format'] != null) 'format': row['format'],
      if (row['language'] != null) 'language': row['language'],
      if (row['available_seats'] != null)
        'available_seats': row['available_seats'],
    };
  }

  static String bookingCustomerName(Map<String, dynamic> booking) {
    final user = booking['user'];
    if (user is Map) {
      final name = user['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    for (final key in ['customer_name', 'name']) {
      final value = booking[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return 'Unknown Customer';
  }

  static String bookingCustomerEmail(Map<String, dynamic> booking) {
    final user = booking['user'];
    if (user is Map) {
      final email = user['email']?.toString().trim();
      if (email != null && email.isNotEmpty) return email;
    }
    for (final key in ['customer_email', 'email']) {
      final value = booking[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static Map<String, dynamic> bookingFromApi(Map<String, dynamic> raw) {
    final showtime = raw['showtime'] is Map
        ? showtimeFromApi(Map<String, dynamic>.from(raw['showtime'] as Map))
        : null;
    final user = raw['user'] is Map
        ? Map<String, dynamic>.from(raw['user'] as Map)
        : null;
    final cancellation = raw['cancellation'] is Map
        ? Map<String, dynamic>.from(raw['cancellation'] as Map)
        : null;
    final customerName = user?['name']?.toString() ??
        raw['customer_name']?.toString() ??
        raw['name']?.toString() ??
        '';
    final customerEmail = user?['email']?.toString() ??
        raw['customer_email']?.toString() ??
        raw['email']?.toString() ??
        '';

    return {
      'id': raw['id']?.toString(),
      'showtime_id': raw['showtime_id'],
      'name': customerName,
      'email': customerEmail,
      'customer_name': customerName,
      'customer_email': customerEmail,
      if (user != null) 'user': user,
      'movie': showtime?['movie']?.toString() ?? raw['movie']?.toString() ?? '',
      'theatre':
          showtime?['theatre']?.toString() ?? raw['theatre']?.toString() ?? '',
      'date': showtime?['date']?.toString() ?? raw['date']?.toString() ?? '',
      'time': showtime?['time']?.toString() ?? raw['time']?.toString() ?? '',
      'showtime': showtime?['showtime_iso']?.toString() ??
          (showtime != null
              ? '${showtime['date']} ${showtime['time']}'.trim()
              : raw['showtime']?.toString() ?? ''),
      'seats': raw['seats']?.toString() ?? '',
      'amount': (raw['total_price'] ?? raw['amount'])?.toString() ?? '0',
      'tickets':
          (raw['number_of_tickets'] ?? raw['tickets'])?.toString() ?? '1',
      'format': showtime?['format']?.toString() ?? '2D',
      'language': showtime?['language']?.toString() ?? 'English',
      'status': bookingStatusLabel(raw['status']?.toString()),
      'adminStatus': bookingStatusLabel(raw['status']?.toString(), admin: true),
      'bookingDate': _formatDate(raw['booking_date'] ?? raw['created_at']),
      'cancellationReason': cancellation?['reason']?.toString(),
      'cancellationStatus': cancellation?['status']?.toString(),
      'refundAmount': cancellation?['refund_amount']?.toString(),
      'cancellationFee': cancellation?['cancellation_fee']?.toString(),
      '_api_status': raw['status']?.toString(),
    };
  }

  /// Normalizes API snake_case or UI labels to a single status key.
  static String? normalizeBookingStatusKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.toLowerCase().trim().replaceAll(' ', '_');
  }

  /// Resolves the status key used for tabs, badges, and actions.
  static String effectiveBookingStatusKey(Map<String, dynamic> booking) {
    final apiKey = normalizeBookingStatusKey(
      booking['_api_status']?.toString(),
    );
    final fallbackKey = normalizeBookingStatusKey(
      booking['status']?.toString(),
    );
    final key = apiKey ?? fallbackKey ?? 'unknown';

    final cancellationKey = normalizeBookingStatusKey(
      booking['cancellationStatus']?.toString(),
    );
    if (key == 'confirmed' && cancellationKey == 'rejected') {
      return 'rejected';
    }
    return key;
  }

  static void logBookingStatus(Map<String, dynamic> booking) {
    final key = effectiveBookingStatusKey(booking);
    debugPrint('BOOKING STATUS: $key');
  }

  static String bookingStatusLabel(String? status, {bool admin = false}) {
    switch (normalizeBookingStatusKey(status)) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return admin ? 'Pending' : 'Pending Payment';
      case 'cancelled':
        return 'Cancelled';
      case 'cancellation_requested':
        return admin
            ? 'Pending Cancellation Request'
            : 'Cancellation Requested';
      case 'rejected':
        return 'Rejected';
      default:
        return status ?? 'Unknown';
    }
  }

  static String bookingBadgeLabel(Map<String, dynamic> booking) {
    switch (effectiveBookingStatusKey(booking)) {
      case 'confirmed':
      case 'offline_confirmed':
        return 'CONFIRMED';
      case 'cancellation_requested':
        return 'CANCELLATION PENDING';
      case 'cancelled':
      case 'offline_cancelled':
        return 'CANCELLED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'PENDING PAYMENT';
      default:
        return effectiveBookingStatusKey(booking)
            .replaceAll('_', ' ')
            .toUpperCase();
    }
  }

  static String? bookingStatusSubtitle(Map<String, dynamic> booking) {
    switch (effectiveBookingStatusKey(booking)) {
      case 'cancellation_requested':
        return 'Your cancellation request has been sent and is awaiting admin review.';
      case 'rejected':
        return 'Cancellation request rejected by admin.';
      default:
        return null;
    }
  }

  static bool isActiveBooking(Map<String, dynamic> booking) {
    final key = effectiveBookingStatusKey(booking);
    return key == 'confirmed' ||
        key == 'cancellation_requested' ||
        key == 'offline_confirmed' ||
        key == 'pending' ||
        key == 'rejected';
  }

  static bool isCancelledBooking(Map<String, dynamic> booking) {
    final key = effectiveBookingStatusKey(booking);
    return key == 'cancelled' || key == 'offline_cancelled';
  }

  /// API bookings only — offline bookings use local cancel/delete.
  static bool canRequestCancellation(Map<String, dynamic> booking) {
    if (booking['is_local_booking'] == true ||
        booking['bookingSource']?.toString() == 'offline') {
      return false;
    }
    final key = effectiveBookingStatusKey(booking);
    return key == 'confirmed' || key == 'rejected';
  }

  static Color bookingStatusColor(String? status) {
    return bookingStatusColorForKey(normalizeBookingStatusKey(status));
  }

  static Color bookingStatusColorForKey(String? statusKey) {
    switch (statusKey) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'confirmed':
      case 'offline_confirmed':
        return const Color(0xFF15803D);
      case 'cancellation_requested':
        return const Color(0xFFEA580C);
      case 'cancelled':
      case 'offline_cancelled':
        return const Color(0xFFB91C1C);
      case 'rejected':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static List<String> _stringList(
    dynamic value, {
    List<String> fallback = const [],
  }) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return fallback;
  }

  static String _isoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime12h(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')} $period';
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String _combineDateAndTime(String date, String time) {
    if (date.isEmpty) return '';
    try {
      final parts = time.trim().split(' ');
      if (parts.length == 2) {
        final hm = parts[0].split(':');
        var hour = int.parse(hm[0]);
        final minute = int.parse(hm[1]);
        final amPm = parts[1].toUpperCase();
        if (amPm == 'PM' && hour != 12) hour += 12;
        if (amPm == 'AM' && hour == 12) hour = 0;
        final d = DateTime.parse(date);
        return DateTime(d.year, d.month, d.day, hour, minute).toIso8601String();
      }
      return DateTime.parse('$date $time').toIso8601String();
    } catch (_) {
      return date;
    }
  }
}
