import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wa3_core/wa3_core.dart';

import 'app/app.dart';
import 'app/boot_error.dart';
import 'app/deps.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/common/presentation/google_map_surface.dart';
import 'features/location/data/geolocator_location_service.dart';
import 'features/places/data/api_places_repository.dart';
import 'features/profile/data/firestore_profile_repository.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/trips/data/firestore_trip_repository.dart';

const _region = 'europe-west1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    prefs = null; // Settings then last for this session only.
  }
  final settings = SettingsController(prefs);

  try {
    await Firebase.initializeApp();
  } catch (e) {
    runApp(RiderShell(settings: settings, home: BootErrorScreen(error: e)));
    return;
  }

  final functions = FirebaseFunctions.instanceFor(region: _region);
  if (const bool.fromEnvironment('USE_EMULATOR')) {
    const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    functions.useFunctionsEmulator(host, 5001);
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
    );
  } catch (e) {
    // Commands then fail with a clear server error if App Check is enforced.
    debugPrint('App Check activation failed: $e');
  }

  final api = WasilhaApi(functions: functions);
  const shareOverride = String.fromEnvironment('SHARE_BASE_URL');
  final shareBase = shareOverride.isNotEmpty ? shareOverride : 'https://$_region-${Firebase.app().options.projectId}.cloudfunctions.net/sharedTrip';

  runApp(RiderDeps(
    auth: FirebaseAuthRepository(FirebaseAuth.instance),
    profile: FirestoreProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance, api),
    trips: FirestoreTripRepository(FirebaseFirestore.instance, FirebaseAuth.instance, api, shareBaseUrl: shareBase),
    places: ApiPlacesRepository(api),
    location: GeolocatorLocationService(),
    map: googleMapBuilder,
    settings: settings,
    child: RiderApp(settings: settings),
  ));
}
