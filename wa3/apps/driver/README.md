# Wasilha Driver

Driver app (Android, iOS) for Wasilha v1. Follows `wa3/docs/app-engineering-brief.md`; all contracts come from `packages/wa3_core`.

## Configuration

| What | Where |
|---|---|
| Firebase | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`. Without them the app shows a full-screen configuration error. |
| Google Maps SDK key | Android: `MAPS_API_KEY=…` in `android/local.properties`. iOS: copy `ios/Flutter/Secrets.xcconfig.example` to `Secrets.xcconfig`. |
| Support phone (assumption) | `--dart-define=OPS_PHONE=+249…` (default is a placeholder, see `lib/app/config.dart`). |
| Emulators | `--dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2` |

## Checks

```sh
flutter analyze
flutter test
```
