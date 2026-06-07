import 'package:flutter/foundation.dart';

import '../utils/movie_catalog_utils.dart';
import 'local_db_service.dart';

/// Keeps local sqflite favourites in sync with refreshed poster URLs.
/// Does not mutate Laravel CRUD entities.
class MovieCatalogSyncService {
  MovieCatalogSyncService._();

  static Future<void> syncExternalMoviesToLocal() async {
    debugPrint(
      'ℹ️ MOVIE SYNC - External movie list sync is optional enrichment only',
    );
  }

  static Future<void> applyLiveExternalMovies(
    List<Map<String, dynamic>> movies,
  ) async {
    var updated = 0;
    for (final m in movies) {
      final title = m['title']?.toString() ?? '';
      final image = MovieCatalogUtils.effectivePosterUrl(m) ?? '';
      if (title.isEmpty || image.isEmpty) continue;
      await LocalDbService.updateFavoriteImage(title, image);
      updated++;
    }
    debugPrint(
      'ℹ️ MOVIE SYNC - Refreshed favourite posters from $updated external rows',
    );
  }

  static Future<void> clearImageCacheAfterRefresh([
    List<Map<String, dynamic>>? movies,
  ]) async {}
}
