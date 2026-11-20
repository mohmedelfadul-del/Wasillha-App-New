import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/account/data/firebase_driver_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/documents/data/firebase_document_repository.dart';
import '../features/documents/data/image_picker_adapter.dart';
import '../features/earnings/data/firebase_earnings_repository.dart';
import '../features/history/data/firebase_history_repository.dart';
import '../features/location/application/location_service.dart';
import '../features/location/data/firestore_presence_sink.dart';
import '../features/location/data/geolocator_source.dart';
import '../features/requests/data/firebase_request_repository.dart';
import '../features/trip/data/firebase_trip_repository.dart';
import '../features/vehicles/data/firebase_vehicle_repository.dart';
import 'launcher.dart';
import 'services.dart';
import 'settings_controller.dart';

/// Brief bootstrap: Firebase, optional emulators, App Check.
Future<void> initFirebase() async {
  await Firebase.initializeApp();
  if (const bool.fromEnvironment('USE_EMULATOR')) {
    const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost'); // 10.0.2.2 on the Android emulator
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
  );
}

AppServices firebaseServices(SettingsController settings) {
  final db = FirebaseFirestore.instance;
  final api = WasilhaApi();
  return AppServices(
    auth: FirebaseAuthRepository(FirebaseAuth.instance),
    driver: FirebaseDriverRepository(db, api),
    documents: FirebaseDocumentRepository(db, FirebaseStorage.instance, api),
    picker: ImagePickerAdapter(),
    vehicles: FirebaseVehicleRepository(db, api),
    requests: FirebaseRequestRepository(db, api),
    trips: FirebaseTripRepository(db, api),
    earnings: FirebaseEarningsRepository(db, api),
    history: FirebaseHistoryRepository(db),
    location: LocationService(source: GeolocatorSource(), sink: FirestorePresenceSink(db)),
    launcher: UrlLauncher(),
    settings: settings,
  );
}
