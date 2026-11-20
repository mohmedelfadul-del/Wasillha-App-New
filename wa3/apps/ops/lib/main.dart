import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'app/config_error.dart';
import 'app/firebase_services.dart';
import 'app/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final missing = OpsConfig.missing();
  if (missing.isNotEmpty) {
    runApp(ConfigErrorApp(missing: missing));
    return;
  }
  try {
    await Firebase.initializeApp(options: OpsConfig.options);
    if (OpsConfig.useEmulator) {
      const host = OpsConfig.emulatorHost;
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    }
    if (OpsConfig.useEmulator || kDebugMode) {
      await FirebaseAppCheck.instance.activate(providerWeb: WebDebugProvider());
    } else {
      await FirebaseAppCheck.instance.activate(providerWeb: ReCaptchaV3Provider(OpsConfig.appCheckSiteKey));
    }
  } catch (e) {
    runApp(ConfigErrorApp(error: e));
    return;
  }
  final settings = SettingsController(await SharedPreferences.getInstance());
  runApp(OpsApp(settings: settings, services: firebaseServices()));
}
