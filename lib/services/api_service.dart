import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import 'api_mappers.dart';

class ApiResult<T> {
  final bool ok;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResult.success(this.data, {this.statusCode})
      : ok = true,
        error = null,
        errors = null;

  ApiResult.failure(
    this.error, {
    this.statusCode,
    this.errors,
  })  : ok = false,
        data = null;
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

/// Centralized HTTP client for the Laravel SSP API (Sanctum tokens).
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

  // -------- logging --------

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

  static void _logRequest(
    String tag,
    String method,
    Uri uri,
    Map<String, dynamic>? body,
  ) {
    debugPrint('🌐 $tag → $method $uri');
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

  // -------- response parsing --------

  static dynamic _decodeBody(http.Response resp) {
    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body);
  }

  static Map<String, dynamic>? _asMap(dynamic decoded) {
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  static Map<String, dynamic>? _unwrapData(Map<String, dynamic> root) {
    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data'] as Map);
    }
    return root;
  }

  static String _extractMessage(http.Response resp) {
    try {
      final body = _decodeBody(resp);
      final map = _asMap(body);
      if (map == null) return 'HTTP ${resp.statusCode}';

      if (map['message'] is String && (map['message'] as String).isNotEmpty) {
        return map['message'] as String;
      }

      if (map['errors'] is Map) {
        final errors = map['errors'] as Map;
        for (final v in errors.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
        }
      }
    } catch (_) {}
    return 'HTTP ${resp.statusCode}';
  }

  static Map<String, dynamic>? _extractErrors(http.Response resp) {
    try {
      final body = _decodeBody(resp);
      final map = _asMap(body);
      if (map != null && map['errors'] is Map) {
        return Map<String, dynamic>.from(map['errors'] as Map);
      }
    } catch (_) {}
    return null;
  }

  static ApiResult<T> _mapStatus<T>(http.Response resp, T? data) {
    final code = resp.statusCode;
    if (code >= 200 && code < 300) {
      // Laravel may return HTTP 200 with only {message} on business-rule failures.
      if (_isMessageOnlyErrorBody(resp)) {
        final msg = _extractMessage(resp);
        debugPrint('⚠️ API - message-only 2xx treated as failure: $msg');
        return ApiResult.failure(
          msg.isNotEmpty ? msg : 'Request failed.',
          statusCode: code,
        );
      }
      return ApiResult.success(data, statusCode: code);
    }

    final msg = _extractMessage(resp);
    return ApiResult.failure(
      _friendlyError(code, msg),
      statusCode: code,
      errors: _extractErrors(resp),
    );
  }

  static bool _isMessageOnlyErrorBody(http.Response resp) {
    if (resp.body.isEmpty) return false;
    try {
      final map = _asMap(_decodeBody(resp));
      if (map == null) return false;
      final hasMessage = map['message']?.toString().trim().isNotEmpty ?? false;
      final hasData = map['data'] != null;
      final hasErrors = map['errors'] != null;
      return hasMessage && !hasData && !hasErrors;
    } catch (_) {
      return false;
    }
  }

  static String _friendlyError(int code, String msg) {
    switch (code) {
      case 401:
        return 'Unauthorized. Please sign in again.';
      case 403:
        return 'You do not have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 422:
        return msg.isNotEmpty ? msg : 'Validation failed.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return msg.isNotEmpty ? msg : 'Request failed (HTTP $code).';
    }
  }

  static Map<String, dynamic>? _extractAuthPayload(http.Response resp) {
    try {
      final decoded = _decodeBody(resp);
      final map = _asMap(decoded);
      if (map == null) return null;

      final root = _unwrapData(map) ?? map;
      final token = (root['token'] ?? root['access_token'] ?? root['plainTextToken'])
          ?.toString();
      Map<String, dynamic>? user;
      if (root['user'] is Map) {
        user = Map<String, dynamic>.from(root['user'] as Map);
      } else if (map['user'] is Map) {
        user = Map<String, dynamic>.from(map['user'] as Map);
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

  static List<Map<String, dynamic>> _mapFromListItems(List list) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) {
        debugPrint('⚠️ API - Skipping non-object list item at index $i');
        continue;
      }
      try {
        out.add(Map<String, dynamic>.from(item));
      } catch (e) {
        debugPrint('⚠️ API - Could not map list item at index $i: $e');
      }
    }
    return out;
  }

