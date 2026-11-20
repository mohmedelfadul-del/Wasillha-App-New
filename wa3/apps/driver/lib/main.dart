import 'package:flutter/material.dart';

import 'app/driver_app.dart';
import 'app/firebase_services.dart';
import 'app/settings_controller.dart';
import 'app/startup_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initFirebase();
  } catch (e) {
    runApp(StartupErrorApp(detail: e.toString()));
    return;
  }
  final settings = await SettingsController.load();
  runApp(DriverApp(services: firebaseServices(settings)));
}
