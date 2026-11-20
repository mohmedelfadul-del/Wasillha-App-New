import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_ops/app/app.dart';
import 'package:wasilha_ops/app/services.dart';
import 'package:wasilha_ops/app/settings.dart';
import 'package:wasilha_ops/features/auth/application/session_controller.dart';
import 'package:wasilha_ops/features/auth/domain/auth_repository.dart';

import 'fakes.dart';

Future<SettingsController> testSettings({String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues({'ops.lang': lang});
  return SettingsController(await SharedPreferences.getInstance());
}

/// Full app (gate, shell, routes) on fakes.
Future<void> pumpApp(WidgetTester tester, OpsServices services, {String route = '/', String lang = 'en', Size size = const Size(1280, 900), double textScale = 1.0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final settings = await testSettings(lang: lang);
  await tester.pumpWidget(OpsApp(settings: settings, services: services, initialRoute: route));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// A single widget with the scopes screens expect.
Future<void> pumpWidgetIn(WidgetTester tester, Widget child, {StaffSession? session, OpsServices? services, String lang = 'en'}) async {
  final settings = await testSettings(lang: lang);
  final sess = session ?? staff(StaffRole.kyc);
  final strings = S(lang);
  await tester.pumpWidget(MaterialApp(
    theme: wasilhaTheme(Brightness.light),
    locale: Locale(lang),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => OpsServicesScope(
      services: services ?? fakeServices(session: sess),
      child: SettingsScope(
        controller: settings,
        child: WStrings(
          strings: strings,
          child: SessionScope(session: sess, onSignOut: () async {}, child: child!),
        ),
      ),
    ),
    home: Scaffold(body: child),
  ));
  await tester.pump();
}
