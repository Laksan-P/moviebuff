import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme controller. Default `ThemeMode.system` satisfies the
/// "follow device setting" requirement, but the user can override
/// (toggle stored in SharedPreferences).
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark =>
      _mode == ThemeMode.dark ||
      (_mode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == 'light') {
      _mode = ThemeMode.light;
    } else if (raw == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }
    debugPrint('🎨 THEME - Loaded mode: $_mode');
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToString(m));
    debugPrint('🎨 THEME - Saved mode: $m');
  }

  String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
