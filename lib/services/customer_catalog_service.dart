import '../utils/movie_catalog_utils.dart';
import 'theatre_service.dart';

/// Customer-facing catalogue helpers.
///
/// Core data comes from [CatalogRepository] (Laravel API primary) merged with
/// external_movies.json via [ExternalMovieService]. This service normalizes maps.
class CustomerCatalogService {
  CustomerCatalogService._();

  static Future<List<Map<String, dynamic>>> mergeCustomerMovies(
    List<Map<String, dynamic>> movies,
  ) async {
    return movies
        .map((m) => MovieCatalogUtils.normalizeCustomerMovie(m))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> mergeCustomerTheatres(
    List<Map<String, dynamic>> mergedMovies,
  ) async {
    final theatres = await TheatreService.getTheatres();
    theatres.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return theatres;
  }
}
