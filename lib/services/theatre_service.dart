import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Theatres loaded and mutated exclusively through the Laravel API.
class TheatreService {
  static Future<List<Map<String, dynamic>>> getTheatres() async {
    final theatres = await ApiService.fetchTheatres();
    debugPrint('🎭 THEATRE SERVICE - Loaded ${theatres.length} theatres from API');
    return theatres;
  }

  static Future<void> addTheatre(Map<String, dynamic> theatre) async {
    final row = Map<String, dynamic>.from(theatre);
    row.putIfAbsent('total_seats', () => 120);
    await ApiService.createTheatre(row);
    debugPrint('🛠️ ADMIN CRUD - Created theatre via API: ${theatre['name']}');
  }

  static Future<void> updateTheatre(
    dynamic indexOrId,
    Map<String, dynamic> updatedTheatre,
  ) async {
    final id = _resolveId(indexOrId, updatedTheatre);
    await ApiService.updateTheatre(id, updatedTheatre);
    debugPrint(
      '🛠️ ADMIN CRUD - Updated theatre via API: ${updatedTheatre['name']}',
    );
  }

  static Future<void> removeTheatre(int index) async {
    throw UnsupportedError(
      'Use removeTheatreById — list index is not stable with API data.',
    );
  }

  static Future<void> removeTheatreByName(String name) async {
    throw UnsupportedError(
      'Use removeTheatreById — delete theatres by database id.',
    );
  }

  static Future<void> removeTheatreById(int id) async {
    await ApiService.deleteTheatre(id);
    debugPrint('🛠️ ADMIN CRUD - Deleted theatre via API: $id');
  }

  static int _resolveId(
    dynamic indexOrId,
    Map<String, dynamic>? theatre,
  ) {
    final fromTheatre = theatre?['id'];
    if (fromTheatre != null) return int.parse(fromTheatre.toString());
    if (indexOrId is int && indexOrId > 0) return indexOrId;
    final parsed = int.tryParse(indexOrId?.toString() ?? '');
    if (parsed != null) return parsed;
    throw ArgumentError('Theatre id is required for API update/delete.');
  }
}
