import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the authenticated session returned by the Laravel API.
/// Does not perform local login or store demo users.
class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<bool> _getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> saveLoginSession(
    String name,
    String email, {
    bool isAdmin = false,
  }) async {
    await _setBool(_isLoggedInKey, true);
    await _setString(_userNameKey, name);
    await _setString(_userEmailKey, email);
    await _setString(_userRoleKey, isAdmin ? 'admin' : 'customer');
    debugPrint('✅ Session saved for: $name ($email) [admin=$isAdmin]');
  }

  static Future<bool> isLoggedIn() async => _getBool(_isLoggedInKey);

  static Future<bool> isAdmin() async {
    final role = await _getString(_userRoleKey);
    return role == 'admin';
  }

  static Future<String?> getUserName() => _getString(_userNameKey);

  static Future<String?> getUserEmail() => _getString(_userEmailKey);

  static Future<void> logout() async {
    await _remove(_isLoggedInKey);
    await _remove(_userNameKey);
    await _remove(_userEmailKey);
    await _remove(_userRoleKey);
    debugPrint('✅ Session cleared');
  }
}
