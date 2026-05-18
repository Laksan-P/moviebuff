import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only profile photo path (SharedPreferences + device file path).
/// Scoped per logged-in user email. Not synced to SSP backend.
class ProfilePhotoService {
  ProfilePhotoService._();

  /// Legacy global key from older builds. Intentionally not read for display so
  /// a new user never inherits another account's photo; removed on first save.
  static const _legacyGlobalKey = 'profile_pic_path';

  /// Visible prefix for debugging / prefs inspection.
  static const prefsKeyPrefix = 'profile_photo_path_';

  /// Sanitize email for a stable SharedPreferences key segment.
  static String sanitizedEmailSegment(String? email) {
    final e = (email ?? '').toLowerCase().trim();
    if (e.isEmpty) return '';
    var s = e.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_|_$'), '');
    return s;
  }

  static String? prefsKeyFor(String? email) {
    final seg = sanitizedEmailSegment(email);
    if (seg.isEmpty) return null;
    return '$prefsKeyPrefix$seg';
  }

  static String _logLabel(String? email) {
    final e = email?.trim() ?? '';
    if (e.isEmpty) return '(no email)';
    return e;
  }

  static Future<void> _removeLegacyGlobal(SharedPreferences prefs) async {
    if (prefs.containsKey(_legacyGlobalKey)) {
      await prefs.remove(_legacyGlobalKey);
      debugPrint('📷 PROFILE PHOTO - Discarded legacy global key (not used for display)');
    }
  }

  static Future<String?> getValidPath(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefsKeyFor(email);
    final label = _logLabel(email);

    if (key == null) {
      debugPrint('👤 PROFILE - No saved profile photo for $label');
      return null;
    }

    final path = prefs.getString(key);
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      debugPrint('📷 PROFILE PHOTO - Loaded for $label');
      return path;
    }

    debugPrint('👤 PROFILE - No saved profile photo for $label');
    return null;
  }

  static Future<void> savePath(String? email, String path) async {
    final key = prefsKeyFor(email);
    final label = _logLabel(email);
    if (key == null) {
      debugPrint('📷 PROFILE PHOTO - Saved skipped (no user email)');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, path);
    await _removeLegacyGlobal(prefs);
    debugPrint('📷 PROFILE PHOTO - Saved for $label');
  }

  static Future<void> clear(String? email) async {
    final key = prefsKeyFor(email);
    final label = _logLabel(email);
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    debugPrint('📷 PROFILE PHOTO - Removed for $label');
  }
}
