import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/movie_catalog_utils.dart';
import '../utils/theatre_catalog_utils.dart';
import 'admin_catalog_service.dart';

class ShowtimeService {
  static const String _showtimesKey = 'app_showtimes_v4'; // Relative dates v4

  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Templates for showtimes
  static final List<Map<String, dynamic>> _showtimeTemplates = [
    // --- AGS Cinemas ---
    {
      'id_base': 'ags_avengers',
      'time': '09:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'theatre': 'AGS Cinemas',
      'movie': 'Avengers: Endgame',
      'price': 1200.0,
      'days': [0, 1, 2, 3, 4, 5, 6],
    },
    {
      'id_base': 'ags_avengers_morn',
      'time': '10:00 AM',
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'theatre': 'AGS Cinemas',
      'movie': 'Avengers: Endgame',
      'price': 800.0,
      'days': [0, 2, 4, 6],
    },
    {
      'id_base': 'ags_spiderman',
      'time': '09:30 PM',
      'label': '3D',
      'language': 'Tamil',
      'format': '3D',
      'theatre': 'AGS Cinemas',
      'movie': 'Spider-Man: No Way Home',
      'price': 950.0,
      'days': [0, 1, 3, 5],
    },
    {
      'id_base': 'ags_spiderman_matinee',
      'time': '01:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'theatre': 'AGS Cinemas',
      'movie': 'Spider-Man: No Way Home',
      'price': 1300.0,
      'days': [1, 2, 4, 6],
    },
    {
      'id_base': 'ags_dune',
      'time': '11:00 AM',
      'label': '4DX',
      'language': 'English',
      'format': '4DX',
      'theatre': 'AGS Cinemas',
      'movie': 'Dune',
      'price': 1400.0,
      'days': [0, 1, 2, 3, 4, 5, 6],
    },

    // --- PVR Icon ---
    {
      'id_base': 'pvr_avengers',
      'time': '09:30 PM',
      'label': '3D',
      'language': 'Hindi',
      'format': '3D',
      'theatre': 'PVR Icon',
      'movie': 'Avengers: Endgame',
      'price': 1000.0,
      'days': [0, 1, 2, 3, 4, 5, 6],
    },
    {
      'id_base': 'pvr_interstellar',
      'time': '08:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'theatre': 'PVR Icon',
      'movie': 'Interstellar',
      'price': 1200.0,
      'days': [0, 2, 4, 6],
    },
    {
      'id_base': 'pvr_darkknight',
      'time': '09:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'theatre': 'PVR Icon',
      'movie': 'The Dark Knight',
      'price': 1300.0,
      'days': [1, 3, 5],
    },

    // --- Sathyam Cinemas ---
    {
      'id_base': 'sathyam_interstellar',
      'time': '09:15 PM',
      'label': '4DX',
      'language': 'English',
      'format': '4DX',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Interstellar',
      'price': 1500.0,
      'days': [0, 1, 2, 3, 4, 5, 6],
    },
    {
      'id_base': 'sathyam_inception',
      'time': '08:30 PM',
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Inception',
      'price': 900.0,
      'days': [0, 2, 4, 6],
    },
    {
      'id_base': 'sathyam_dune',
      'time': '09:45 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Dune',
      'price': 1350.0,
      'days': [1, 3, 5],
    },

    // --- Mayajaal Multiplex ---
    {
      'id_base': 'mayajaal_inception',
      'time': '09:00 PM',
      'label': '2D',
      'language': 'Tamil',
      'format': '2D',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Inception',
      'price': 700.0,
      'days': [0, 1, 2, 3, 4, 5, 6],
    },
    {
      'id_base': 'mayajaal_darkknight',
      'time': '08:45 PM',
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'The Dark Knight',
      'price': 900.0,
      'days': [0, 2, 4, 6],
    },
    {
      'id_base': 'mayajaal_spiderman',
      'time': '10:00 PM',
      'label': '3D',
      'language': 'English',
      'format': '3D',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Spider-Man: No Way Home',
      'price': 1000.0,
      'days': [1, 3, 5],
    },
  ];

