import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

class ApiResult<T> {
  final bool ok;
  final T? data;
  final String? error;
  final int? statusCode;
  ApiResult.success(this.data, {this.statusCode})
      : ok = true,
        error = null;
  ApiResult.failure(this.error, {this.statusCode})
      : ok = false,
        data = null;
}

/// Thin client for the SSP Laravel API (Jetstream + Sanctum tokens).
///
/// Accepts both common Laravel response shapes:
///
///   Shape A:  { "token": "...", "user": { ... } }
///
///   Shape B:  { "status": true, "message": "...",
///               "data": { "token": "...", "user": { ... } } }
class ApiService {
  static const _tokenKey = 'sanctum_token';

  // -------- token storage --------

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint('🔑 API - Saved Sanctum token (len=${token.length})');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint('🔑 API - Cleared Sanctum token');
  }

  static Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // -------- logging helpers --------

  static String _maskPasswords(Map<String, dynamic> body) {
    final masked = Map<String, dynamic>.from(body);
    for (final key in ['password', 'password_confirmation']) {
      if (masked.containsKey(key)) {
        final v = masked[key]?.toString() ?? '';
        masked[key] = v.isEmpty ? '<empty>' : '***(${v.length} chars)';
      }
    }
    return jsonEncode(masked);
  }

  static void _logRequest(String tag, String method, Uri uri,
      Map<String, dynamic>? body, Duration timeout) {
    debugPrint('🌐 $tag ─────────────────────────────────────');
    debugPrint('🌐 $tag → $method $uri');
    debugPrint('🌐 $tag   timeout: ${timeout.inSeconds}s');
    if (body != null) {
      debugPrint('🌐 $tag   body: ${_maskPasswords(body)}');
    }
  }

  static void _logResponse(String tag, http.Response resp, Stopwatch sw) {
    debugPrint('🌐 $tag ← ${resp.statusCode} in ${sw.elapsedMilliseconds}ms');
    final body = resp.body;
    final preview = body.length > 800 ? '${body.substring(0, 800)}…' : body;
    debugPrint('🌐 $tag   raw body: $preview');
  }

  /// Parses a Laravel response and extracts `{ token, user }` from either
  /// the top level or the `data` envelope.
  static Map<String, dynamic>? _extractAuthPayload(http.Response resp) {
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);

      // Shape B envelope (`status`, `message`, `data`)
      Map<String, dynamic> root = m;
      if (m['data'] is Map) {
        root = Map<String, dynamic>.from(m['data'] as Map);
      }

      final token =
          (root['token'] ?? root['access_token'] ?? root['plainTextToken'])
              ?.toString();
      Map<String, dynamic>? user;
      if (root['user'] is Map) {
        user = Map<String, dynamic>.from(root['user'] as Map);
      } else if (m['user'] is Map) {
        user = Map<String, dynamic>.from(m['user'] as Map);
      }

      return {
        if (token != null && token.isNotEmpty) 'token': token,
        if (user != null) ...user,
      };
    } catch (e) {
      debugPrint('🌐 API - Could not parse auth payload: $e');
      return null;
    }
  }

  // -------- auth --------

  static Future<ApiResult<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    const tag = 'API LOGIN';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/login');
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'device_name': 'moviebuff-android',
    };
    _logRequest(tag, 'POST', uri, body, AppConfig.httpTimeout);
    final sw = Stopwatch()..start();

    try {
      final resp = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(AppConfig.httpTimeout);
      sw.stop();
      _logResponse(tag, resp, sw);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final payload = _extractAuthPayload(resp);
        if (payload == null) {
          return ApiResult.failure(
            'API returned ${resp.statusCode} but response was unparseable',
            statusCode: resp.statusCode,
          );
        }
        final token = payload['token']?.toString();
        if (token != null && token.isNotEmpty) await _saveToken(token);

        // Build user map (strip token from user payload)
        final user = Map<String, dynamic>.from(payload)..remove('token');
        if (user['email'] == null) user['email'] = email;

        debugPrint(
          '✅ $tag OK — token=${token != null} user.email=${user['email']}',
        );
        return ApiResult.success(user, statusCode: resp.statusCode);
      }

      final msg = _extractMessage(resp);
      debugPrint('❌ $tag fail — $msg');
      return ApiResult.failure(msg, statusCode: resp.statusCode);
    } on SocketException catch (e) {
      sw.stop();
      debugPrint('❌ $tag SocketException after ${sw.elapsedMilliseconds}ms: $e');
      return ApiResult.failure('No connection to server');
    } on TimeoutException {
      sw.stop();
      debugPrint(
        '❌ $tag TimeoutException after ${sw.elapsedMilliseconds}ms '
        '(limit ${AppConfig.httpTimeout.inSeconds}s)',
      );
      return ApiResult.failure(
        'Server timeout after ${AppConfig.httpTimeout.inSeconds}s',
      );
    } catch (e) {
      sw.stop();
      debugPrint('❌ $tag error after ${sw.elapsedMilliseconds}ms: $e');
      return ApiResult.failure('Unable to reach server: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    const tag = 'API REGISTER';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/register');
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'device_name': 'moviebuff-android',
    };
    _logRequest(tag, 'POST', uri, body, AppConfig.httpTimeout);
    final sw = Stopwatch()..start();

    try {
      final resp = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(AppConfig.httpTimeout);
      sw.stop();
      _logResponse(tag, resp, sw);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final payload = _extractAuthPayload(resp);
        if (payload == null) {
          return ApiResult.failure(
            'API returned ${resp.statusCode} but response was unparseable',
            statusCode: resp.statusCode,
          );
        }
        final token = payload['token']?.toString();
        if (token != null && token.isNotEmpty) await _saveToken(token);

        final user = Map<String, dynamic>.from(payload)..remove('token');
        if (user['name'] == null) user['name'] = name;
        if (user['email'] == null) user['email'] = email;

        debugPrint(
          '✅ $tag OK — token=${token != null} user.email=${user['email']}',
        );
        return ApiResult.success(user, statusCode: resp.statusCode);
      }

      final msg = _extractMessage(resp);
      debugPrint('❌ $tag fail — $msg');
      return ApiResult.failure(msg, statusCode: resp.statusCode);
    } on SocketException catch (e) {
      sw.stop();
      debugPrint('❌ $tag SocketException after ${sw.elapsedMilliseconds}ms: $e');
      return ApiResult.failure('No connection to server');
    } on TimeoutException {
      sw.stop();
      debugPrint(
        '❌ $tag TimeoutException after ${sw.elapsedMilliseconds}ms '
        '(limit ${AppConfig.httpTimeout.inSeconds}s)',
      );
      return ApiResult.failure(
        'Server timeout after ${AppConfig.httpTimeout.inSeconds}s',
      );
    } catch (e) {
      sw.stop();
      debugPrint('❌ $tag error after ${sw.elapsedMilliseconds}ms: $e');
      return ApiResult.failure('Unable to reach server: $e');
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/logout');
    try {
      await http
          .post(uri, headers: _headers(token: token))
          .timeout(AppConfig.httpTimeout);
      debugPrint('🌐 API LOGOUT - sent');
    } catch (e) {
      debugPrint('🌐 API LOGOUT - failed: $e');
    }
    await clearToken();
  }

  // -------- data --------

  /// GET /api/movies — supports a list or `{ data: [...] }` envelope.
  static Future<List<Map<String, dynamic>>?> fetchApiMovies() async {
    const tag = 'API MOVIES';
    final token = await getToken();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/movies');
    _logRequest(tag, 'GET', uri, null, AppConfig.httpTimeout);
    final sw = Stopwatch()..start();

    try {
      final resp = await http
          .get(uri, headers: _headers(token: token))
          .timeout(AppConfig.httpTimeout);
      sw.stop();
      _logResponse(tag, resp, sw);

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = (decoded is List)
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : const []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      sw.stop();
      debugPrint('❌ $tag error after ${sw.elapsedMilliseconds}ms: $e');
    }
    return null;
  }

  /// Light-weight reachability probe used by the in-app "Test SSP API" button.
  ///
  /// Tries (in order): `GET /user` (if token), then `GET /movies`.
  /// Returns a success result describing which endpoint responded, or a
  /// failure result with the raw error.
  static Future<ApiResult<String>> testConnection() async {
    const tag = 'API TEST';
    final token = await getToken();
    final endpoints = <String>[
      if (token != null) '/user',
      '/movies',
    ];

    for (final path in endpoints) {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      _logRequest(tag, 'GET', uri, null, AppConfig.httpTimeout);
      final sw = Stopwatch()..start();
      try {
        final resp = await http
            .get(uri, headers: _headers(token: token))
            .timeout(AppConfig.httpTimeout);
        sw.stop();
        _logResponse(tag, resp, sw);

        if (resp.statusCode >= 200 && resp.statusCode < 500) {
          // 2xx/4xx both prove the server is reachable.
          return ApiResult.success(
            'OK from $path · HTTP ${resp.statusCode} · '
            '${sw.elapsedMilliseconds}ms',
            statusCode: resp.statusCode,
          );
        }
      } on TimeoutException {
        sw.stop();
        return ApiResult.failure(
          'Timeout after ${AppConfig.httpTimeout.inSeconds}s on $path',
        );
      } on SocketException catch (e) {
        sw.stop();
        return ApiResult.failure('No connection on $path: ${e.message}');
      } catch (e) {
        sw.stop();
        return ApiResult.failure('Error on $path: $e');
      }
    }
    return ApiResult.failure('All probe endpoints returned 5xx');
  }

  static String _extractMessage(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);
      if (body is Map) {
        if (body['message'] is String) return body['message'] as String;
        if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          for (final v in errors.values) {
            if (v is List && v.isNotEmpty) return v.first.toString();
          }
        }
      }
    } catch (_) {}
    return 'HTTP ${resp.statusCode}';
  }
}
