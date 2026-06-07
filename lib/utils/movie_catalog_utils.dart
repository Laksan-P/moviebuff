import 'package:flutter/foundation.dart';

/// Shared helpers for the customer catalogue (external JSON + Laravel API).
class MovieCatalogUtils {
  MovieCatalogUtils._();

  static final Set<String> _loggedPosterFailures = {};
  static final Set<String> _loggedPosterSources = {};

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

  static bool isNetworkPosterUrl(String? url) {
    final t = url?.trim() ?? '';
    return t.startsWith('http://') || t.startsWith('https://');
  }

  static bool isInvalidPosterPath(String? url) {
    final t = url?.trim() ?? '';
    if (t.isEmpty || t == 'null') return true;
    if (t.startsWith('assets/')) return true;
    return !isNetworkPosterUrl(t);
  }

  /// Prefer [image], then [posterUrl]; only returns HTTP(S) URLs.
  static String? effectivePosterUrl(Map<String, dynamic> movie) {
    for (final key in ['image', 'posterUrl']) {
      final raw = movie[key]?.toString().trim();
      if (isNetworkPosterUrl(raw)) return raw;
    }
    return null;
  }

  static List<String> networkPosterCandidates(Map<String, dynamic> movie) {
    final urls = <String>[];
    for (final key in ['image', 'posterUrl']) {
      final raw = movie[key]?.toString().trim();
      if (isNetworkPosterUrl(raw) && !urls.contains(raw)) {
        urls.add(raw!);
      }
    }
    return urls;
  }

  static Map<String, String> buildPosterLookup(
    Iterable<Map<String, dynamic>> movies,
  ) {
    final lookup = <String, String>{};
    for (final movie in movies) {
      final title = movie['title']?.toString().trim().toLowerCase() ?? '';
      final url = effectivePosterUrl(movie);
      if (title.isEmpty || url == null) continue;
      lookup.putIfAbsent(title, () => url);
    }
    return lookup;
  }

  /// Strips invalid poster paths (assets/*, empty, non-http).
  static void stripInvalidPosterFields(Map<String, dynamic> movie) {
    for (final key in ['image', 'posterUrl']) {
      final raw = movie[key]?.toString();
      if (isInvalidPosterPath(raw)) {
        movie.remove(key);
      }
    }
  }

  /// Normalizes a movie map for the customer UI (network poster URLs only).
  static Map<String, dynamic> normalizeCustomerMovie(
    Map<String, dynamic> raw, {
    Map<String, String>? posterLookup,
  }) {
    final m = Map<String, dynamic>.from(raw);
    stripInvalidPosterFields(m);

    var url = effectivePosterUrl(m);
    if (url == null && posterLookup != null) {
      final title = m['title']?.toString().trim().toLowerCase() ?? '';
      url = posterLookup[title];
    }

    if (url != null && isNetworkPosterUrl(url)) {
      m['image'] = url;
      m['posterUrl'] = url;
    } else {
      m.remove('image');
      m.remove('posterUrl');
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

  /// External catalogue first; API titles not present in external stay.
  static List<Map<String, dynamic>> mergeCustomerMovieLists(
    List<Map<String, dynamic>> externalPrimary,
    List<Map<String, dynamic>> localFallback, {
    Map<String, String>? posterLookup,
  }) {
    final lookup = posterLookup ?? buildPosterLookup(externalPrimary);

    final extNorm = externalPrimary
        .map(
          (m) => normalizeCustomerMovie(
            Map<String, dynamic>.from(m),
            posterLookup: lookup,
          ),
        )
        .toList();
    final titles = extNorm
        .map((m) => (m['title']?.toString() ?? '').toLowerCase())
        .toSet();
    final out = List<Map<String, dynamic>>.from(extNorm);
    for (final m in localFallback) {
      final t = (m['title']?.toString() ?? '').toLowerCase();
      if (t.isEmpty || titles.contains(t)) continue;
      out.add(
        normalizeCustomerMovie(
          Map<String, dynamic>.from(m),
          posterLookup: lookup,
        ),
      );
      titles.add(t);
    }
    return out;
  }

  static void logPosterSource(String title, String? imageUrl) {
    final key = '$title|${imageUrl ?? ''}';
    if (!_loggedPosterSources.add(key)) return;
    debugPrint('MOVIE POSTER SOURCE:\n$title\n${imageUrl ?? '(placeholder)'}');
  }

  static void logPosterLoadFailed(
    String title,
    Object? error, {
    String? attemptedUrl,
  }) {
    if (!_loggedPosterFailures.add(title)) return;
    final urlPart =
        attemptedUrl != null ? ' url=$attemptedUrl' : '';
    debugPrint(
      '⚠️ IMAGE LOAD FAILED for movie: $title$urlPart'
      '${error != null ? ' ($error)' : ''}',
    );
  }

  static void logMergedCataloguePosters(List<Map<String, dynamic>> movies) {
    debugPrint('📋 MERGED CATALOGUE POSTERS (${movies.length} movies)');
    for (final m in movies) {
      final title = m['title']?.toString() ?? '?';
      final url = effectivePosterUrl(m);
      debugPrint('MOVIE POSTER SOURCE:\n$title\n${url ?? '(placeholder)'}');
    }
  }

  /// Loose match for linking external JSON theatre names to AppData theatres.
  static bool theatresLooselyMatch(String a, String b) {
    final na = a.toLowerCase().trim();
    final nb = b.toLowerCase().trim();
    if (na.isEmpty || nb.isEmpty) return false;
    return na == nb || na.contains(nb) || nb.contains(na);
  }
}
