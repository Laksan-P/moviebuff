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
    if (existing == null) {
      // Seed with initial theatres from AppData
      await _setString(_theatresKey, jsonEncode(AppData.theatres));
      debugPrint('🎭 THEATRE SERVICE - Initialized with default theatres');
    }
  }

  // Get all theatres
  static Future<List<Map<String, dynamic>>> getTheatres() async {
    await initTheatres(); // Ensure we have data
    final json = await _getString(_theatresKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((t) => Map<String, dynamic>.from(t)).toList();
  }

  // Add a theatre
  static Future<void> addTheatre(Map<String, dynamic> theatre) async {
    final theatres = await getTheatres();
    theatres.add(theatre);
    await _setString(_theatresKey, jsonEncode(theatres));
    debugPrint('🎭 THEATRE SERVICE - Added: ${theatre['name']}');
  }

  // Update a theatre
  static Future<void> updateTheatre(
    int index,
    Map<String, dynamic> updatedTheatre,
  ) async {
    final theatres = await getTheatres();
    if (index >= 0 && index < theatres.length) {
      theatres[index] = updatedTheatre;
      await _setString(_theatresKey, jsonEncode(theatres));
      debugPrint('🎭 THEATRE SERVICE - Updated: ${updatedTheatre['name']}');
    }
  }

  // Remove a theatre by index
  static Future<void> removeTheatre(int index) async {
    final theatres = await getTheatres();
    if (index >= 0 && index < theatres.length) {
      final removed = theatres.removeAt(index);
      await _setString(_theatresKey, jsonEncode(theatres));
      debugPrint('🎭 THEATRE SERVICE - Removed: ${removed['name']}');
    }
  }
}
