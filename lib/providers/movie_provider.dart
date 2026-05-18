import 'package:flutter/foundation.dart';

import '../services/customer_catalog_service.dart';
import '../services/external_movie_service.dart';
import '../services/local_db_service.dart';
import '../services/showtime_service.dart';

class MovieProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _favorites = [];
  MovieSource _source = MovieSource.asset;
  DateTime? _fetchedAt;
  String? _statusMessage;
  bool _loading = false;

  List<Map<String, dynamic>> get movies => _movies;
  List<Map<String, dynamic>> get favorites => _favorites;
  MovieSource get source => _source;
  DateTime? get fetchedAt => _fetchedAt;
  String? get statusMessage => _statusMessage;
  bool get loading => _loading;

  String get sourceLabel {
    switch (_source) {
      case MovieSource.network:
        return 'Live from external JSON';
      case MovieSource.cache:
        return 'From sqflite cache';
      case MovieSource.asset:
        return 'From bundled offline JSON';
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    _loading = true;
    notifyListeners();

    final result = await ExternalMovieService.fetchMovies(
      forceRefresh: forceRefresh,
    );
    _movies = await CustomerCatalogService.mergeCustomerMovies(
      result.movies,
    );
    _source = result.source;
    _fetchedAt = result.fetchedAt;
    _statusMessage = result.errorMessage;

    await ShowtimeService.initShowtimes(
      applySem1Templates: !_catalogueStyleMovies(_movies),
    );

    final favs = await LocalDbService.getFavorites();
    _favorites = favs;

    _loading = false;
    debugPrint(
      '🎞️ MOVIE PROVIDER - ${_movies.length} movies ($_source), ${_favorites.length} favorites',
    );
    notifyListeners();
  }

  Future<void> toggleFavorite(Map<String, dynamic> movie) async {
    final title = movie['title'] as String;
    final isFav = await LocalDbService.isFavorite(title);
    if (isFav) {
      await LocalDbService.removeFavorite(title);
    } else {
      await LocalDbService.addFavorite(movie);
    }
    _favorites = await LocalDbService.getFavorites();
    notifyListeners();
  }

  bool isFavorite(String title) =>
      _favorites.any((f) => f['title'] == title);

  bool _catalogueStyleMovies(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return false;
    return list.any(
      (m) =>
          (m['theatre']?.toString().trim() ?? '').isNotEmpty ||
          (m['showtimes'] is List && (m['showtimes'] as List).isNotEmpty),
    );
  }

  /// Re-merge local admin prefs with last external fetch (no forced network).
  Future<void> refreshAfterAdminEdit() async {
    final result = await ExternalMovieService.fetchMovies(
      forceRefresh: false,
    );
    _movies = await CustomerCatalogService.mergeCustomerMovies(
      result.movies,
    );
    await ShowtimeService.initShowtimes(
      applySem1Templates: !_catalogueStyleMovies(_movies),
    );
    debugPrint(
      '🔄 CUSTOMER CATALOGUE - Refreshed after admin changes',
    );
    notifyListeners();
  }
}
