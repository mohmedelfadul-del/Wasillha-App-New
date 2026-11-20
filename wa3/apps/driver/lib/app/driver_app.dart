import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wa3_core/wa3_core.dart';

import 'root_gate.dart';
import 'services.dart';

/// MaterialApp with Wasilha theme, Arabic-first locale and shared strings.
class DriverApp extends StatelessWidget {
  const DriverApp({super.key, required this.services, this.home});
  final AppServices services;

  /// Defaults to the auth/registration gate.
  final Widget? home;

  @override
  Widget build(BuildContext context) => Services(
        services: services,
        child: ListenableBuilder(
          listenable: services.settings,
          builder: (context, _) {
            final lang = services.settings.lang;
            final strings = S(lang);
            return MaterialApp(
              title: strings.t('وصلها — السائق', 'Wasilha Driver'),
              debugShowCheckedModeBanner: false,
              theme: wasilhaTheme(Brightness.light),
              darkTheme: wasilhaTheme(Brightness.dark),
              themeMode: services.settings.theme,
              locale: Locale(lang),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
              builder: (context, child) => WStrings(strings: strings, child: Directionality(textDirection: strings.dir, child: child!)),
              home: home ?? const RootGate(),
            );
          },
        ),
      );
}
