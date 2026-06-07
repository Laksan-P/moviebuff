import 'package:flutter/foundation.dart';

import '../core/data/catalog_architecture.dart';
import '../services/catalog_repository.dart';
import '../services/external_movie_service.dart';
import '../services/local_db_service.dart';
import '../utils/movie_catalog_utils.dart';

class MovieProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _theatres = [];
  List<Map<String, dynamic>> _showtimes = [];
  List<Map<String, dynamic>> _favorites = [];

  String? _errorMessage;
  bool _loading = false;
  bool _catalogueReady = false;
  CatalogueDataSource _catalogueSource = CatalogueDataSource.empty;

  String _sourceLabel = 'Laravel API + External JSON';

  List<Map<String, dynamic>> get movies => _movies;
  List<Map<String, dynamic>> get theatres => _theatres;
  List<Map<String, dynamic>> get showtimes => _showtimes;
  List<Map<String, dynamic>> get favorites => _favorites;

  String? get errorMessage => _errorMessage;
  bool get loading => _loading;
  bool get catalogueReady => _catalogueReady;
  bool get awaitingCatalogueUi => !_catalogueReady || _loading;
  CatalogueDataSource get catalogueSource => _catalogueSource;
  String get sourceLabel => _sourceLabel;

  void _appendError(String message) {
    if (_errorMessage == null || _errorMessage!.isEmpty) {
      _errorMessage = message;
    } else if (!_errorMessage!.contains(message)) {
      _errorMessage = '$_errorMessage; $message';
    }
  }

  Future<void> load({
    bool forceRefresh = false,
    bool isOnline = true,
  }) async {
    if (_loading && !forceRefresh) {
      debugPrint('🔄 CATALOGUE - load already in progress, skipping');
      return;
    }

    debugPrint(
      '🔄 CATALOGUE - load start '
      '(online=$isOnline, forceRefresh=$forceRefresh)',
    );
    _loading = true;
    _catalogueReady = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        CatalogRepository.load(isOnline: isOnline, forceRefresh: forceRefresh),
        ExternalMovieService.fetchMovies(forceRefresh: forceRefresh),
      ]);

      final core = results[0] as CoreCatalogueBundle;
      final external = results[1] as ExternalMoviesResult;

      final bundledMovies = await ExternalMovieService.loadBundledMovieList();
      final posterLookup = MovieCatalogUtils.buildPosterLookup([
        ...external.movies,
        ...bundledMovies,
      ]);

      final externalCatalogue = MovieCatalogUtils.mergeCustomerMovieLists(
        external.movies,
        bundledMovies,
        posterLookup: posterLookup,
      );

      _movies = MovieCatalogUtils.mergeCustomerMovieLists(
        externalCatalogue,
        core.movies.map((m) {
          final row = Map<String, dynamic>.from(m);
          MovieCatalogUtils.tagLaravelMovie(row);
          return row;
        }).toList(),
        posterLookup: posterLookup,
      );

      MovieCatalogUtils.logMergedCataloguePosters(_movies);
      _theatres = core.theatres;
      _showtimes = core.showtimes;
      _catalogueSource = core.overallSource;
      _sourceLabel = _buildSourceLabel(core, external);

      if (external.errorMessage != null) {
        _appendError(external.errorMessage!);
      }

      try {
        _favorites = await LocalDbService.getFavorites();
      } catch (e, st) {
        _favorites = [];
        debugPrint('❌ CATALOGUE favorites error: $e');
        debugPrint('$st');
      }

      debugPrint(
        '✅ CATALOGUE - merged movies=${_movies.length} '
        '(api=${core.movies.length}, external=${external.movies.length}) '
        'theatres=${_theatres.length} showtimes=${_showtimes.length}',
      );
    } catch (e, st) {
      _appendError(e.toString());
      debugPrint('❌ CATALOGUE - unexpected load error: $e');
      debugPrint('$st');
    } finally {
      _catalogueReady = true;
      _loading = false;
      notifyListeners();
      debugPrint(
        '🔄 CATALOGUE - finished (ready=$_catalogueReady loading=$_loading)',
      );
    }
  }

  static String _buildSourceLabel(
    CoreCatalogueBundle core,
    ExternalMoviesResult external,
  ) {
    final extPart = switch (external.source) {
      MovieSource.network => 'External JSON (live)',
      MovieSource.cache => 'External JSON (cache)',
      MovieSource.asset => 'External JSON (bundled)',
    };
    return '${core.sourceLabel} + $extPart';
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

  Future<void> refreshAfterAdminEdit({bool forceNetwork = false}) async {
    await load(forceRefresh: forceNetwork);
  }
}
