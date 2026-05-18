import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthSource { api, local, none }

/// Wraps the existing local AuthService plus the new ApiService.
/// Order of attempts in [login] / [register]:
///   1. Laravel Sanctum API
///   2. Local SharedPreferences registry  (works offline / when API down)
class AuthProvider extends ChangeNotifier {
  String? _name;
  String? _email;
  bool _isAdmin = false;
  AuthSource _source = AuthSource.none;
  String? _lastMessage;

  String? get name => _name;
  String? get email => _email;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _email != null;
  AuthSource get source => _source;
  String? get lastMessage => _lastMessage;

  Future<void> hydrate() async {
    final logged = await AuthService.isLoggedIn();
    if (logged) {
      _name = await AuthService.getUserName();
      _email = await AuthService.getUserEmail();
      _isAdmin = await AuthService.isAdmin();
      final token = await ApiService.getToken();
      _source = token != null ? AuthSource.api : AuthSource.local;
      debugPrint(
        '🔐 AUTH - Hydrated session: $_email (admin=$_isAdmin, src=$_source)',
      );
      notifyListeners();
    }
  }

  /// Returns true if a session was created. Sets [_lastMessage] either way.
  ///
  /// Order of attempts:
  ///   1. Laravel Sanctum API. If it returns 2xx, we trust it and stop here.
  ///   2. If the API errored (timeout / network / 4xx-5xx), try local registry.
  Future<bool> login(String email, String password) async {
    _lastMessage = null;

    final apiResult = await ApiService.login(email, password);

    // Hard success path — never touch the local layer on 2xx.
    if (apiResult.ok && apiResult.data != null) {
      final u = apiResult.data!;
      final name = (u['name'] ?? email).toString();
      final mail = (u['email'] ?? email).toString();
      final admin = (u['role']?.toString().toLowerCase() == 'admin') ||
          mail.toLowerCase() == 'admin@moviebuff.com';
      await AuthService.saveLoginSession(name, mail, isAdmin: admin);
      _name = name;
      _email = mail;
      _isAdmin = admin;
      _source = AuthSource.api;
      _lastMessage = '✅ Signed in via SSP API';
      debugPrint('🔐 AUTH - API login SUCCESS ($mail)');
      notifyListeners();
      return true;
    }

    debugPrint(
      '🔐 AUTH - API login failed (${apiResult.error}) → trying local fallback',
    );
    final local = await AuthService.authenticateUser(email, password);
    if (local != null) {
      final admin = local['role'] == 'admin';
      await AuthService.saveLoginSession(
        local['name']!,
        local['email']!,
        isAdmin: admin,
      );
      _name = local['name'];
      _email = local['email'];
      _isAdmin = admin;
      _source = AuthSource.local;
      _lastMessage =
          'API unavailable (${apiResult.error}). Using local fallback for demo.';
      notifyListeners();
      return true;
    }

    _lastMessage =
        apiResult.error == null
            ? 'Invalid email or password'
            : 'Login failed: ${apiResult.error}';
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _lastMessage = null;

    final apiResult = await ApiService.register(
      name: name,
      email: email,
      password: password,
    );

    if (apiResult.ok && apiResult.data != null) {
      final mail = (apiResult.data!['email'] ?? email).toString();
      final displayName = (apiResult.data!['name'] ?? name).toString();
      final admin = mail.toLowerCase() == 'admin@moviebuff.com';
      // Mirror the new user into the local registry so the demo still works
      // offline next time. registerUser may return false if email already
      // exists locally - that's fine, the API is the source of truth.
      await AuthService.registerUser(
        displayName,
        mail,
        password,
        role: admin ? 'admin' : 'user',
      );
      await AuthService.saveLoginSession(displayName, mail, isAdmin: admin);
      _name = displayName;
      _email = mail;
      _isAdmin = admin;
      _source = AuthSource.api;
      _lastMessage = '✅ Registered via SSP API';
      debugPrint('🔐 AUTH - API register SUCCESS ($mail)');
      notifyListeners();
      return true;
    }

    debugPrint(
      '🔐 AUTH - API register failed (${apiResult.error}) → registering locally',
    );
    final isAdmin = email.toLowerCase().contains('admin@moviebuff.com');
    final ok = await AuthService.registerUser(
      name,
      email,
      password,
      role: isAdmin ? 'admin' : 'user',
    );
    if (!ok) {
      _lastMessage = 'Email already registered';
      return false;
    }
    await AuthService.saveLoginSession(name, email, isAdmin: isAdmin);
    _name = name;
    _email = email;
    _isAdmin = isAdmin;
    _source = AuthSource.local;
    _lastMessage =
        'API unavailable (${apiResult.error}). Using local fallback for demo.';
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await ApiService.logout();
    await AuthService.logout();
    _name = null;
    _email = null;
    _isAdmin = false;
    _source = AuthSource.none;
    _lastMessage = null;
    notifyListeners();
  }
}