  static Future<void> initShowtimes({bool applySem1Templates = true}) async {
    final existingJson = await _getString(_showtimesKey);
    List<Map<String, dynamic>> showtimes = [];

    if (existingJson != null) {
      final List<dynamic> decoded = jsonDecode(existingJson);
      showtimes = decoded.map((s) => Map<String, dynamic>.from(s)).toList();
    }

    // Dynamically identify all template-based showtime prefixes to refresh them
    final Set<String> templatePrefixes = _showtimeTemplates
        .map((t) => '${(t['id_base'] as String).split('_')[0]}_')
        .toSet();

    showtimes.removeWhere((s) {
      final id = s['id']?.toString() ?? '';
      return templatePrefixes.any((prefix) => id.startsWith(prefix));
    });

    if (applySem1Templates) {
      // Generate fresh templates for the next 7 days
      final now = DateTime.now();
      final List<Map<String, dynamic>> freshTemplates = [];

      for (var template in _showtimeTemplates) {
        final days = template['days'] as List<int>;
        for (int offset in days) {
          final showDate = now.add(Duration(days: offset));
          final dateStr =
              '${showDate.year}-${showDate.month.toString().padLeft(2, '0')}-${showDate.day.toString().padLeft(2, '0')}';

          freshTemplates.add({
            'id': '${template['id_base']}_$offset',
            'time': template['time'],
            'label': template['label'],
            'language': template['language'],
            'format': template['format'],
            'date': dateStr,
            'theatre': template['theatre'],
            'movie': template['movie'],
            'price': template['price'],
          });
        }
      }

      showtimes.addAll(freshTemplates);
      debugPrint(
        '⏰ SHOWTIME SERVICE - Refreshed templates. Total: ${showtimes.length} (Templates: ${freshTemplates.length})',
      );
    } else {
      debugPrint(
        '⏰ SHOWTIME SERVICE - Sem 1 templates skipped (active catalogue). Total: ${showtimes.length}',
      );
    }

    await _setString(_showtimesKey, jsonEncode(showtimes));
  }

