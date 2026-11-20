import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language (ar default) and theme, saved in shared_preferences.
/// With no [prefs] (tests) the settings live in memory only.
class SettingsController extends ChangeNotifier {
  SettingsController([this._prefs]) {
    final p = _prefs;
    if (p != null) {
      _lang = p.getString(_langKey) == 'en' ? 'en' : 'ar';
      _theme = ThemeMode.values.firstWhere((m) => m.name == p.getString(_themeKey), orElse: () => ThemeMode.system);
    }
  }

  static const _langKey = 'lang', _themeKey = 'theme';
  final SharedPreferences? _prefs;
  String _lang = 'ar';
  ThemeMode _theme = ThemeMode.system;

  String get lang => _lang;
  ThemeMode get theme => _theme;

  Future<void> setLang(String lang) async {
    if (lang == _lang) return;
    _lang = lang == 'en' ? 'en' : 'ar';
    notifyListeners();
    await _prefs?.setString(_langKey, _lang);
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (mode == _theme) return;
    _theme = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }
}
