import '../utils/movie_catalog_utils.dart';
import '../utils/theatre_catalog_utils.dart';
import 'admin_catalog_service.dart';
import 'movie_service.dart';
import 'theatre_service.dart';

/// Customer-facing catalogue merge (admin local → external rows → seed fallback).
class CustomerCatalogService {
  CustomerCatalogService._();

  static String primaryMovieKey(Map<String, dynamic> m) {
    final id = m['id']?.toString().trim();
    if (id != null && id.isNotEmpty && id != 'null') return 'id:$id';
    return 't:${AdminCatalogService.normalizeMovieKey(m['title']?.toString())}';
  }

  /// Merge priority: admin-local movies → external list → Sem 1 seed if [externalMovies] empty.
  static Future<List<Map<String, dynamic>>> mergeCustomerMovies(
    List<Map<String, dynamic>> externalMovies,
  ) async {
    final hidden = await AdminCatalogService.hiddenMovieKeys();
    final persisted = await MovieService.getMovies();
    final byTitle = <String, Map<String, dynamic>>{};

    bool allow(Map<String, dynamic> m) {
      final t = AdminCatalogService.normalizeMovieKey(m['title']?.toString());
      return t.isNotEmpty && !hidden.contains(t);
    }

    void putFromAdmin(Map<String, dynamic> m) {
      if (!allow(m)) return;
      final k = AdminCatalogService.normalizeMovieKey(m['title']?.toString());
      byTitle[k] = MovieCatalogUtils.normalizeCustomerMovie(
        Map<String, dynamic>.from(m),
      );
    }

    for (final m in persisted) {
      if (m['_adminLocal'] == true) {
        final copy = Map<String, dynamic>.from(m)..remove('_adminLocal');
        putFromAdmin(copy);
      }
    }

    if (externalMovies.isNotEmpty) {
      for (final raw in externalMovies) {
        final m = Map<String, dynamic>.from(raw);
        if (!allow(m)) continue;
        final k = AdminCatalogService.normalizeMovieKey(m['title']?.toString());
        if (!byTitle.containsKey(k)) {
          byTitle[k] = MovieCatalogUtils.normalizeCustomerMovie(m);
        }
      }
      return byTitle.values.toList();
    }

    for (final m in persisted) {
      if (m['_adminLocal'] == true) continue;
      final copy = Map<String, dynamic>.from(m);
      if (!allow(copy)) continue;
      final k = AdminCatalogService.normalizeMovieKey(copy['title']?.toString());
      if (!byTitle.containsKey(k)) {
        byTitle[k] = MovieCatalogUtils.normalizeCustomerMovie(copy);
      }
    }
    return byTitle.values.toList();
  }

  /// Theatres for customer: admin-local venues → venues from movie rows → Sem 1 fallback.
  static Future<List<Map<String, dynamic>>> mergeCustomerTheatres(
    List<Map<String, dynamic>> mergedMovies,
  ) async {
    final hidden = await AdminCatalogService.hiddenTheatreKeys();
    final persisted = await TheatreService.getTheatres();
    final fromMovies =
        TheatreCatalogUtils.buildTheatresFromMovies(mergedMovies);
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void push(Map<String, dynamic> row) {
      final name = row['name'] as String? ?? '';
      final k = TheatreCatalogUtils.normalizeTheatreKey(name);
      if (k.isEmpty || hidden.contains(k) || seen.contains(k)) return;
      seen.add(k);
      out.add(Map<String, dynamic>.from(row));
    }

    for (final t in persisted) {
      if (t['_adminLocal'] == true) {
        final copy = Map<String, dynamic>.from(t)..remove('_adminLocal');
        push(copy);
      }
    }

    for (final t in fromMovies) {
      push(Map<String, dynamic>.from(t));
    }

    if (fromMovies.isEmpty) {
      for (final t in persisted) {
        if (t['_adminLocal'] == true) continue;
        push(Map<String, dynamic>.from(t));
      }
    }

    out.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return out;
  }
}
