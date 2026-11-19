import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/push.dart';
import 'data/backend.dart';
import 'data/demo_backend.dart';
import 'data/firebase_backend.dart';

/// Force demo mode even when Firebase is configured:
///   flutter run --dart-define=WASILHA_DEMO=true
const _forceDemo = bool.fromEnvironment('WASILHA_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final backend = await _initBackend();
  final prefs = await SharedPreferences.getInstance();

  // Register for push once signed in (no-op in demo mode).
  backend.profile().listen((p) => p == null ? PushService.stop() : PushService.start(backend));

  runApp(
    MultiProvider(
      providers: [
        Provider<WasilhaBackend>.value(value: backend),
        ChangeNotifierProvider(create: (_) => AppState(backend, prefs)),
      ],
      child: const WasilhaApp(),
    ),
  );
}

/// Uses Firebase when the native config files are present
/// (android/app/google-services.json, ios/Runner/GoogleService-Info.plist);
/// otherwise falls back to the in-memory demo backend.
Future<WasilhaBackend> _initBackend() async {
  if (_forceDemo) return DemoBackend();
  try {
    // Time-boxed so a missing config or a stalled network can't block startup.
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
    return FirebaseBackend();
  } catch (e) {
    debugPrint('Firebase not configured ($e) — running in demo mode.');
    return DemoBackend();
  }
}
