import 'package:flutter/foundation.dart';

import 'api_service.dart';

class ShowtimeService {
  static Future<List<Map<String, dynamic>>> getShowtimes({
    int? movieId,
    int? theatreId,
  }) async {
    final list = await ApiService.fetchShowtimes(
      movieId: movieId,
      theatreId: theatreId,
    );
    debugPrint('⏰ SHOWTIME SERVICE - Loaded ${list.length} showtimes from API');
    return list;
  }

  static Future<List<Map<String, dynamic>>> getCustomerShowtimes(
    List<Map<String, dynamic>> mergedMovies, {
    int? movieId,
    int? theatreId,
  }) async {
    final all = await getShowtimes(movieId: movieId, theatreId: theatreId);
    if (mergedMovies.isEmpty) return all;

    final titles = mergedMovies
        .map((m) => (m['title'] ?? '').toString().toLowerCase().trim())
        .where((t) => t.isNotEmpty)
        .toSet();

    return all.where((st) {
      final title = (st['movie'] ?? '').toString().toLowerCase().trim();
      return titles.contains(title);
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAdminMergedShowtimes(
    List<Map<String, dynamic>> mergedMovies,
  ) async {
    return getCustomerShowtimes(mergedMovies);
  }

  static Future<void> addShowtime(Map<String, dynamic> showtime) async {
    await _ensureForeignKeys(showtime);
    await ApiService.createShowtime(showtime);
    debugPrint(
      '🛠️ ADMIN CRUD - Created showtime via API: ${showtime['movie']} @ ${showtime['theatre']}',
    );
  }

  static Future<void> updateShowtime(
    String id,
    Map<String, dynamic> updated,
  ) async {
    await _ensureForeignKeys(updated);
    await ApiService.updateShowtime(int.parse(id), updated);
    debugPrint('🛠️ ADMIN CRUD - Updated showtime via API: $id');
  }

  static Future<void> deleteShowtime(String id) async {
    await ApiService.deleteShowtime(int.parse(id));
    debugPrint('🛠️ ADMIN CRUD - Deleted showtime via API: $id');
  }

  static Future<void> _ensureForeignKeys(Map<String, dynamic> row) async {
    if (row['movie_id'] == null && row['movie'] != null) {
      final movies = await ApiService.fetchMovies();
      final title = row['movie'].toString().toLowerCase().trim();
      final match = movies.firstWhere(
        (m) => (m['title'] ?? '').toString().toLowerCase().trim() == title,
        orElse: () => {},
      );
      if (match['id'] != null) row['movie_id'] = match['id'];
    }
    if (row['theatre_id'] == null && row['theatre'] != null) {
      final theatres = await ApiService.fetchTheatres();
      final name = row['theatre'].toString().toLowerCase().trim();
      final match = theatres.firstWhere(
        (t) => (t['name'] ?? '').toString().toLowerCase().trim() == name,
        orElse: () => {},
      );
      if (match['id'] != null) row['theatre_id'] = match['id'];
    }
  }

  static bool isShowtimePassed(String timeStr, String dateStr) {
    try {
      final now = DateTime.now();
      final showDate = DateTime.parse(dateStr);
      final normalizedNow = DateTime(now.year, now.month, now.day);
      if (showDate.isBefore(normalizedNow)) return true;
      if (showDate.isAfter(normalizedNow)) return false;

      final parts = timeStr.trim().split(' ');
      if (parts.length != 2) return false;

      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final amPm = parts[1].toUpperCase();

      if (amPm == 'PM' && hour != 12) hour += 12;
      if (amPm == 'AM' && hour == 12) hour = 0;

      final showTime = DateTime(now.year, now.month, now.day, hour, minute);
      return now.isAfter(showTime);
    } catch (e) {
      debugPrint('⏰ TIME ERROR ($timeStr, $dateStr): $e');
      return false;
    }
  }
}