  static Future<List<Map<String, dynamic>>> _readPrefsList() async {
    final json = await _getString(_showtimesKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  /// Dedupe key: movie + theatre + date + time + format + language (lowercase).
  static String showtimeDedupeKey(Map<String, dynamic> st) {
    final m = (st['movie'] ?? '').toString().toLowerCase().trim();
    final t = (st['theatre'] ?? '').toString().toLowerCase().trim();
    final d = (st['date'] ?? '').toString();
    final ti = (st['time'] ?? '').toString().toLowerCase().trim();
    final f = (st['format'] ?? '').toString().toLowerCase().trim();
    final l = (st['language'] ?? '').toString().toLowerCase().trim();
    return '$m|$t|$d|$ti|$f|$l';
  }

  static bool _catalogueStyleMovies(List<Map<String, dynamic>> mergedMovies) {
    if (mergedMovies.isEmpty) return false;
    return mergedMovies.any(
      (m) =>
          (m['theatre']?.toString().trim() ?? '').isNotEmpty ||
          (m['showtimes'] is List && (m['showtimes'] as List).isNotEmpty),
    );
  }

  static bool _showtimeMatchesMergedCatalogue(
    Map<String, dynamic> st,
    List<Map<String, dynamic>> mergedMovies,
  ) {
    final stMovie = AdminCatalogService.normalizeMovieKey(st['movie']?.toString());
    for (final m in mergedMovies) {
      final mt = AdminCatalogService.normalizeMovieKey(m['title']?.toString());
      if (mt != stMovie) continue;
      if (TheatreCatalogUtils.normalizeTheatreKey(
            m['theatre']?.toString() ?? '',
          ).isEmpty ||
          TheatreCatalogUtils.theatresLooselyMatch(
            m['theatre']?.toString() ?? '',
            st['theatre']?.toString() ?? '',
          )) {
        return true;
      }
    }
    return false;
  }

  /// Customer + movie-details: prefs showtimes (filtered) + synthetic catalogue showtimes.
  static Future<List<Map<String, dynamic>>> getCustomerShowtimes(
    List<Map<String, dynamic>> mergedMovies,
  ) async {
    final useSem1 = mergedMovies.isEmpty || !_catalogueStyleMovies(mergedMovies);
    if (useSem1) {
      debugPrint('⚠️ ADMIN FALLBACK - Using default showtime data');
    }
    await initShowtimes(applySem1Templates: useSem1);

    final hiddenMovies = await AdminCatalogService.hiddenMovieKeys();
    final hiddenTheatres = await AdminCatalogService.hiddenTheatreKeys();
    var list = await _readPrefsList();

    list = list.where((s) {
      final mk = AdminCatalogService.normalizeMovieKey(s['movie']?.toString());
      if (hiddenMovies.contains(mk)) return false;
      final tk = TheatreCatalogUtils.normalizeTheatreKey(
        s['theatre']?.toString() ?? '',
      );
      if (hiddenTheatres.contains(tk)) return false;
      if (!useSem1) {
        return _showtimeMatchesMergedCatalogue(s, mergedMovies);
      }
      return true;
    }).toList();

    final merged = <String, Map<String, dynamic>>{};
    for (final s in list) {
      merged[showtimeDedupeKey(s)] = s;
    }

    if (!useSem1) {
      for (final m in mergedMovies) {
        for (final st in buildExternalCatalogShowtimes(m)) {
          final k = showtimeDedupeKey(st);
          merged.putIfAbsent(k, () => st);
        }
      }
    }

    final out = merged.values.toList();
    debugPrint('🕒 CUSTOMER SHOWTIMES - ${out.length} slots (sem1=$useSem1)');
    return out;
  }

  /// Same data as [getCustomerShowtimes] with admin dashboard log line.
  static Future<List<Map<String, dynamic>>> getAdminMergedShowtimes(
    List<Map<String, dynamic>> mergedMovies,
  ) async {
    final out = await getCustomerShowtimes(mergedMovies);
    debugPrint(
      '🕒 ADMIN SHOWTIMES - Loaded ${out.length} showtimes from active catalogue',
    );
    return out;
  }

  /// Backwards-compatible: seeds Sem 1 templates when no merged-movie context provided.
  static Future<List<Map<String, dynamic>>> getShowtimes() async {
    await initShowtimes(applySem1Templates: true);
    final json = await _getString(_showtimesKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  static Future<void> addShowtime(Map<String, dynamic> showtime) async {
    final list = await _readPrefsList();
    final row = Map<String, dynamic>.from(showtime);
    row['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    row['_adminLocal'] = true;
    list.add(row);
    await _setString(_showtimesKey, jsonEncode(list));
    debugPrint(
      '🛠️ ADMIN CRUD - Added showtime ${row['movie']} @ ${row['theatre']} ${row['time']}',
    );
  }

  static Future<void> deleteShowtime(String id) async {
    final list = await _readPrefsList();
    list.removeWhere((s) => s['id'] == id);
    await _setString(_showtimesKey, jsonEncode(list));
    debugPrint('🛠️ ADMIN CRUD - Deleted showtime $id');
  }

  static Future<void> updateShowtime(
    String id,
    Map<String, dynamic> updated,
  ) async {
    final list = await _readPrefsList();
    final i = list.indexWhere((s) => s['id'] == id);
    if (i >= 0) {
      final row = Map<String, dynamic>.from(updated);
      row['id'] = id;
      row['_adminLocal'] = true;
      list[i] = row;
      await _setString(_showtimesKey, jsonEncode(list));
      debugPrint('🛠️ ADMIN CRUD - Edited showtime $id');
    }
  }

  // Time-based filtering helper
  static bool isShowtimePassed(String timeStr, String dateStr) {
    try {
      final now = DateTime.now();
      DateTime showDate;

      // Parse dateStr (handles "yyyy-MM-dd")
      showDate = DateTime.parse(dateStr);

      // If the show date is in the past, return true
      final normalizedNow = DateTime(now.year, now.month, now.day);
      if (showDate.isBefore(normalizedNow)) return true;
      if (showDate.isAfter(normalizedNow)) return false;

      // If show is today, check time
      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) return false;

      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      final showTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Hide if the current time is after the showtime
      return now.isAfter(showTime);
    } catch (e) {
      debugPrint('⏰ TIME ERROR ($timeStr, $dateStr): $e');
      return false;
    }
  }

  /// Synthetic showtimes for external-catalog movies (7 days × JSON or default slots).
  static List<Map<String, dynamic>> buildExternalCatalogShowtimes(
    Map<String, dynamic> movie,
  ) {
    final title = movie['title']?.toString() ?? 'Movie';
    final theatreRaw = movie['theatre']?.toString().trim() ?? '';
    final theatre = theatreRaw.isNotEmpty
        ? theatreRaw
        : MovieCatalogUtils.defaultExternalTheatre;

    List<String> times;
    final raw = movie['showtimes'];
    if (raw is List && raw.isNotEmpty) {
      times = raw.map((e) => e.toString()).toList();
    } else {
      times = List<String>.from(MovieCatalogUtils.defaultExternalShowtimes);
    }

    final price = MovieCatalogUtils.priceFromMovie(movie);
    var fmt = '2D';
    final fmts = movie['formats'];
    if (fmts is List && fmts.isNotEmpty) fmt = fmts.first.toString();
    var lang = 'English';
    final langs = movie['languages'];
    if (langs is List && langs.isNotEmpty) lang = langs.first.toString();

    final now = DateTime.now();
    final out = <Map<String, dynamic>>[];
    for (var d = 0; d < 7; d++) {
      final showDate = now.add(Duration(days: d));
      final dateStr =
          '${showDate.year}-${showDate.month.toString().padLeft(2, '0')}-${showDate.day.toString().padLeft(2, '0')}';
      for (var i = 0; i < times.length; i++) {
        out.add({
          'id': 'extcat_${title.hashCode}_${d}_$i',
          'time': times[i],
          'label': fmt,
          'language': lang,
          'format': fmt,
          'date': dateStr,
          'theatre': theatre,
          'movie': title,
          'price': price,
        });
      }
    }
    return out;
  }
}
