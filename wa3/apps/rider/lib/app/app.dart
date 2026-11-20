import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/settings/application/settings_controller.dart';
import 'auth_gate.dart';

const supportedLocales = [Locale('ar'), Locale('en')];

/// Theme, language and direction around any [home] (the app or a test).
class RiderShell extends StatelessWidget {
  const RiderShell({super.key, required this.settings, required this.home});
  final SettingsController settings;
  final Widget home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final s = S(settings.lang);
          return WStrings(
            strings: s,
            child: MaterialApp(
              title: s.t('وصلها', 'Wasilha'),
              debugShowCheckedModeBanner: false,
              locale: Locale(settings.lang),
              supportedLocales: supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: wasilhaTheme(Brightness.light),
              darkTheme: wasilhaTheme(Brightness.dark),
              themeMode: settings.theme,
              builder: (context, child) => Directionality(textDirection: s.dir, child: child!),
              home: home,
            ),
          );
        },
      );
}

class RiderApp extends StatelessWidget {
  const RiderApp({super.key, required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) => RiderShell(settings: settings, home: const AuthGate());
}
