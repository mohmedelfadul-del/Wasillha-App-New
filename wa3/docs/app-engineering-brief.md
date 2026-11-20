# Wasilha v1 — app engineering brief (rider · driver · operations)

Three **separate** Flutter products share one backend and one package. Do not merge them or add role switching.

| App | Path | Platform | Users |
|---|---|---|---|
| Rider | `wa3/apps/rider` | Android, iOS | Riders |
| Driver | `wa3/apps/driver` | Android, iOS | Drivers |
| Operations console | `wa3/apps/ops` | Flutter Web | Staff |

Everything else is shared:
- **Backend:** `wa3/backend`. Firebase: Auth, Firestore, Cloud Functions in `europe-west1`.
- **Shared package:** `wa3/packages/wa3_core`.

## Non-negotiable engineering rules

1. **The server is the source of truth.** Clients never write Firestore, except the driver's own `presence/{uid}`.
   - Every change is a command in `wa3_core`'s `WasilhaApi`.
   - Render only what the server confirms. Never infer completion, payment or approval from local state.
2. **Idempotency and revision.** Create an `IntentKey.generate()` when the user taps, and pass it to the command.
   - `WasilhaApi` already retries network failures with the same key.
   - Trip transitions send `expectedRevision` from the latest trip snapshot you rendered.
   - On a `stale_revision` failure, show the message: the snapshot listener will already have refreshed the screen.
3. **Realtime.** Listen to the authoritative document with `snapshots()`. It *is* the authoritative read, so render from it.
   - Show `snapshot.metadata.isFromCache` as "may be out of date" when it stays true for more than a few seconds.
4. **Location.**
   - Driver app: writes `presence/{uid}` roughly every 5 s while moving and every 15 s as a heartbeat when stationary. Fields: `lat`, `lng`, `geohash` (from `geohashEncode`), optional `heading`, `speed`, `accuracy`, and `updatedAt: FieldValue.serverTimestamp()`. The rules reject any other field.
   - Rider UI: if the driver's `updatedAt` is older than 30 s (`DriverPosition.isStale`), say clearly that the location is stale. Never pretend it is live.
5. **No secrets in clients.** Maps routing and places go through the `placesSearch`, `placeLabel` and `createDraft` commands. The Google Maps SDK key for the map tiles lives in native config only.
   - Android: `MAPS_API_KEY` in `local.properties` becomes a manifest placeholder.
   - iOS: `ios/Flutter/Secrets.xcconfig`.
   - App Check: activate `firebase_app_check` with Play Integrity and App Attest, or the debug provider in debug builds.
6. **Honest failures.** Use `WStateView` for loading, empty, error with retry, offline and permission denied. Explain errors with `context.s.error(code)`.
   - Never simulate success.
   - Never show "coming soon" or locked buttons. Out-of-scope features do not exist in the UI.
7. **Structure.** Feature-first folders: `lib/features/<feature>/{domain,data,application,presentation}`.
   - App shell: `lib/app/`.
   - Keep every file under about 400 lines, and split big screens into stage-specific widgets.
   - State management: `ChangeNotifier` plus `ListenableBuilder` or `StreamBuilder`. No extra packages.
8. **Out of scope. Do not build any of these:**
   - wallet or digital payments
   - scheduled trips
   - intercity travel
   - parcels
   - food or retail
   - in-app chat (a call button is enough)
   - saved places
   - promotions or coupons
   - marketing notifications

## UX rules

- **RTL first.** Arabic is the default and English is the secondary language.
  - Use `EdgeInsetsDirectional`, `AlignmentDirectional` and start/end.
  - Wrap numbers, plates and phone numbers with `ltr()`, or use the `money()`, `km()` and `minutes()` helpers.
