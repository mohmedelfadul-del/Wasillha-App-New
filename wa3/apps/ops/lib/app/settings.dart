import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language (ar default, en) and theme (system/light/dark), saved locally.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
      : _lang = _prefs.getString(_kLang) == 'en' ? 'en' : 'ar',
        _theme = ThemeMode.values.firstWhere((m) => m.name == _prefs.getString(_kTheme), orElse: () => ThemeMode.system);

  static const _kLang = 'ops.lang';
  static const _kTheme = 'ops.theme';
  final SharedPreferences _prefs;
  String _lang;
  ThemeMode _theme;

  String get lang => _lang;
  ThemeMode get themeMode => _theme;

  void setLang(String lang) {
    if (lang == _lang) return;
    _lang = lang;
    _prefs.setString(_kLang, lang);
    notifyListeners();
  }

  void toggleLang() => setLang(_lang == 'ar' ? 'en' : 'ar');

  void setTheme(ThemeMode m) {
    if (m == _theme) return;
    _theme = m;
    _prefs.setString(_kTheme, m.name);
    notifyListeners();
  }
}

/// Gives every screen (including sign-in) the language and theme controls.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({super.key, required SettingsController controller, required super.child}) : super(notifier: controller);
  static SettingsController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
