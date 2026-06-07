import 'package:flutter/foundation.dart';

import '../core/data/catalog_architecture.dart';
import 'api_service.dart' show ApiException;
import 'catalog_cache_service.dart';
import 'movie_service.dart';
import 'offline_catalog_service.dart';
import 'showtime_service.dart';
import 'theatre_service.dart';

class EntityLoadResult<T> {
  const EntityLoadResult({
    required this.data,
    required this.source,
    this.error,
  });

  final List<T> data;
  final CatalogueDataSource source;
  final String? error;
}

class CoreCatalogueBundle {
  const CoreCatalogueBundle({
    required this.movies,
    required this.theatres,
    required this.showtimes,
    required this.overallSource,
    required this.sourceLabel,
  });

  final List<Map<String, dynamic>> movies;
  final List<Map<String, dynamic>> theatres;
  final List<Map<String, dynamic>> showtimes;
  final CatalogueDataSource overallSource;
  final String sourceLabel;
}

/// Loads core business catalogue with Laravel API as primary source.
class CatalogRepository {
  CatalogRepository._();

  static Future<CoreCatalogueBundle> load({
    required bool isOnline,
    bool forceRefresh = false,
  }) async {
    if (!isOnline) {
      debugPrint('📡 CATALOG REPO - offline; skipping Laravel API');
      final offline = await OfflineCatalogService.loadFallback();
      return CoreCatalogueBundle(
        movies: offline.movies,
        theatres: offline.theatres,
        showtimes: offline.showtimes,
        overallSource: offline.source,
        sourceLabel: _labelFor(offline.source, offline.message),
      );
    }

    final moviesResult = await _loadMovies();
    final theatresResult = await _loadTheatres();
    final showtimesResult = await _loadShowtimes();

    final sources = {
      moviesResult.source,
      theatresResult.source,
      showtimesResult.source,
    };

    final overall = sources.contains(CatalogueDataSource.laravelApi)
        ? CatalogueDataSource.laravelApi
        : sources.contains(CatalogueDataSource.sqfliteCache)
            ? CatalogueDataSource.sqfliteCache
            : sources.contains(CatalogueDataSource.localJsonAsset)
                ? CatalogueDataSource.localJsonAsset
                : CatalogueDataSource.empty;

    final errors = [
      moviesResult.error,
      theatresResult.error,
      showtimesResult.error,
    ].whereType<String>().where((e) => e.isNotEmpty).toList();

    var label = _labelFor(overall, null);
    if (errors.isNotEmpty && overall != CatalogueDataSource.laravelApi) {
      label = '$label · ${errors.first}';
    }

    return CoreCatalogueBundle(
      movies: moviesResult.data,
      theatres: theatresResult.data,
      showtimes: showtimesResult.data,
      overallSource: overall,
      sourceLabel: label,
    );
  }

  static Future<EntityLoadResult<Map<String, dynamic>>> _loadMovies() async {
    try {
      final movies = await MovieService.getMovies();
      await CatalogCacheService.saveMovies(movies);
      return EntityLoadResult(
        data: movies,
        source: CatalogueDataSource.laravelApi,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CATALOG REPO movies API: ${e.message}');
      return _fallbackEntity(await _cachedOrAssetMovies(), e.message);
    } catch (e) {
      debugPrint('❌ CATALOG REPO movies: $e');
      return _fallbackEntity(await _cachedOrAssetMovies(), e.toString());
    }
  }

  static Future<EntityLoadResult<Map<String, dynamic>>> _loadTheatres() async {
    try {
      final theatres = await TheatreService.getTheatres();
      await CatalogCacheService.saveTheatres(theatres);
      return EntityLoadResult(
        data: theatres,
        source: CatalogueDataSource.laravelApi,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CATALOG REPO theatres API: ${e.message}');
      return _fallbackEntity(await _cachedOrAssetTheatres(), e.message);
    } catch (e) {
      debugPrint('❌ CATALOG REPO theatres: $e');
      return _fallbackEntity(await _cachedOrAssetTheatres(), e.toString());
    }
  }

  static Future<EntityLoadResult<Map<String, dynamic>>> _loadShowtimes() async {
    try {
      final showtimes = await ShowtimeService.getShowtimes();
      await CatalogCacheService.saveShowtimes(showtimes);
      return EntityLoadResult(
        data: showtimes,
        source: CatalogueDataSource.laravelApi,
      );
    } on ApiException catch (e) {
      debugPrint('❌ CATALOG REPO showtimes API: ${e.message}');
      return _fallbackEntity(await _cachedOrAssetShowtimes(), e.message);
    } catch (e) {
      debugPrint('❌ CATALOG REPO showtimes: $e');
      return _fallbackEntity(await _cachedOrAssetShowtimes(), e.toString());
    }
  }

  static EntityLoadResult<Map<String, dynamic>> _fallbackEntity(
    ({List<Map<String, dynamic>> data, CatalogueDataSource source}) resolved,
    String? error,
  ) {
    return EntityLoadResult(
      data: resolved.data,
      source: resolved.data.isEmpty
          ? CatalogueDataSource.empty
          : resolved.source,
      error: resolved.data.isEmpty ? error : 'Partial fallback: $error',
    );
  }

  static Future<({List<Map<String, dynamic>> data, CatalogueDataSource source})>
      _cachedOrAssetMovies() async {
    final cached = await CatalogCacheService.loadMovies();
    if (cached != null && cached.isNotEmpty) {
      return (data: cached, source: CatalogueDataSource.sqfliteCache);
    }
    final asset = await OfflineCatalogService.loadFallback();
    return (data: asset.movies, source: asset.source);
  }

  static Future<({List<Map<String, dynamic>> data, CatalogueDataSource source})>
      _cachedOrAssetTheatres() async {
    final cached = await CatalogCacheService.loadTheatres();
    if (cached != null && cached.isNotEmpty) {
      return (data: cached, source: CatalogueDataSource.sqfliteCache);
    }
    final asset = await OfflineCatalogService.loadFallback();
    return (data: asset.theatres, source: asset.source);
  }

  static Future<({List<Map<String, dynamic>> data, CatalogueDataSource source})>
      _cachedOrAssetShowtimes() async {
    final cached = await CatalogCacheService.loadShowtimes();
    if (cached != null && cached.isNotEmpty) {
      return (data: cached, source: CatalogueDataSource.sqfliteCache);
    }
    final asset = await OfflineCatalogService.loadFallback();
    return (data: asset.showtimes, source: asset.source);
  }

  static String _labelFor(CatalogueDataSource source, String? detail) {
    final base = switch (source) {
      CatalogueDataSource.laravelApi => 'Laravel API (live)',
      CatalogueDataSource.sqfliteCache => 'sqflite cache (offline)',
      CatalogueDataSource.localJsonAsset => 'Local JSON asset (offline)',
      CatalogueDataSource.empty => 'No catalogue data',
    };
    if (detail == null || detail.isEmpty) return base;
    return '$base — $detail';
  }
}