- **One primary action per screen** (`PrimaryAction`, which blocks double taps). Clear hierarchy. No decorative cards, gradients or dead buttons.
- **Accessibility (WCAG 2.2 AA):**
  - Touch targets of at least 48 dp. Driver primary actions use `PrimaryAction(large: true)`.
  - Semantics labels on icon buttons and map markers.
  - Layout works at 320 px wide with 200 % text: use `SingleChildScrollView` and `Flexible`, and never fix text heights.
  - Respect reduced motion with `motion(context, d)`.
  - Green means success, red error, amber warning. Always pair the color with text or an icon (`StatusBadge`, `WBanner`).
- **Theme and language:** `wasilhaTheme(Brightness.light / dark)`.
  - Settings: language (ar/en) and theme (system/light/dark), saved in `shared_preferences`.
  - Wrap the app in `WStrings(strings: S(lang))` and a `Directionality`, and set `MaterialApp.locale` with the flutter_localizations delegates.
- **Map semantics:** route and pin colors come from `MapColors`, independent of the brand color.
- **Confirmation:** destructive or financial actions use `confirmWithReason` or `confirmAction`.

## Bootstrap (every app)

```dart
await Firebase.initializeApp();                 // native config (google-services.json / GoogleService-Info.plist); web: options from --dart-define
if (const bool.fromEnvironment('USE_EMULATOR')) {
  final host = const String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost'); // 10.0.2.2 on the Android emulator
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instanceFor(region: 'europe-west1').useFunctionsEmulator(host, 5001);
  // driver: FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
```

If Firebase fails to initialize, show a clear full-screen error that names the missing configuration. Do not run a fake mode.

## Backend contract (see `wa3_core/lib/src/data/api.dart` and `models.dart`)

**Readable collections (Firestore rules enforce these):**
- Rider:
  - `trips/{id}` where `riderId == uid`, and `trips/{id}/offers/*` on their own trip.
  - `presence/{driverId}` of the assigned driver.
  - `riders/{uid}`.
- Driver:
  - `drivers/{uid}` and `drivers/{uid}/documents/*`.
  - `vehicles/*` where `driverId == uid`, and their `documents`.
  - `inbox/{uid}/requests/*`: sanitized nearby requests, written by the server.
  - `trips/{id}` where `driverId == uid`.
  - `ledger` where `driverId == uid`.
  - `presence/{uid}`.
  - `zones/*`.
- Staff, with custom claims `staff: true` and `role`:
  - Everything except `audit`, which is admin only.
  - `ledger`: finance and operations only.

**Trip states:** `draft → searching → offering → driverAssigned → driverEnRoute → driverArrived → inProgress → arrived → paymentPending → completed`.
- Any state before pickup can go to `cancelled`.
- `completed` can go to `disputed` within 48 h.

**Commands:**

| Area | Commands |
|---|---|
| Rider | `registerRider`, `createDraft` (returns tripId, revision, quote, route), `confirmRequest`, `acceptOffer`, `cancelTrip`, `rateTrip`, `disputeTrip`, `reportSafety`, `shareTrip` (token; link = `https://<region>-<project>.cloudfunctions.net/sharedTrip?t=<token>`, configurable), `placesSearch`, `placeLabel` |
| Driver | `registerDriver`, `submitDocument` (after a Storage upload to `drivers/{uid}/…`), `addVehicle`, `setActiveVehicle`, `goOnline`, `goOffline`, `submitOffer`, then `stage('ackAssignment'|'markArrived'|'startTrip'|'finishTrip')`, `recordCash`, `myEarnings`, plus shared `cancelTrip` and `rateTrip` |
| Operations | `claimReview` and `decideReview` (review item `path` = `drivers/{uid}/documents/{type}` or `vehicles/{vid}/documents/{type}`), `opsCancelTrip`, `resolveDispute`, `claimCase`, `closeCase`, `updatePricing`, `recordSettlement`, `recordAdjustment`, `driverMoney` |

**Verification commands:**
- `cd <app> && flutter analyze` must report no issues.
- `flutter test` must pass.
- Flutter: `export PATH=/opt/flutter-sdk/flutter/bin:$PATH` (the warning about running as root is harmless).
- Don't edit `wa3_core` or the backend. If you need something there, say so in your report.
