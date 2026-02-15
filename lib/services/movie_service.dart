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
    List<Map<String, dynamic>> movies = [];

    if (existing != null) {
      final List<dynamic> decoded = jsonDecode(existing);
      movies = decoded.map((m) => Map<String, dynamic>.from(m)).toList();
    }

    // Add missing movies OR update existing ones from AppData
    bool updated = false;
    for (var initialMovie in _initialMovies) {
      final index = movies.indexWhere(
        (m) => m['title'] == initialMovie['title'],
      );

      if (index == -1) {
        // New movie added in AppData
        movies.add(initialMovie);
        updated = true;
      } else {
        // Existing movie - check if important fields changed in code
        bool changed = false;
        if (movies[index]['image'] != initialMovie['image']) {
          movies[index]['image'] = initialMovie['image'];
          changed = true;
        }
        if (movies[index]['genre'] != initialMovie['genre']) {
          movies[index]['genre'] = initialMovie['genre'];
          changed = true;
        }
        if (movies[index]['description'] != initialMovie['description']) {
          movies[index]['description'] = initialMovie['description'];
          changed = true;
        }

        if (changed) updated = true;
      }
    }

    if (updated || existing == null) {
      await _setString(_moviesKey, jsonEncode(movies));
      debugPrint(
        '🎬 MOVIE SERVICE - Synced with ${existing == null ? "initial" : "updated"} default movies',
      );
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
        'theatre': movie['theatre'],
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
