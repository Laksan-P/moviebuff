import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only profile photo path (SharedPreferences + device file path).
/// Not synced to SSP backend.
class ProfilePhotoService {
  ProfilePhotoService._();

  /// Same key as earlier Device screen builds — keeps existing saved photos.
  static const prefsKey = 'profile_pic_path';

  static Future<String?> getValidPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(prefsKey);
    if (path == null || path.isEmpty) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  static Future<void> savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, path);
    debugPrint('📷 PROFILE PHOTO - saved locally');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
