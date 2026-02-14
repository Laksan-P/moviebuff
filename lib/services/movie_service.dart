import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_data.dart';

class MovieService {
  static const String _moviesKey = 'app_movies';

  // Initial Movies from AppData
  static final List<Map<String, dynamic>> _initialMovies =
      AppData.initialMovies;

  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Initialize movies if not present
  static Future<void> initMovies() async {
    final existing = await _getString(_moviesKey);
    if (existing == null) {
      await _setString(_moviesKey, jsonEncode(_initialMovies));
      debugPrint('🎬 MOVIE SERVICE - Initialized with default movies');
    }
  }

  // Get all movies
  static Future<List<Map<String, dynamic>>> getMovies() async {
    await initMovies(); // Ensure we have data
    final json = await _getString(_moviesKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((m) {
      final movie = Map<String, dynamic>.from(m);
      // Data Sanitization
      return {
        ...movie,
        'rating': movie['rating'] ?? 'N/A',
        'duration': movie['duration'] ?? 0,
        'genre': movie['genre'] ?? 'Action',
        'description': movie['description'] ?? 'No description available.',
        'formats': movie['formats'] ?? [],
        'languages': movie['languages'] ?? [],
        'image': movie['image'] ?? '',
        'trailerUrl': movie['trailerUrl'] ?? '',
      };
    }).toList();
  }

  // Add a movie
  static Future<void> addMovie(Map<String, dynamic> movie) async {
    final movies = await getMovies();
    movies.add(movie);
    await _setString(_moviesKey, jsonEncode(movies));
    debugPrint('🎬 MOVIE SERVICE - Added: ${movie['title']}');
  }

  // Remove a movie by title
  static Future<void> removeMovie(String title) async {
    final movies = await getMovies();
    movies.removeWhere((m) => m['title'] == title);
    await _setString(_moviesKey, jsonEncode(movies));
    debugPrint('🎬 MOVIE SERVICE - Removed: $title');
  }

  // Update a movie
  static Future<void> updateMovie(
    String oldTitle,
    Map<String, dynamic> updatedMovie,
  ) async {
    final movies = await getMovies();
    final index = movies.indexWhere((m) => m['title'] == oldTitle);
    if (index != -1) {
      movies[index] = updatedMovie;
      await _setString(_moviesKey, jsonEncode(movies));
      debugPrint('🎬 MOVIE SERVICE - Updated: ${updatedMovie['title']}');
    }
  }
}
