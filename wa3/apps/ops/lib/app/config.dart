import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Build-time configuration, read from `--dart-define`. Nothing here is a
/// secret: Firebase web config is public by design; access is enforced by
/// Auth custom claims, Firestore rules and App Check.
class OpsConfig {
  const OpsConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  /// reCAPTCHA v3 site key for App Check (the server enforces App Check).
  static const appCheckSiteKey = String.fromEnvironment('APP_CHECK_SITE_KEY');

  static const useEmulator = bool.fromEnvironment('USE_EMULATOR');
  static const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

  /// Mirrors the server's REQUIRE_STAFF_MFA=false. Only honored together with
  /// USE_EMULATOR, because the Auth emulator cannot issue TOTP sessions.
  static const staffMfaOptional = bool.fromEnvironment('STAFF_MFA_OPTIONAL') && useEmulator;

  /// Names of the required defines that are missing (empty = complete).
  static List<String> missing() => [
        if (apiKey.isEmpty) 'FIREBASE_API_KEY',
        if (appId.isEmpty) 'FIREBASE_APP_ID',
        if (projectId.isEmpty) 'FIREBASE_PROJECT_ID',
        if (authDomain.isEmpty) 'FIREBASE_AUTH_DOMAIN',
        if (storageBucket.isEmpty) 'FIREBASE_STORAGE_BUCKET',
        if (messagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
        // Production calls are rejected without an App Check token.
        if (appCheckSiteKey.isEmpty && !useEmulator && kReleaseMode) 'APP_CHECK_SITE_KEY',
      ];

  static FirebaseOptions get options => const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
      );
}
