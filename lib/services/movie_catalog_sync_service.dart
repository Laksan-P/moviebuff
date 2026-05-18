import 'package:flutter/widgets.dart';

import '../utils/movie_catalog_utils.dart';
import 'local_db_service.dart';
import 'movie_service.dart';

/// Applies live external JSON into local persistence and image cache.
class MovieCatalogSyncService {
  MovieCatalogSyncService._();

  static String? _posterUrl(Map<String, dynamic> m) =>
      MovieCatalogUtils.effectivePosterUrl(m);

  static void _alignImageAndPoster(Map<String, dynamic> m) {
    final url = _posterUrl(m);
    if (url != null && url.isNotEmpty) {
      m['image'] = url;
      m['posterUrl'] = url;
    }
  }

  static int _findMovieIndex(
    List<Map<String, dynamic>> movies,
    Map<String, dynamic> incoming,
  ) {
    final id = incoming['id']?.toString().trim();
    if (id != null && id.isNotEmpty && id != 'null') {
      final byId = movies.indexWhere((m) => m['id']?.toString().trim() == id);
      if (byId != -1) return byId;
    }
    final title = (incoming['title']?.toString() ?? '').trim().toLowerCase();
    if (title.isEmpty) return -1;
    return movies.indexWhere(
      (m) => (m['title']?.toString() ?? '').trim().toLowerCase() == title,
    );
  }

  /// Upserts live JSON rows into [MovieService] and favorite poster columns.
  static Future<void> applyLiveExternalMovies(
    List<Map<String, dynamic>> liveMovies,
  ) async {
    if (liveMovies.isEmpty) return;

    final movies = await MovieService.getMovies();
    var upserts = 0;
    var imageUpdates = 0;

    for (final raw in liveMovies) {
      final incoming = Map<String, dynamic>.from(raw);
      _alignImageAndPoster(incoming);

      final title = incoming['title']?.toString() ?? '';
      if (title.trim().isEmpty) continue;

      final idx = _findMovieIndex(movies, incoming);
      if (idx == -1) {
        incoming['_externalSynced'] = true;
        movies.add(incoming);
        upserts++;
        debugPrint(
          'MOVIE UPSERTED: $title + ${_posterUrl(incoming) ?? 'no image'}',
        );
        continue;
      }

      final existing = movies[idx];
      if (existing['_adminLocal'] == true) {
        debugPrint('MOVIE UPSERT SKIPPED (admin local): $title');
        continue;
      }

      final oldUrl = _posterUrl(existing) ?? '';
      final newUrl = _posterUrl(incoming) ?? '';

      final merged = Map<String, dynamic>.from(existing);
      for (final entry in incoming.entries) {
        if (entry.key == '_adminLocal') continue;
        merged[entry.key] = entry.value;
      }
      _alignImageAndPoster(merged);
      merged['_externalSynced'] = true;
      movies[idx] = merged;
      upserts++;

      debugPrint(
        'MOVIE UPSERTED: $title + ${newUrl.isEmpty ? 'no image' : newUrl}',
      );

      if (newUrl.isNotEmpty && oldUrl != newUrl) {
        imageUpdates++;
        debugPrint('MOVIE IMAGE UPDATED: $title $oldUrl -> $newUrl');
        await LocalDbService.updateFavoriteImage(title, newUrl);
      }
    }

    await MovieService.saveMovies(movies);
    debugPrint(
      'ADMIN MOVIES LOADED FROM SYNCED SOURCE: ${liveMovies.length} movies '
      '($upserts upserts, $imageUpdates image updates)',
    );
  }

  /// Clears Flutter image cache after a successful live JSON refresh.
  static Future<void> clearImageCacheAfterRefresh(
    List<Map<String, dynamic>> movies,
  ) async {
    final urls = <String>{};
    for (final m in movies) {
      final u = _posterUrl(m);
      if (u != null && u.startsWith('http')) urls.add(u);
    }

    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();

    for (final url in urls) {
      try {
        await NetworkImage(url).evict();
      } catch (e) {
        debugPrint('🖼️ IMAGE CACHE - evict failed for $url: $e');
      }
    }
    debugPrint(
      '🖼️ IMAGE CACHE - Cleared after live refresh (${urls.length} poster urls)',
    );
  }
}
