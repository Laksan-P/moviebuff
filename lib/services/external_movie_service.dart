import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import 'local_db_service.dart';

enum MovieSource { network, cache, asset }

class ExternalMoviesResult {
  final List<Map<String, dynamic>> movies;
  final MovieSource source;
  final DateTime? fetchedAt;
  final String? errorMessage;

  ExternalMoviesResult({
    required this.movies,
    required this.source,
    this.fetchedAt,
    this.errorMessage,
  });
}

/// Fetches the master movie list from an external JSON URL on the internet.
/// Order of attempts:
///   1. Network (http.get)         -> success: also persists to sqflite cache
///   2. sqflite cache              -> last good response
///   3. Bundled asset JSON         -> guaranteed offline fallback
class ExternalMovieService {
  static const _cacheKey = 'external_movies';

  static Future<ExternalMoviesResult> fetchMovies({
    bool forceRefresh = false,
  }) async {
    if (!AppConfig.externalMoviesConfigured) {
      debugPrint(
        '🌐 EXTERNAL - URL not configured (${AppConfig.externalMoviesUrl}); '
        'skipping network and using bundled asset.',
      );
      return _loadBundled(
        message: 'External JSON not configured — using bundled offline JSON',
      );
    }

    if (!forceRefresh) {
      debugPrint('🌐 EXTERNAL - Loading from external JSON');
    } else {
      debugPrint('🌐 EXTERNAL - Loading from external JSON (force refresh)');
    }

    try {
      final uri = Uri.parse(AppConfig.externalMoviesUrl);
      final resp = await http.get(uri).timeout(AppConfig.httpTimeout);

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) {
          final list = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          debugPrint(
            '✅ EXTERNAL - Loaded ${list.length} movies from live JSON',
          );
          await LocalDbService.writeMovieCache(_cacheKey, list);
          return ExternalMoviesResult(
            movies: list,
            source: MovieSource.network,
            fetchedAt: DateTime.now(),
          );
        }
        debugPrint('🌐 EXTERNAL - Unexpected payload shape');
      } else {
        debugPrint('🌐 EXTERNAL - Network HTTP ${resp.statusCode}');
      }
    } on TimeoutException {
      debugPrint('🌐 EXTERNAL - Network timeout');
    } catch (e) {
      debugPrint('🌐 EXTERNAL - Network error: $e');
    }

    debugPrint('⚠️ EXTERNAL - Failed, using cache/offline fallback');

    // ---- Fallback 1: sqflite cache ----
    final cached = await LocalDbService.readMovieCache(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      final ts = await LocalDbService.cacheTimestamp(_cacheKey);
      debugPrint('🌐 EXTERNAL - Using sqflite cache (ts: $ts)');
      return ExternalMoviesResult(
        movies: cached,
        source: MovieSource.cache,
        fetchedAt: ts,
        errorMessage: 'Showing cached data (network unavailable)',
      );
    }

    // ---- Fallback 2: bundled asset ----
    return _loadBundled(
      message: 'Offline mode — showing bundled movie list',
    );
  }

  static Future<ExternalMoviesResult> _loadBundled({String? message}) async {
    debugPrint('🌐 EXTERNAL - Falling back to bundled asset JSON');
    final raw = await rootBundle.loadString(AppConfig.localMoviesAsset);
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return ExternalMoviesResult(
      movies: list,
      source: MovieSource.asset,
      errorMessage: message,
    );
  }
}
