import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Movies loaded and mutated exclusively through the Laravel API.
class MovieService {
  static Future<List<Map<String, dynamic>>> getMovies() async {
    final movies = await ApiService.fetchMovies();
    debugPrint('🎬 MOVIE SERVICE - Loaded ${movies.length} movies from API');
    return movies;
  }

  static Future<void> addMovie(Map<String, dynamic> movie) async {
    await ApiService.createMovie(movie);
    debugPrint('🛠️ ADMIN CRUD - Created movie via API: ${movie['title']}');
  }

  static Future<void> updateMovie(
    dynamic idOrTitle,
    Map<String, dynamic> updatedMovie,
  ) async {
    final id = _resolveId(idOrTitle, updatedMovie);
    await ApiService.updateMovie(id, updatedMovie);
    debugPrint('🛠️ ADMIN CRUD - Updated movie via API: ${updatedMovie['title']}');
  }

  static Future<void> removeMovie(dynamic idOrTitle) async {
    final id = _resolveId(idOrTitle, null);
    await ApiService.deleteMovie(id);
    debugPrint('🛠️ ADMIN CRUD - Deleted movie via API: $id');
  }

  static int _resolveId(
    dynamic idOrTitle,
    Map<String, dynamic>? movie,
  ) {
    final fromMovie = movie?['id'];
    if (fromMovie != null) return int.parse(fromMovie.toString());
    if (idOrTitle is int) return idOrTitle;
    final parsed = int.tryParse(idOrTitle?.toString() ?? '');
    if (parsed != null) return parsed;
    throw ArgumentError('Movie id is required for API update/delete.');
  }
}
