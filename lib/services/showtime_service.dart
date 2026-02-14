import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> initShowtimes() async {
    final existingJson = await _getString(_showtimesKey);
    List<Map<String, dynamic>> showtimes = [];

    if (existingJson != null) {
      final List<dynamic> decoded = jsonDecode(existingJson);
      showtimes = decoded.map((s) => Map<String, dynamic>.from(s)).toList();
    }

    // Identify and remove all template-based showtimes to refresh them
    final templatePrefixes = ['ags_', 'pvr_', 'sathyam_', 'mayajaal_'];
    showtimes.removeWhere((s) {
      final id = s['id']?.toString() ?? '';
      return templatePrefixes.any((prefix) => id.startsWith(prefix));
    });

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

    // Merge and save
    showtimes.addAll(freshTemplates);
    await _setString(_showtimesKey, jsonEncode(showtimes));

    debugPrint(
      '⏰ SHOWTIME SERVICE - Refreshed templates. Total: ${showtimes.length} (Templates: ${freshTemplates.length})',
    );
  }

  static Future<List<Map<String, dynamic>>> getShowtimes() async {
    await initShowtimes();
    final json = await _getString(_showtimesKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  static Future<void> addShowtime(Map<String, dynamic> showtime) async {
    final showtimes = await getShowtimes();
    showtime['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    showtimes.add(showtime);
    await _setString(_showtimesKey, jsonEncode(showtimes));
    debugPrint('⏰ SHOWTIME SERVICE - Added showtime: ${showtime['time']}');
  }

  static Future<void> deleteShowtime(String id) async {
    final showtimes = await getShowtimes();
    showtimes.removeWhere((s) => s['id'] == id);
    await _setString(_showtimesKey, jsonEncode(showtimes));
    debugPrint('⏰ SHOWTIME SERVICE - Deleted showtime: $id');
  }

  // Time-based filtering helper
  static bool isShowtimePassed(String timeStr, String dateStr) {
    // UNLIMITED DATE: Disabled filtering to ensure all movies/showtimes are visible
    // as requested by the user.
    return false;
    /*
    try {
      final now = DateTime.now();
      DateTime showDate;

      // Parse dateStr (handles both "yyyy-MM-dd" and legacy "Today")
      if (dateStr == 'Today') {
        showDate = DateTime(now.year, now.month, now.day);
      } else if (dateStr == 'Tomorrow') {
        showDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
      } else {
        showDate = DateTime.parse(dateStr);
      }

      // If the show date is in the past, return true
      final normalizedNow = DateTime(now.year, now.month, now.day);
      if (showDate.isBefore(normalizedNow)) return true;
      if (showDate.isAfter(normalizedNow)) return false;

      // If show is today, check time
      final parts = timeStr.split(' ');
      if (parts.length != 2) return false;

      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      final showTime = DateTime(now.year, now.month, now.day, hour, minute);

      return now.isAfter(showTime);
    } catch (e) {
      debugPrint('⏰ TIME ERROR: $e');
      return false;
    }
    */
  }
}
