import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _usersKey = 'registered_users';
  static const String _userRoleKey = 'user_role';

  // Unified storage helpers using SharedPreferences
  static Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    debugPrint('💾 STORAGE - Set $key: $value');
  }

  static Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    debugPrint('💾 STORAGE - Set $key: $value');
  }

  static Future<String?> _getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    debugPrint('💾 STORAGE - Get $key: $value');
    return value;
  }

  static Future<bool> _getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key) ?? false;
    debugPrint('💾 STORAGE - Get $key: $value');
    return value;
  }

  static Future<void> _remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    debugPrint('💾 STORAGE - Removed $key');
  }

  // Save Login Session
  static Future<void> saveLoginSession(
    String name,
    String email, {
    bool isAdmin = false,
  }) async {
    await _setBool(_isLoggedInKey, true);
    await _setString(_userNameKey, name);
    await _setString(_userEmailKey, email);
    await _setString(_userRoleKey, isAdmin ? 'admin' : 'user');
    debugPrint(
      '✅ Session saved for: $name ($email) [Role: ${isAdmin ? 'admin' : 'user'}]',
    );
  }

  // Check Login Status
  static Future<bool> isLoggedIn() async {
    return await _getBool(_isLoggedInKey);
  }

  // Check if current user is Admin
  static Future<bool> isAdmin() async {
    final role = await _getString(_userRoleKey);
    return role == 'admin';
  }

  // Get User Name
  static Future<String?> getUserName() async {
    return await _getString(_userNameKey);
  }

  // Get User Email
  static Future<String?> getUserEmail() async {
    return await _getString(_userEmailKey);
  }

  // Clear Session (Logout)
  static Future<void> logout() async {
    await _remove(_isLoggedInKey);
    await _remove(_userNameKey);
    await _remove(_userEmailKey);
    await _remove(_userRoleKey);
    debugPrint('✅ Session cleared');
  }

  // Register New User
  static Future<bool> registerUser(
    String name,
    String email,
    String password, {
    String role = 'user',
  }) async {
    final usersJson = await _getString(_usersKey) ?? '[]';
    final List<dynamic> users = jsonDecode(usersJson);

    final normalizedEmail = email
        .trim(); // Only trim, don't lowercase for storage
    final uniquenessEmail = email
        .trim()
        .toLowerCase(); // Used only for uniqueness check

    debugPrint('🔵 REGISTER - Input email: "$email"');
    debugPrint('🔵 REGISTER - Storage email: "$normalizedEmail"');

    // Check if user already exists (case-insensitive check for uniqueness)
    if (users.any(
      (u) => (u['email'] as String).trim().toLowerCase() == uniquenessEmail,
    )) {
      debugPrint('🔴 REGISTER - User already exists!');
      return false;
    }

    final newUser = {
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password.trim(),
      'role': role,
    };

    users.add(newUser);
    debugPrint('🔵 REGISTER - Adding user: $newUser');

    final jsonString = jsonEncode(users);
    await _setString(_usersKey, jsonString);

    // Verify it was saved locally
    final verifyJson = await _getString(_usersKey) ?? '[]';
    final success = verifyJson == jsonString;
    debugPrint('🔵 REGISTER - Verification: ${success ? "SUCCESS" : "FAILED"}');
    debugPrint('🔵 REGISTER - Total users now: ${users.length}');

    return success;
  }

  // Authenticate User
  static Future<Map<String, dynamic>?> authenticateUser(
    String email,
    String password,
  ) async {
    final usersJson = await _getString(_usersKey) ?? '[]';
    final List<dynamic> users = jsonDecode(usersJson);

    debugPrint('🟢 LOGIN - Raw users JSON: $usersJson');
    debugPrint('🟢 LOGIN - Total users in storage: ${users.length}');
    debugPrint('🟢 LOGIN - Input email: "$email"');

    final normalizedEmail = email.trim(); // No lowercase for exact match
    final normalizedPassword = password.trim();

    debugPrint('🟢 LOGIN - Search email: "$normalizedEmail"');

    // Hardcoded Admin Credentials Fallback
    if (normalizedEmail == 'admin@moviebuff.com' &&
        normalizedPassword == 'admin123') {
      debugPrint('✅ LOGIN - Hardcoded Admin authenticated');
      return {
        'name': 'Administrator',
        'email': 'admin@moviebuff.com',
        'role': 'admin',
      };
    }

    try {
      final user = users.firstWhere(
        (u) =>
            (u['email'] as String).trim() == normalizedEmail &&
            (u['password'] as String).trim() == normalizedPassword,
      );
      debugPrint('✅ LOGIN - Authentication successful for: ${user['email']}');
      final role =
          (user['role'] as String?) ??
          (normalizedEmail.contains('admin') ? 'admin' : 'user');

      return {
        'name': user['name'] as String,
        'email': user['email'] as String,
        'role': role,
      };
    } catch (e) {
      debugPrint('❌ LOGIN - Authentication failed: $e');
      return null;
    }
  }
}
