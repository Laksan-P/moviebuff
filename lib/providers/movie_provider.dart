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
  /// False until the first [load] / [refreshAfterAdminEdit] merge completes.
  bool _catalogueReady = false;

  List<Map<String, dynamic>> get movies => _movies;
  List<Map<String, dynamic>> get favorites => _favorites;
  MovieSource get source => _source;
  DateTime? get fetchedAt => _fetchedAt;
  String? get statusMessage => _statusMessage;
  bool get loading => _loading;

  bool get catalogueReady => _catalogueReady;

  /// Customer screens should not show catalogue-derived lists while this is true.
  bool get awaitingCatalogueUi => !_catalogueReady || _loading;

  Future<void> _logCatalogueReadyStats() async {
    final theatres =
        await CustomerCatalogService.mergeCustomerTheatres(_movies);
    final showtimes = await ShowtimeService.getCustomerShowtimes(_movies);
    debugPrint(
      '✅ CATALOGUE - Merged catalogue ready: ${_movies.length} movies, '
      '${theatres.length} theatres, ${showtimes.length} showtimes',
    );
  }

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
    debugPrint('🔄 CATALOGUE - Loading merged catalogue');
    _loading = true;
    _catalogueReady = false;
    _movies = [];
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

    await _logCatalogueReadyStats();

    _catalogueReady = true;
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

  /// Re-merge local admin prefs; uses cache unless [forceNetwork] is true.
  Future<void> refreshAfterAdminEdit({bool forceNetwork = false}) async {
    debugPrint('🔄 CATALOGUE - Loading merged catalogue');
    _loading = true;
    _catalogueReady = false;
    notifyListeners();

    final result = await ExternalMovieService.fetchMovies(
      forceRefresh: forceNetwork,
    );
    _movies = await CustomerCatalogService.mergeCustomerMovies(
      result.movies,
    );
    await ShowtimeService.initShowtimes(
      applySem1Templates: !_catalogueStyleMovies(_movies),
    );

    await _logCatalogueReadyStats();

    _catalogueReady = true;
    _loading = false;
    debugPrint('🔄 CATALOGUE - Refreshed after admin CRUD');
    notifyListeners();
  }
}
