# Wasilha rider app

Android/iOS Flutter app for riders. Rules: `../../docs/app-engineering-brief.md`.

## Native configuration (not committed)

- Firebase: `android/app/google-services.json` (the Google Services Gradle plugin is applied only when it exists) and `ios/Runner/GoogleService-Info.plist`. Without them the app shows a full-screen configuration error.
- Google Maps SDK key (map tiles only):
  - Android: `MAPS_API_KEY=...` in `android/local.properties`.
  - iOS: copy `ios/Flutter/Secrets.xcconfig.example` to `ios/Flutter/Secrets.xcconfig` and set `MAPS_API_KEY`.
- iOS phone sign-in also needs the `REVERSED_CLIENT_ID` URL scheme from `GoogleService-Info.plist` and APNs set up in Firebase.

## Run

```sh
flutter run                                              # production Firebase project
flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2
flutter run --dart-define=SHARE_BASE_URL=https://example/sharedTrip   # override the share link base
```

## Check

```sh
flutter analyze && flutter test
```

Screens read data through the interfaces in `lib/features/*/domain`; tests use fakes (`test/support/fakes.dart`) and a placeholder map.
