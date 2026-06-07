import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/config/app_config.dart';
import '../core/data/catalog_architecture.dart';
import 'api_mappers.dart';
import 'catalog_cache_service.dart';
import '../utils/movie_catalog_utils.dart';

class OfflineCatalogBundle {
  const OfflineCatalogBundle({
    required this.movies,
    required this.theatres,
    required this.showtimes,
    required this.source,
    this.message,
  });

  final List<Map<String, dynamic>> movies;
  final List<Map<String, dynamic>> theatres;
  final List<Map<String, dynamic>> showtimes;
  final CatalogueDataSource source;
  final String? message;
}

/// Offline fallback for Laravel API catalogue entities.
class OfflineCatalogService {
  OfflineCatalogService._();

  static Future<OfflineCatalogBundle> loadFallback() async {
    final cachedMovies = await CatalogCacheService.loadMovies();
    final cachedTheatres = await CatalogCacheService.loadTheatres();
    final cachedShowtimes = await CatalogCacheService.loadShowtimes();

    if ((cachedMovies?.isNotEmpty ?? false) ||
        (cachedTheatres?.isNotEmpty ?? false) ||
        (cachedShowtimes?.isNotEmpty ?? false)) {
      debugPrint(
        '📴 OFFLINE CATALOG - using sqflite cache '
        '(movies=${cachedMovies?.length ?? 0}, '
        'theatres=${cachedTheatres?.length ?? 0}, '
        'showtimes=${cachedShowtimes?.length ?? 0})',
      );
      return OfflineCatalogBundle(
        movies: cachedMovies ?? [],
        theatres: cachedTheatres ?? [],
        showtimes: cachedShowtimes ?? [],
        source: CatalogueDataSource.sqfliteCache,
        message: 'Offline — showing last synced Laravel catalogue',
      );
    }

    return _loadBundledAsset();
  }

  static Future<OfflineCatalogBundle> _loadBundledAsset() async {
    debugPrint(
      '📴 OFFLINE CATALOG - loading bundled ${AppConfig.localOfflineCatalogAsset}',
    );
    final raw = await rootBundle.loadString(AppConfig.localOfflineCatalogAsset);
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    final movies = _mapList(map['movies'], ApiMappers.movieFromApi)
        .map((m) => MovieCatalogUtils.normalizeCustomerMovie(m))
        .toList();
    final theatres = _mapList(map['theatres'], ApiMappers.theatreFromApi);
    final showtimes = _mapList(map['showtimes'], ApiMappers.showtimeFromApi);

    return OfflineCatalogBundle(
      movies: movies,
      theatres: theatres,
      showtimes: showtimes,
      source: CatalogueDataSource.localJsonAsset,
      message: 'Offline — showing bundled local JSON catalogue',
    );
  }

  static List<Map<String, dynamic>> _mapList(
    dynamic raw,
    Map<String, dynamic> Function(Map<String, dynamic>) mapper,
  ) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      try {
        out.add(mapper(Map<String, dynamic>.from(item)));
      } catch (e) {
        debugPrint('📴 OFFLINE CATALOG - skip item[$i]: $e');
      }
    }
    return out;
  }
}
