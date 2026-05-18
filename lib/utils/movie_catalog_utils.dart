import 'package:flutter/foundation.dart';

/// Shared helpers for the customer catalogue (external JSON + local seed).
class MovieCatalogUtils {
  MovieCatalogUtils._();

  /// Sri Lankan default when JSON omits theatre/showtimes (MAD II customer flow).
  static const String defaultExternalTheatre =
      'Scope Cinemas Colombo City Centre';

  static const List<String> defaultExternalShowtimes = [
    '10:30 AM',
    '01:30 PM',
    '06:30 PM',
    '09:00 PM',
  ];

  static const double defaultTicketPrice = 750.0;

  /// Prefer [image]; if empty, use [posterUrl].
  static String? effectivePosterUrl(Map<String, dynamic> movie) {
    final img = movie['image']?.toString().trim();
    if (img != null && img.isNotEmpty && img != 'null') return img;
    final p = movie['posterUrl']?.toString().trim();
    if (p != null && p.isNotEmpty && p != 'null') return p;
    return null;
  }

  /// Normalizes a movie map for the customer UI (poster + optional ticketPrice).
  static Map<String, dynamic> normalizeCustomerMovie(
    Map<String, dynamic> raw,
  ) {
    final m = Map<String, dynamic>.from(raw);
    final url = effectivePosterUrl(m);
    if (url != null) {
      m['image'] = url;
      m['posterUrl'] = url;
    }
    return m;
  }

  static double priceFromMovie(Map<String, dynamic> movie) {
    final p = movie['price'] ?? movie['ticketPrice'];
    if (p is num) return p.toDouble();
    if (p is String) {
      final v = double.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (v != null) return v;
    }
    return defaultTicketPrice;
  }

  /// External catalogue first; local seed titles not present in external stay.
  static List<Map<String, dynamic>> mergeCustomerMovieLists(
    List<Map<String, dynamic>> externalPrimary,
    List<Map<String, dynamic>> localFallback,
  ) {
    final extNorm = externalPrimary
        .map((m) => normalizeCustomerMovie(Map<String, dynamic>.from(m)))
        .toList();
    final titles = extNorm
        .map((m) => (m['title']?.toString() ?? '').toLowerCase())
        .toSet();
    final out = List<Map<String, dynamic>>.from(extNorm);
    for (final m in localFallback) {
      final t = (m['title']?.toString() ?? '').toLowerCase();
      if (t.isEmpty || titles.contains(t)) continue;
      out.add(normalizeCustomerMovie(Map<String, dynamic>.from(m)));
      titles.add(t);
    }
    return out;
  }

  /// Loose match for linking external JSON theatre names to AppData theatres.
  static bool theatresLooselyMatch(String a, String b) {
    final na = a.toLowerCase().trim();
    final nb = b.toLowerCase().trim();
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  static void logPosterLoadFailed(String title, Object? error) {
    debugPrint(
      '⚠️ IMAGE LOAD FAILED for movie: $title${error != null ? ' ($error)' : ''}',
    );
  }
}
