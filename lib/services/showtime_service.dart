import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowtimeService {
  static const String _showtimesKey =
      'app_showtimes_v2'; // Force refresh with new data

  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Initial mock data covering ALL theatres and movies
  static final List<Map<String, dynamic>> _initialShowtimes = [
    // --- AGS Cinemas (Avengers, Spider-Man, Dune) ---
    {
      'id': 'ags_avengers_1',
      'time': '09:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-08',
      'theatre': 'AGS Cinemas',
      'movie': 'Avengers: Endgame',
      'price': 1200.0,
    },
    {
      'id': 'ags_avengers_2',
      'time': '10:00 AM',
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'date': '2026-02-09',
      'theatre': 'AGS Cinemas',
      'movie': 'Avengers: Endgame',
      'price': 800.0,
    },
    {
      'id': 'ags_spiderman_1',
      'time': '09:30 PM',
      'label': '3D',
      'language': 'Tamil',
      'format': '3D',
      'date': '2026-02-08',
      'theatre': 'AGS Cinemas',
      'movie': 'Spider-Man: No Way Home',
      'price': 950.0,
    },
    {
      'id': 'ags_spiderman_2',
      'time': '01:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-09',
      'theatre': 'AGS Cinemas',
      'movie': 'Spider-Man: No Way Home',
      'price': 1300.0,
    },
    {
      'id': 'ags_dune_1',
      'time': '11:00 AM',
      'label': '4DX',
      'language': 'English',
      'format': '4DX',
      'date': '2026-02-09',
      'theatre': 'AGS Cinemas',
      'movie': 'Dune',
      'price': 1400.0,
    },

    // --- PVR Icon (Avengers, Interstellar, The Dark Knight) ---
    {
      'id': 'pvr_avengers_1',
      'time': '09:30 PM',
      'label': '3D',
      'language': 'Hindi',
      'format': '3D',
      'date': '2026-02-08',
      'theatre': 'PVR Icon',
      'movie': 'Avengers: Endgame',
      'price': 1000.0,
    },
    {
      'id': 'pvr_avengers_2',
      'time': '11:30 AM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-09',
      'theatre': 'PVR Icon',
      'movie': 'Avengers: Endgame',
      'price': 1400.0,
    },
    {
      'id': 'pvr_interstellar_1',
      'time': '08:00 PM', // Today
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-08',
      'theatre': 'PVR Icon',
      'movie': 'Interstellar',
      'price': 1200.0,
    },
    {
      'id': 'pvr_interstellar_2',
      'time': '10:30 PM', // Today
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'date': '2026-02-08',
      'theatre': 'PVR Icon',
      'movie': 'Interstellar',
      'price': 700.0,
    },
    {
      'id': 'pvr_darkknight_1',
      'time': '09:00 PM', // Today
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-08',
      'theatre': 'PVR Icon',
      'movie': 'The Dark Knight',
      'price': 1300.0,
    },
    {
      'id': 'pvr_darkknight_2',
      'time': '12:00 PM',
      'label': '2D',
      'language': 'Tamil',
      'format': '2D',
      'date': '2026-02-09',
      'theatre': 'PVR Icon',
      'movie': 'The Dark Knight',
      'price': 850.0,
    },

    // --- Sathyam Cinemas (Interstellar, Inception, Dune) ---
    {
      'id': 'sathyam_interstellar_1',
      'time': '09:15 PM', // Today
      'label': '4DX',
      'language': 'English',
      'format': '4DX',
      'date': '2026-02-08',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Interstellar',
      'price': 1500.0,
    },
    {
      'id': 'sathyam_interstellar_2',
      'time': '10:30 AM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-09',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Interstellar',
      'price': 1300.0,
    },
    {
      'id': 'sathyam_inception_1',
      'time': '08:30 PM', // Today
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'date': '2026-02-08',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Inception',
      'price': 900.0,
    },
    {
      'id': 'sathyam_inception_2',
      'time': '03:00 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-09',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Inception',
      'price': 1400.0,
    },
    {
      'id': 'sathyam_dune_1',
      'time': '09:45 PM', // Today
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-08',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Dune',
      'price': 1350.0,
    },
    {
      'id': 'sathyam_dune_2',
      'time': '01:30 PM',
      'label': '4DX',
      'language': 'Hindi',
      'format': '4DX',
      'date': '2026-02-09',
      'theatre': 'Sathyam Cinemas',
      'movie': 'Dune',
      'price': 1450.0,
    },

    // --- Mayajaal Multiplex (Inception, The Dark Knight, Spider-Man) ---
    {
      'id': 'mayajaal_inception_1',
      'time': '09:00 PM', // Today
      'label': '2D',
      'language': 'Tamil',
      'format': '2D',
      'date': '2026-02-08',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Inception',
      'price': 700.0,
    },
    {
      'id': 'mayajaal_inception_2',
      'time': '10:15 AM',
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'date': '2026-02-09',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Inception',
      'price': 800.0,
    },
    {
      'id': 'mayajaal_darkknight_1',
      'time': '08:45 PM', // Today
      'label': '2D',
      'language': 'English',
      'format': '2D',
      'date': '2026-02-08',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'The Dark Knight',
      'price': 900.0,
    },
    {
      'id': 'mayajaal_darkknight_2',
      'time': '01:45 PM',
      'label': 'IMAX',
      'language': 'English',
      'format': 'IMAX',
      'date': '2026-02-09',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'The Dark Knight',
      'price': 1200.0,
    },
    {
      'id': 'mayajaal_spiderman_1',
      'time': '10:00 PM', // Today
      'label': '3D',
      'language': 'English',
      'format': '3D',
      'date': '2026-02-08',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Spider-Man: No Way Home',
      'price': 1000.0,
    },
    {
      'id': 'mayajaal_spiderman_2',
      'time': '04:30 PM',
      'label': '2D',
      'language': 'Tamil',
      'format': '2D',
      'date': '2026-02-09',
      'theatre': 'Mayajaal Multiplex',
      'movie': 'Spider-Man: No Way Home',
      'price': 850.0,
    },
  ];

  static Future<void> initShowtimes() async {
    final existing = await _getString(_showtimesKey);
    if (existing == null) {
      await _setString(_showtimesKey, jsonEncode(_initialShowtimes));
      debugPrint(
        '⏰ SHOWTIME SERVICE - Initialized with ${_initialShowtimes.length} coverage showtimes (v2)',
      );
    } else {
      final List<dynamic> decoded = jsonDecode(existing);
      debugPrint(
        '⏰ SHOWTIME SERVICE - Already initialized with ${decoded.length} showtimes (v2)',
      );
    }
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
  }
}
