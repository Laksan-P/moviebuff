import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_data.dart';

class TheatreService {
  static const String _theatresKey = 'app_theatres';

  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Initialize theatres if not present
  static Future<void> initTheatres() async {
    final existing = await _getString(_theatresKey);
    List<Map<String, dynamic>> theatres = [];

    if (existing != null) {
      final List<dynamic> decoded = jsonDecode(existing);
      theatres = decoded.map((t) => Map<String, dynamic>.from(t)).toList();
    }

    // Add any missing theatres from AppData
    bool updated = false;
    for (var initialTheatre in AppData.theatres) {
      if (!theatres.any((t) => t['name'] == initialTheatre['name'])) {
        theatres.add(initialTheatre);
        updated = true;
      }
    }

    if (updated || existing == null) {
      await _setString(_theatresKey, jsonEncode(theatres));
      debugPrint(
        '🎭 THEATRE SERVICE - Synced with ${updated ? "new " : ""}default theatres',
      );
    }
  }

  // Get all theatres
  static Future<List<Map<String, dynamic>>> getTheatres() async {
    await initTheatres(); // Ensure we have data
    final json = await _getString(_theatresKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((t) => Map<String, dynamic>.from(t)).toList();
  }

  // Add a theatre (marks as admin-managed local row).
  static Future<void> addTheatre(Map<String, dynamic> theatre) async {
    final theatres = await getTheatres();
    theatres.removeWhere(
      (t) => t['name'] == theatre['name'] && t['_adminLocal'] == true,
    );
    final row = Map<String, dynamic>.from(theatre);
    row['_adminLocal'] = true;
    theatres.add(row);
    await _setString(_theatresKey, jsonEncode(theatres));
    debugPrint('🛠️ ADMIN CRUD - Added theatre: ${row['name']}');
  }

  // Update a theatre
  static Future<void> updateTheatre(
    int index,
    Map<String, dynamic> updatedTheatre,
  ) async {
    final theatres = await getTheatres();
    if (index >= 0 && index < theatres.length) {
      final merged = Map<String, dynamic>.from(updatedTheatre);
      if (theatres[index]['_adminLocal'] == true) {
        merged['_adminLocal'] = true;
      }
      theatres[index] = merged;
      await _setString(_theatresKey, jsonEncode(theatres));
      debugPrint('🛠️ ADMIN CRUD - Updated theatre: ${merged['name']}');
    }
  }

  // Remove a theatre by index
  static Future<void> removeTheatre(int index) async {
    final theatres = await getTheatres();
    if (index >= 0 && index < theatres.length) {
      final removed = theatres.removeAt(index);
      await _setString(_theatresKey, jsonEncode(theatres));
      debugPrint(
        '🛠️ ADMIN CRUD - Deleted theatre: ${removed['name']}',
      );
    }
  }

  static Future<void> removeTheatreByName(String name) async {
    final theatres = await getTheatres();
    final index = theatres.indexWhere((t) => t['name'] == name);
    if (index >= 0) {
      await removeTheatre(index);
    }
  }
}
