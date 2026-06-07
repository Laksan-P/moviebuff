import '../utils/movie_catalog_utils.dart';
import 'movie_service.dart';
import 'theatre_service.dart';

/// Admin catalogue helpers — all data comes from the Laravel API.
class AdminCatalogService {
  AdminCatalogService._();

  static String normalizeMovieKey(String? title) =>
      (title ?? '').toLowerCase().trim();

  static Future<List<Map<String, dynamic>>> mergeTheatresForAdmin(
    List<Map<String, dynamic>> catalogueMovies,
  ) async {
    return TheatreService.getTheatres();
  }

  static Future<List<Map<String, dynamic>>> mergeMoviesForAdmin(
    List<Map<String, dynamic>> catalogueMovies,
  ) async {
    final movies = await MovieService.getMovies();
    return movies
        .map(
          (m) => {
            ...MovieCatalogUtils.normalizeCustomerMovie(m),
            '_adminSource': 'api',
          },
        )
        .toList();
  }

  static Future<void> suppressTheatre(String displayName) async {
    final theatres = await TheatreService.getTheatres();
    final key = displayName.toLowerCase().trim();
    final match = theatres.firstWhere(
      (t) => (t['name'] ?? '').toString().toLowerCase().trim() == key,
      orElse: () => {},
    );
    if (match['id'] != null) {
      await TheatreService.removeTheatreById(int.parse(match['id'].toString()));
    }
  }

  static Future<void> suppressMovie(String title) async {
    final movies = await MovieService.getMovies();
    final key = title.toLowerCase().trim();
    final match = movies.firstWhere(
      (m) => (m['title'] ?? '').toString().toLowerCase().trim() == key,
      orElse: () => {},
    );
    if (match['id'] != null) {
      await MovieService.removeMovie(match['id']);
    }
  }
}
