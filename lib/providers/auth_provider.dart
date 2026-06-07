import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthSource { api, none }

/// Authentication via Laravel Sanctum only.
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

  bool _userIsAdmin(Map<String, dynamic> user) {
    final role = user['role']?.toString().toLowerCase();
    return role == 'admin';
  }

  Future<void> hydrate() async {
    final logged = await AuthService.isLoggedIn();
    final token = await ApiService.getToken();
    if (!logged || token == null) {
      if (logged && token == null) {
        await AuthService.logout();
      }
      return;
    }

    _name = await AuthService.getUserName();
    _email = await AuthService.getUserEmail();
    _isAdmin = await AuthService.isAdmin();
    _source = AuthSource.api;

    final userResult = await ApiService.getCurrentUser();
    if (userResult.ok && userResult.data != null) {
      final u = userResult.data!;
      _name = (u['name'] ?? _name)?.toString();
      _email = (u['email'] ?? _email)?.toString();
      _isAdmin = _userIsAdmin(u);
      await AuthService.saveLoginSession(
        _name ?? 'User',
        _email ?? '',
        isAdmin: _isAdmin,
      );
    } else if (userResult.statusCode == 401) {
      await logout();
      return;
    }

    debugPrint(
      '🔐 AUTH - Hydrated session: $_email (admin=$_isAdmin)',
    );
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _lastMessage = null;

    final apiResult = await ApiService.login(email, password);
    if (!apiResult.ok || apiResult.data == null) {
      _lastMessage = apiResult.error ?? 'Invalid email or password.';
      debugPrint('🔐 AUTH - API login failed: ${apiResult.error}');
      return false;
    }

    final u = apiResult.data!;
    final name = (u['name'] ?? email).toString();
    final mail = (u['email'] ?? email).toString();
    final role = u['role']?.toString();
    final admin = _userIsAdmin(u);

    debugPrint('🔐 AUTH - login response user=$u');
    debugPrint(
      '🔐 AUTH - role field="$role" isAdmin=$admin '
      '(routes to ${admin ? 'AdminDashboard' : 'HomeScreen'})',
    );

    await AuthService.saveLoginSession(name, mail, isAdmin: admin);
    _name = name;
    _email = mail;
    _isAdmin = admin;
    _source = AuthSource.api;
    _lastMessage = 'Signed in successfully.';
    debugPrint('🔐 AUTH - API login SUCCESS ($mail)');
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _lastMessage = null;

    final apiResult = await ApiService.register(
      name: name,
      email: email,
      password: password,
    );

    if (!apiResult.ok || apiResult.data == null) {
      _lastMessage = apiResult.error ?? 'Registration failed.';
      debugPrint('🔐 AUTH - API register failed: ${apiResult.error}');
      return false;
    }

    final u = apiResult.data!;
    final mail = (u['email'] ?? email).toString();
    final displayName = (u['name'] ?? name).toString();
    final admin = _userIsAdmin(u);

    await AuthService.saveLoginSession(displayName, mail, isAdmin: admin);
    _name = displayName;
    _email = mail;
    _isAdmin = admin;
    _source = AuthSource.api;
    _lastMessage = 'Account created successfully.';
    debugPrint('🔐 AUTH - API register SUCCESS ($mail)');
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
