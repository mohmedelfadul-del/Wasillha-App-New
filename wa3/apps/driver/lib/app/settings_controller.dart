import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language (ar default, en) and theme (system/light/dark), persisted.
class SettingsController extends ChangeNotifier {
  SettingsController({this.lang = 'ar', this.theme = ThemeMode.system, this.prefs});
  String lang;
  ThemeMode theme;
  final SharedPreferences? prefs;

  static Future<SettingsController> load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('theme');
    return SettingsController(
      lang: p.getString('lang') == 'en' ? 'en' : 'ar',
      theme: ThemeMode.values.firstWhere((m) => m.name == t, orElse: () => ThemeMode.system),
      prefs: p,
    );
  }

  Future<void> setLang(String l) async {
    lang = l;
    notifyListeners();
    await prefs?.setString('lang', l);
  }

  Future<void> setTheme(ThemeMode m) async {
    theme = m;
    notifyListeners();
    await prefs?.setString('theme', m.name);
  }
}
