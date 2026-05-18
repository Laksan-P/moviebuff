import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/movie_catalog_utils.dart';
import '../utils/theatre_catalog_utils.dart';
import 'movie_service.dart';
import 'theatre_service.dart';

/// Merges live catalogue with admin-local prefs for admin UI (order + suppression).
class AdminCatalogService {
  AdminCatalogService._();

  static const _hiddenTheatresKey = 'admin_hidden_theatre_keys';
  static const _hiddenMoviesKey = 'admin_hidden_movie_keys';

  static Future<Set<String>> _loadHidden(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    if (s == null || s.isEmpty) return {};
    try {
      final list = jsonDecode(s) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveHidden(String key, Set<String> values) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(values.toList()));
  }

  static Future<Set<String>> hiddenTheatreKeys() =>
      _loadHidden(_hiddenTheatresKey);

  static Future<Set<String>> hiddenMovieKeys() => _loadHidden(_hiddenMoviesKey);

  static String normalizeMovieKey(String? title) =>
      (title ?? '').toLowerCase().trim();

  static Future<void> suppressTheatre(String displayName) async {
    final k = TheatreCatalogUtils.normalizeTheatreKey(displayName);
    final h = await hiddenTheatreKeys();
    h.add(k);
    await _saveHidden(_hiddenTheatresKey, h);
    debugPrint(
      '🛠️ ADMIN CRUD - suppressed theatre from admin list: $displayName',
    );
  }

  static Future<void> suppressMovie(String title) async {
    final k = normalizeMovieKey(title);
    final h = await hiddenMovieKeys();
    h.add(k);
    await _saveHidden(_hiddenMoviesKey, h);
    debugPrint(
      '🛠️ ADMIN CRUD - suppressed movie from admin list: $title',
    );
  }

  /// Admin-local prefs → live catalogue theatres → fallback (Chennai seed) if no catalogue.
  static Future<List<Map<String, dynamic>>> mergeTheatresForAdmin(
    List<Map<String, dynamic>> catalogueMovies,
  ) async {
    final hidden = await hiddenTheatreKeys();
    final persisted = await TheatreService.getTheatres();
    final catalogueList =
        TheatreCatalogUtils.buildTheatresFromMovies(catalogueMovies);

    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void push(Map<String, dynamic> row, String source) {
      final name = row['name'] as String? ?? '';
      final k = TheatreCatalogUtils.normalizeTheatreKey(name);
      if (k.isEmpty || hidden.contains(k) || seen.contains(k)) return;
      seen.add(k);
      out.add({...row, '_adminSource': source});
    }

    for (final t in persisted) {
      if (t['_adminLocal'] == true) {
        final copy = Map<String, dynamic>.from(t)..remove('_adminLocal');
        push(copy, 'admin_local');
      }
    }

    if (catalogueList.isNotEmpty) {
      for (final t in catalogueList) {
        push(Map<String, dynamic>.from(t), 'catalogue');
      }
      debugPrint(
        '🎭 ADMIN THEATRES - Loaded ${catalogueList.length} theatres from active catalogue',
      );
      return out;
    }

    debugPrint('⚠️ ADMIN FALLBACK - Using default local data');
    for (final t in persisted) {
      if (t['_adminLocal'] == true) continue;
      push(Map<String, dynamic>.from(t), 'seed');
    }
    return out;
  }

  static String _adminMovieKey(Map<String, dynamic> row) {
    final id = row['id']?.toString().trim();
    if (id != null && id.isNotEmpty && id != 'null') return 'id:$id';
    return 't:${normalizeMovieKey(row['title']?.toString())}';
  }

  /// Live catalogue (latest posters) → admin-local overlay → seed if no catalogue.
  static Future<List<Map<String, dynamic>>> mergeMoviesForAdmin(
    List<Map<String, dynamic>> catalogueMovies,
  ) async {
    final hidden = await hiddenMovieKeys();
    final persisted = await MovieService.getMovies();
    final byKey = <String, Map<String, dynamic>>{};

    void put(Map<String, dynamic> row, String source) {
      final title = row['title']?.toString() ?? '';
      final k = normalizeMovieKey(title);
      if (k.isEmpty || hidden.contains(k)) return;
      final mapKey = _adminMovieKey(row);
      byKey[mapKey] = {
        ...MovieCatalogUtils.normalizeCustomerMovie(
          Map<String, dynamic>.from(row),
        ),
        '_adminSource': source,
      };
    }

    if (catalogueMovies.isNotEmpty) {
      for (final raw in catalogueMovies) {
        put(Map<String, dynamic>.from(raw), 'catalogue');
      }
    }

    for (final m in persisted) {
      if (m['_adminLocal'] != true) continue;
      final copy = Map<String, dynamic>.from(m)..remove('_adminLocal');
      put(copy, 'admin_local');
    }

    if (byKey.isNotEmpty) {
      debugPrint(
        'ADMIN MOVIES LOADED FROM SYNCED SOURCE: ${byKey.length} movies',
      );
      return byKey.values.toList();
    }

    debugPrint('⚠️ ADMIN FALLBACK - Using default local data');
    for (final m in persisted) {
      if (m['_adminLocal'] == true) continue;
      put(Map<String, dynamic>.from(m), 'seed');
    }
    return byKey.values.toList();
  }
}
