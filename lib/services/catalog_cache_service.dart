import 'package:flutter/foundation.dart';

import '../utils/movie_catalog_utils.dart';
import 'local_db_service.dart';

/// Persists last-good Laravel API catalogue snapshots in sqflite.
class CatalogCacheService {
  CatalogCacheService._();

  static const moviesKey = 'api_movies';
  static const theatresKey = 'api_theatres';
  static const showtimesKey = 'api_showtimes';

  static List<Map<String, dynamic>> _sanitize(
    List<Map<String, dynamic>> movies,
  ) {
    return movies
        .map((m) => MovieCatalogUtils.normalizeCustomerMovie(m))
        .toList();
  }

  static Future<void> saveMovies(List<Map<String, dynamic>> movies) async {
    await LocalDbService.writeMovieCache(moviesKey, _sanitize(movies));
    debugPrint('💾 CATALOG CACHE - saved ${movies.length} movies');
  }

  static Future<void> saveTheatres(List<Map<String, dynamic>> theatres) async {
    await LocalDbService.writeMovieCache(theatresKey, theatres);
    debugPrint('💾 CATALOG CACHE - saved ${theatres.length} theatres');
  }

  static Future<void> saveShowtimes(List<Map<String, dynamic>> showtimes) async {
    await LocalDbService.writeMovieCache(showtimesKey, showtimes);
    debugPrint('💾 CATALOG CACHE - saved ${showtimes.length} showtimes');
  }

  static Future<List<Map<String, dynamic>>?> loadMovies() async {
    final cached = await LocalDbService.readMovieCache(moviesKey);
    if (cached == null) return null;
    return _sanitize(cached);
  }

  static Future<List<Map<String, dynamic>>?> loadTheatres() =>
      LocalDbService.readMovieCache(theatresKey);

  static Future<List<Map<String, dynamic>>?> loadShowtimes() =>
      LocalDbService.readMovieCache(showtimesKey);

  static Future<bool> hasAnyCachedCatalogue() async {
    final m = await loadMovies();
    final t = await loadTheatres();
    final s = await loadShowtimes();
    return (m != null && m.isNotEmpty) ||
        (t != null && t.isNotEmpty) ||
        (s != null && s.isNotEmpty);
  }
}