  static List<Map<String, dynamic>> _extractList(
    dynamic decoded, {
    String? dataKey,
  }) {
    if (decoded is List) {
      return _mapFromListItems(decoded);
    }
    final map = _asMap(decoded);
    if (map == null) return [];

    final data = _unwrapData(map) ?? map;
    if (dataKey != null && data[dataKey] is List) {
      return _mapFromListItems(data[dataKey] as List);
    }
    if (data['data'] is List) {
      return _mapFromListItems(data['data'] as List);
    }
    return [];
  }

  static List<Map<String, dynamic>> _mapCatalogueList(
    dynamic decoded, {
    required String dataKey,
    required Map<String, dynamic> Function(Map<String, dynamic>) mapper,
    required String tag,
  }) {
    final raw = _extractList(decoded, dataKey: dataKey);
    debugPrint('📦 $tag - extracted ${raw.length} raw $dataKey');
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      try {
        out.add(mapper(raw[i]));
      } catch (e, st) {
        debugPrint('❌ $tag parse exception item[$i]: $e');
        debugPrint('$st');
      }
    }
    debugPrint('📦 $tag - parsed ${out.length}/${raw.length} $dataKey');
    return out;
  }

  static Map<String, dynamic>? _extractObject(
    dynamic decoded, {
    String? dataKey,
  }) {
    final map = _asMap(decoded);
    if (map == null) return null;
    final data = _unwrapData(map) ?? map;
    if (dataKey != null && data[dataKey] is Map) {
      return Map<String, dynamic>.from(data[dataKey] as Map);
    }
    for (final key in ['movie', 'theatre', 'showtime', 'booking']) {
      if (data[key] is Map) {
        return Map<String, dynamic>.from(data[key] as Map);
      }
    }
    return data;
  }

  // -------- core request --------

  static Future<ApiResult<T>> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool auth = true,
    T Function(dynamic decoded)? parser,
    String tag = 'API',
  }) async {
    final token = auth ? await getToken() : null;
    if (auth && token == null) {
      return ApiResult.failure('Not authenticated.', statusCode: 401);
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    _logRequest(tag, method, uri, body);
    final sw = Stopwatch()..start();

    try {
      final headers = _headers(token: token);
      final encodedBody = body == null ? null : jsonEncode(body);

      late http.Response resp;
      switch (method) {
        case 'GET':
          resp = await http
              .get(uri, headers: headers)
              .timeout(AppConfig.httpTimeout);
          break;
        case 'POST':
          resp = await http
              .post(uri, headers: headers, body: encodedBody)
              .timeout(AppConfig.httpTimeout);
          break;
        case 'PUT':
          resp = await http
              .put(uri, headers: headers, body: encodedBody)
              .timeout(AppConfig.httpTimeout);
          break;
        case 'DELETE':
          resp = await http
              .delete(uri, headers: headers)
              .timeout(AppConfig.httpTimeout);
          break;
        default:
          return ApiResult.failure('Unsupported method: $method');
      }

      sw.stop();
      _logResponse(tag, resp, sw);

      if (resp.statusCode == 401) {
        await clearToken();
      }

      final decoded = resp.body.isNotEmpty ? _decodeBody(resp) : null;
      T? parsed;
      if (parser != null) {
        try {
          parsed = parser(decoded);
        } catch (e, st) {
          debugPrint(
            '❌ $tag parse exception (HTTP ${resp.statusCode}): $e',
          );
          debugPrint('$st');
          return ApiResult.failure(
            'Failed to parse response: $e',
            statusCode: resp.statusCode,
          );
        }
      } else {
        parsed = decoded as T?;
      }
      return _mapStatus(resp, parsed);
    } on SocketException catch (e) {
      sw.stop();
      debugPrint('❌ $tag SocketException: $e');
      return ApiResult.failure('No connection to server');
    } on TimeoutException {
      sw.stop();
      return ApiResult.failure(
        'Server timeout after ${AppConfig.httpTimeout.inSeconds}s',
      );
    } catch (e) {
      sw.stop();
      debugPrint('❌ $tag error: $e');
      return ApiResult.failure('Unable to reach server: $e');
    }
  }

  static Future<T> _require<T>(ApiResult<T> result, String action) async {
    if (result.ok) return result.data as T;
    throw ApiException(
      result.error ?? 'Failed to $action',
      statusCode: result.statusCode,
      errors: result.errors,
    );
  }

  // -------- auth --------

  static Future<ApiResult<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    const tag = 'API LOGIN';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/login');
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'device_name': 'moviebuff-flutter',
    };
    _logRequest(tag, 'POST', uri, body);
    final sw = Stopwatch()..start();

    try {
      final resp = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(AppConfig.httpTimeout);
      sw.stop();
      _logResponse(tag, resp, sw);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final bodyPreview = resp.body.length > 800
            ? '${resp.body.substring(0, 800)}…'
            : resp.body;
        debugPrint('🔐 API LOGIN raw body: $bodyPreview');

        final payload = _extractAuthPayload(resp);
        if (payload == null) {
          return ApiResult.failure(
            'Login response was unparseable',
            statusCode: resp.statusCode,
          );
        }
        final token = payload['token']?.toString();
        if (token != null && token.isNotEmpty) await _saveToken(token);

        final user = Map<String, dynamic>.from(payload)..remove('token');
        if (user['email'] == null) user['email'] = email.trim();
        debugPrint(
          '🔐 API LOGIN parsed role=${user['role']} '
          'email=${user['email']} keys=${user.keys.join(', ')}',
        );
        return ApiResult.success(user, statusCode: resp.statusCode);
      }

      return ApiResult.failure(
        _friendlyError(resp.statusCode, _extractMessage(resp)),
        statusCode: resp.statusCode,
        errors: _extractErrors(resp),
      );
    } on SocketException {
      return ApiResult.failure('No connection to server');
    } on TimeoutException {
      return ApiResult.failure(
        'Server timeout after ${AppConfig.httpTimeout.inSeconds}s',
      );
    } catch (e) {
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
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': password,
      'device_name': 'moviebuff-flutter',
    };
    _logRequest(tag, 'POST', uri, body);
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
            'Registration response was unparseable',
            statusCode: resp.statusCode,
          );
        }
        final token = payload['token']?.toString();
        if (token != null && token.isNotEmpty) await _saveToken(token);

        final user = Map<String, dynamic>.from(payload)..remove('token');
        if (user['name'] == null) user['name'] = name.trim();
        if (user['email'] == null) user['email'] = email.trim();
        return ApiResult.success(user, statusCode: resp.statusCode);
      }

      return ApiResult.failure(
        _friendlyError(resp.statusCode, _extractMessage(resp)),
        statusCode: resp.statusCode,
        errors: _extractErrors(resp),
      );
    } on SocketException {
      return ApiResult.failure('No connection to server');
    } on TimeoutException {
      return ApiResult.failure(
        'Server timeout after ${AppConfig.httpTimeout.inSeconds}s',
      );
    } catch (e) {
      return ApiResult.failure('Unable to reach server: $e');
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('${AppConfig.apiBaseUrl}/logout'),
              headers: _headers(token: token),
            )
            .timeout(AppConfig.httpTimeout);
      } catch (e) {
        debugPrint('🌐 API LOGOUT - failed: $e');
      }
    }
    await clearToken();
  }

  static Future<ApiResult<Map<String, dynamic>>> getCurrentUser() async {
    return _request<Map<String, dynamic>>(
      method: 'GET',
      path: '/user',
      tag: 'API USER',
      parser: (decoded) => _extractObject(decoded) ?? _asMap(decoded) ?? {},
    );
  }

  // -------- movies --------

  static Future<List<Map<String, dynamic>>> fetchMovies() async {
    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/movies',
      auth: false,
      tag: 'API MOVIES',
      parser: (decoded) => _mapCatalogueList(
        decoded,
        dataKey: 'movies',
        mapper: ApiMappers.movieFromApi,
        tag: 'API MOVIES',
      ),
    );
    debugPrint(
      '🎬 API MOVIES status=${result.statusCode} count=${result.data?.length ?? 0}',
    );
    return _require(result, 'load movies');
  }

  static Future<Map<String, dynamic>> createMovie(
    Map<String, dynamic> movie,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/movies',
      body: ApiMappers.movieToApi(movie),
      tag: 'API MOVIE CREATE',
      parser: (decoded) =>
          ApiMappers.movieFromApi(_extractObject(decoded, dataKey: 'movie') ?? {}),
    );
    return _require(result, 'create movie');
  }

  static Future<Map<String, dynamic>> updateMovie(
    int id,
    Map<String, dynamic> movie,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/movies/$id',
      body: ApiMappers.movieToApi(movie),
      tag: 'API MOVIE UPDATE',
      parser: (decoded) =>
          ApiMappers.movieFromApi(_extractObject(decoded, dataKey: 'movie') ?? {}),
    );
    return _require(result, 'update movie');
  }

  static Future<void> deleteMovie(int id) async {
    final result = await _request<void>(
      method: 'DELETE',
      path: '/movies/$id',
      tag: 'API MOVIE DELETE',
      parser: (_) => null,
    );
    await _require(result, 'delete movie');
  }

  // -------- theatres --------

  static Future<List<Map<String, dynamic>>> fetchTheatres() async {
    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/theatres',
      auth: false,
      tag: 'API THEATRES',
      parser: (decoded) => _mapCatalogueList(
        decoded,
        dataKey: 'theatres',
        mapper: ApiMappers.theatreFromApi,
        tag: 'API THEATRES',
      ),
    );
    debugPrint(
      '🏛️ API THEATRES status=${result.statusCode} count=${result.data?.length ?? 0}',
    );
    return _require(result, 'load theatres');
  }

  static Future<Map<String, dynamic>> createTheatre(
    Map<String, dynamic> theatre,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/theatres',
      body: ApiMappers.theatreToApi(theatre),
      tag: 'API THEATRE CREATE',
      parser: (decoded) => ApiMappers.theatreFromApi(
        _extractObject(decoded, dataKey: 'theatre') ?? {},
      ),
    );
    return _require(result, 'create theatre');
  }

  static Future<Map<String, dynamic>> updateTheatre(
    int id,
    Map<String, dynamic> theatre,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/theatres/$id',
      body: ApiMappers.theatreToApi(theatre),
      tag: 'API THEATRE UPDATE',
      parser: (decoded) => ApiMappers.theatreFromApi(
        _extractObject(decoded, dataKey: 'theatre') ?? {},
      ),
    );
    return _require(result, 'update theatre');
  }

  static Future<void> deleteTheatre(int id) async {
    final result = await _request<void>(
      method: 'DELETE',
      path: '/theatres/$id',
      tag: 'API THEATRE DELETE',
      parser: (_) => null,
    );
    await _require(result, 'delete theatre');
  }

  // -------- showtimes --------

  static Future<List<Map<String, dynamic>>> fetchShowtimes({
    int? movieId,
    int? theatreId,
  }) async {
    final query = <String, String>{};
    if (movieId != null) query['movie_id'] = movieId.toString();
    if (theatreId != null) query['theatre_id'] = theatreId.toString();
    final qs = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/showtimes$qs',
      auth: false,
      tag: 'API SHOWTIMES',
      parser: (decoded) => _mapCatalogueList(
        decoded,
        dataKey: 'showtimes',
        mapper: ApiMappers.showtimeFromApi,
        tag: 'API SHOWTIMES',
      ),
    );
    debugPrint(
      '🎟️ API SHOWTIMES status=${result.statusCode} count=${result.data?.length ?? 0}',
    );
    return _require(result, 'load showtimes');
  }

  static Future<Map<String, dynamic>> createShowtime(
    Map<String, dynamic> showtime,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/showtimes',
      body: ApiMappers.showtimeToApi(showtime),
      tag: 'API SHOWTIME CREATE',
      parser: (decoded) => ApiMappers.showtimeFromApi(
        _extractObject(decoded, dataKey: 'showtime') ?? {},
      ),
    );
    return _require(result, 'create showtime');
  }

  static Future<Map<String, dynamic>> updateShowtime(
    int id,
    Map<String, dynamic> showtime,
  ) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/showtimes/$id',
      body: ApiMappers.showtimeToApi(showtime),
      tag: 'API SHOWTIME UPDATE',
      parser: (decoded) => ApiMappers.showtimeFromApi(
        _extractObject(decoded, dataKey: 'showtime') ?? {},
      ),
    );
    return _require(result, 'update showtime');
  }

  static Future<void> deleteShowtime(int id) async {
    final result = await _request<void>(
      method: 'DELETE',
      path: '/showtimes/$id',
      tag: 'API SHOWTIME DELETE',
      parser: (_) => null,
    );
    await _require(result, 'delete showtime');
  }

  // -------- bookings --------

  static Future<List<Map<String, dynamic>>> fetchMyBookings() async {
    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/bookings',
      tag: 'API BOOKINGS',
      parser: (decoded) =>
          _extractList(decoded, dataKey: 'bookings')
              .map(ApiMappers.bookingFromApi)
              .toList(),
    );
    return _require(result, 'load bookings');
  }

  static Future<List<Map<String, dynamic>>> fetchAllBookings() async {
    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/admin/bookings',
      tag: 'API ADMIN BOOKINGS',
      parser: (decoded) =>
          _extractList(decoded, dataKey: 'bookings')
              .map(ApiMappers.bookingFromApi)
              .toList(),
    );
    return _require(result, 'load admin bookings');
  }

  static Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required String seats,
    required int numberOfTickets,
  }) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/bookings',
      body: {
        'showtime_id': showtimeId,
        'seats': seats,
        'number_of_tickets': numberOfTickets,
      },
      tag: 'API BOOKING CREATE',
      parser: (decoded) => ApiMappers.bookingFromApi(
        _extractObject(decoded, dataKey: 'booking') ?? {},
      ),
    );
    return _require(result, 'create booking');
  }

  static Future<Map<String, dynamic>> confirmBookingPayment(
    int bookingId, {
    String? paymentMethod,
    String? cardNumber,
  }) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/bookings/$bookingId/confirm',
      body: {
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (cardNumber != null) 'card_number': cardNumber,
      },
      tag: 'API BOOKING CONFIRM',
      parser: (decoded) => ApiMappers.bookingFromApi(
        _extractObject(decoded, dataKey: 'booking') ?? {},
      ),
    );
    return _require(result, 'confirm booking');
  }

  static Future<Map<String, dynamic>> requestCancellation(
    int bookingId, {
    required String reason,
    String? comments,
  }) async {
    final result = await _request<Map<String, dynamic>>(
      method: 'POST',
      path: '/bookings/$bookingId/cancel',
      body: {
        'reason': reason,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      },
      tag: 'API BOOKING CANCEL',
      parser: (decoded) => ApiMappers.bookingFromApi(
        _extractObject(decoded, dataKey: 'booking') ?? {},
      ),
    );

    debugPrint(
      '🚫 API BOOKING CANCEL response status=${result.statusCode} '
      'ok=${result.ok} error=${result.error}',
    );

    final booking = await _require(result, 'request cancellation');
    debugPrint(
      '🚫 API BOOKING CANCEL body booking id=${booking['id']} '
      'api_status=${booking['_api_status']} label=${booking['status']}',
    );

    final statusKey = ApiMappers.effectiveBookingStatusKey(booking);
    if (statusKey != 'cancellation_requested') {
      throw ApiException(
        'Cancellation was not applied (status=$statusKey).',
        statusCode: result.statusCode,
      );
    }

    return booking;
  }

  static Future<List<Map<String, dynamic>>> fetchPendingCancellations() async {
    final result = await _request<List<Map<String, dynamic>>>(
      method: 'GET',
      path: '/admin/cancellations/pending',
      tag: 'API PENDING CANCELLATIONS',
      parser: (decoded) =>
          _extractList(decoded, dataKey: 'cancellations')
              .map(ApiMappers.bookingFromApi)
              .toList(),
    );
    return _require(result, 'load pending cancellations');
  }

  static Future<void> approveCancellation(int bookingId) async {
    final result = await _request<void>(
      method: 'POST',
      path: '/admin/cancellations/$bookingId/approve',
      tag: 'API CANCEL APPROVE',
      parser: (_) => null,
    );
    await _require(result, 'approve cancellation');
  }

  static Future<void> rejectCancellation(int bookingId) async {
    final result = await _request<void>(
      method: 'POST',
      path: '/admin/cancellations/$bookingId/reject',
      tag: 'API CANCEL REJECT',
      parser: (_) => null,
    );
    await _require(result, 'reject cancellation');
  }

  static Future<List<String>> fetchBookedSeats(int showtimeId) async {
    final result = await _request<List<String>>(
      method: 'GET',
      path: '/showtimes/$showtimeId/booked-seats',
      auth: false,
      tag: 'API BOOKED SEATS',
      parser: (decoded) {
        final map = _asMap(decoded);
        final data = map != null ? (_unwrapData(map) ?? map) : null;
        final seats = data?['seats'] ?? data?['booked_seats'];
        if (seats is List) return seats.map((e) => e.toString()).toList();
        return <String>[];
      },
    );
    return _require(result, 'load booked seats');
  }

  static Future<ApiResult<String>> testConnection() async {
    const tag = 'API TEST';
    final token = await getToken();
    final endpoints = <String>[
      if (token != null) '/user',
      '/movies',
    ];

    for (final path in endpoints) {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      _logRequest(tag, 'GET', uri, null);
      final sw = Stopwatch()..start();
      try {
        final resp = await http
            .get(uri, headers: _headers(token: token))
            .timeout(AppConfig.httpTimeout);
        sw.stop();
        _logResponse(tag, resp, sw);

        if (resp.statusCode >= 200 && resp.statusCode < 500) {
          return ApiResult.success(
            'OK from $path · HTTP ${resp.statusCode} · '
            '${sw.elapsedMilliseconds}ms',
            statusCode: resp.statusCode,
          );
        }
      } on TimeoutException {
        return ApiResult.failure(
          'Timeout after ${AppConfig.httpTimeout.inSeconds}s on $path',
        );
      } on SocketException catch (e) {
        return ApiResult.failure('No connection on $path: ${e.message}');
      } catch (e) {
        return ApiResult.failure('Error on $path: $e');
      }
    }
    return ApiResult.failure('All probe endpoints returned 5xx');
  }
}
