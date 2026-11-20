import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/auth/application/session_controller.dart';
import '../features/auth/presentation/auth_gate.dart';
import 'config.dart';
import 'routes.dart';
import 'services.dart';
import 'settings.dart';

class OpsApp extends StatefulWidget {
  const OpsApp({super.key, required this.settings, required this.services, this.mfaOptional = OpsConfig.staffMfaOptional, this.initialRoute});
  final SettingsController settings;
  final OpsServices services;
  final bool mfaOptional;
  final String? initialRoute;

  @override
  State<OpsApp> createState() => _OpsAppState();
}

class _OpsAppState extends State<OpsApp> {
  late final SessionController _session = SessionController(widget.services.auth);

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        final strings = S(widget.settings.lang);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: strings.t('وصلها · التشغيل', 'Wasilha · Operations'),
          theme: wasilhaTheme(Brightness.light),
          darkTheme: wasilhaTheme(Brightness.dark),
          themeMode: widget.settings.themeMode,
          locale: Locale(widget.settings.lang),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: widget.initialRoute,
          onGenerateRoute: generateRoute,
          // One route per deep link (no '/', '/kyc', … intermediates).
          onGenerateInitialRoutes: (name) => [generateRoute(RouteSettings(name: name))],
          builder: (context, child) => OpsServicesScope(
            services: widget.services,
            child: SettingsScope(
              controller: widget.settings,
              child: WStrings(
                strings: strings,
                child: Directionality(
                  textDirection: strings.dir,
                  child: AuthGate(controller: _session, mfaOptional: widget.mfaOptional, child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
