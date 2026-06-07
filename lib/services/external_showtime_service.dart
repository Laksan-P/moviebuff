import 'package:flutter/foundation.dart';

import '../utils/movie_catalog_utils.dart';
import 'showtime_service.dart';

/// Generated showtimes for external JSON / offline movies only.
/// Not stored in Laravel — used for SQLite booking demonstration.
class ExternalShowtimeService {
  ExternalShowtimeService._();

  static const List<String> dailySlots = [
    '10:00 AM',
    '01:00 PM',
    '04:00 PM',
    '07:00 PM',
  ];

  static String _isoDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Builds showtimes for one external JSON movie (next 7 days × 4 slots).
  static List<Map<String, dynamic>> forMovie(Map<String, dynamic> movie) {
    if (!MovieCatalogUtils.isExternalJsonMovie(movie)) return [];

    final title = movie['title']?.toString() ?? 'Movie';
    final movieId =
        movie['movieId']?.toString() ?? MovieCatalogUtils.externalMovieId(title);
    final price = MovieCatalogUtils.priceFromMovie(movie);
    final theatre = MovieCatalogUtils.defaultExternalTheatre;
    final format = (movie['formats'] is List && (movie['formats'] as List).isNotEmpty)
        ? (movie['formats'] as List).first.toString()
        : '2D';
    final language =
        (movie['languages'] is List && (movie['languages'] as List).isNotEmpty)
            ? (movie['languages'] as List).first.toString()
            : 'English';

    final now = DateTime.now();
    final out = <Map<String, dynamic>>[];

    for (var day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      final dateStr = _isoDate(date);
      for (var slot = 0; slot < dailySlots.length; slot++) {
        final time = dailySlots[slot];
        if (day == 0) {
          // Skip slots already passed today.
          // ShowtimeService.isShowtimePassed handles same-day past times.
        }
        out.add({
          'id': 'ext-$movieId-$dateStr-$slot',
          'movie_id': movieId,
          'movieId': movieId,
          'movie': title,
          'theatre': theatre,
          'date': dateStr,
          'time': time,
          'price': price,
          'format': format,
          'language': language,
          'source': MovieCatalogUtils.catalogSourceExternalJson,
          'label': format,
        });
      }
    }

    final visible = out
        .where(
          (st) => !ShowtimeService.isShowtimePassed(
            st['time']?.toString() ?? '',
            st['date']?.toString() ?? '',
          ),
        )
        .toList();

    debugPrint(
      '🎟️ EXTERNAL SHOWTIMES - $title → ${visible.length} upcoming slots',
    );
    return visible;
  }

}
