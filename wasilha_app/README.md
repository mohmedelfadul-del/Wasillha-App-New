# Wasilha · وصلها — Flutter app

A Flutter port of the Wasilha prototype (`../project/`, `../Wasilha.html`): rides (raksha, motor, car),
fare bidding, live tracking, delivery, food, wallet, safety, plus driver and store modes. Android and iOS.

## Run it now (demo mode)

The app works without any setup. If no Firebase config is found it starts in **demo mode**:
an in-memory backend with simulated drivers who bid on your requests and then complete the trip,
and simulated riders who send you requests when you go online as a driver. Any 6-digit OTP works.

```bash
flutter pub get
flutter run                       # demo mode, illustrated map
```

## Connect Firebase (real accounts and data)

1. Create a project at <https://console.firebase.google.com>.
2. **Authentication → Sign-in method → Phone**: enable it. For testing, add test numbers
   (e.g. `+249 912345678` / code `123456`) so you don't need real SMS.
3. **Firestore Database**: create it (production mode).
4. Add the apps:
   - Android, package name `sd.wasilha.app` → download `google-services.json` → put it in `android/app/`.
     Add your debug keystore's SHA-1 and SHA-256 (`cd android && ./gradlew signingReport`). Phone Auth on Android needs them.
   - iOS, bundle id `sd.wasilha.app` → download `GoogleService-Info.plist` → drag it into `ios/Runner` in Xcode
     (tick “Copy items” and the Runner target). For Phone Auth on iOS also upload an APNs key in the Firebase
     console, then add the `REVERSED_CLIENT_ID` URL scheme to Info.plist.
5. Deploy the rules and indexes:
   ```bash
   npm i -g firebase-tools && firebase login
   firebase use --add            # pick your project
   firebase deploy --only firestore
   ```
6. `flutter run`. The app finds the config files and uses Firebase. To force demo mode anyway, run
   `flutter run --dart-define=WASILHA_DEMO=true`.

Both config files are listed in `.gitignore`.

## Google Maps

By default the app draws the illustrated map from the design. To use real Google Maps:

1. In Google Cloud, enable **Maps SDK for Android** and **Maps SDK for iOS** and create an API key.
2. Android: add `MAPS_API_KEY=your_key` to `android/local.properties`.
3. iOS: create `ios/Flutter/Secrets.xcconfig` containing `MAPS_API_KEY=your_key`.
4. Run with `flutter run --dart-define=USE_GOOGLE_MAPS=true`.

Routes are drawn as straight lines between pickup and drop-off. For road-following routes, add the Directions API.
Destination search uses a built-in list of Khartoum places (`lib/data/catalog.dart`). For full address search,
replace it with the Places API.

## Build for release

```bash
flutter build appbundle           # Android → build/app/outputs/bundle/release/
flutter build ipa                 # iOS (on a Mac with Xcode)
```

Before you publish, set up a release signing key for Android (`android/app/build.gradle.kts` currently signs
release builds with the debug key) and a team and provisioning profile in Xcode.

## Project layout

```
lib/
  main.dart                 picks the Firebase or demo backend
  app.dart                  MaterialApp + route table (route names = prototype screen ids)
  core/app_state.dart       language, accent, appearance, booking draft (persisted)
  core/nav.dart             context.go / swap / root / tab helpers
  data/models.dart          Trip, Bid, Place, WalletTxn, UserProfile, StoreOrder…
  data/backend.dart         WasilhaBackend interface
  data/firebase_backend.dart  Firebase Auth (phone OTP) + Firestore
  data/demo_backend.dart    in-memory simulation
  data/catalog.dart         Khartoum places + restaurants
  theme/tokens.dart         colors, type (Geist, Instrument Serif, IBM Plex Sans Arabic, Amiri)
  widgets/                  icons, glass, buttons, map, service cards
  screens/                  onboarding · rider · account · driver · store
firestore.rules, firestore.indexes.json, firebase.json
```

### Firestore data model

| Path | Contents |
|---|---|
| `users/{uid}` | name, phone, role (`rider`/`driver`/`store`), balance, rating, trips, online, vehicle, plate, storeName |
| `users/{uid}/transactions` | wallet activity |
| `users/{uid}/notifications` | in-app notifications |
| `users/{uid}/places` | saved places |
| `trips/{id}` | rider, service, pickup/dropoff, offeredFare/finalFare, status, driver details and live position |
| `trips/{id}/bids/{driverId}` | driver counter-offers |
| `orders/{id}` | food and store orders |

Trip flow: the rider creates a trip (`requested`) → drivers bid → the rider accepts one (`accepted`) → the driver
moves it to `arriving`, then `inProgress`, then `completed` → the rider rates it and the wallet is charged.

## Production checklist (not done yet)

- **Payments**: top-ups are recorded, but no money moves. Integrate a provider (Bankak / mBOK / card acquirer) and
  credit the wallet from a **Cloud Function** after the provider confirms. Then make `balance` read-only for clients
  in `firestore.rules`.
- **Trip charging and driver payouts** should also move to Cloud Functions.
- **Push notifications** (FCM) for new requests, accepted bids and arrivals. Today notifications only show while the app is open.
- **Driver location**: `FirebaseBackend.updateDriverLocation` exists. Feed it from a `geolocator` position stream
  while a trip is active, and request location permission at runtime.
- In-app chat with the driver. The chat button currently shows "coming soon".
- App icons and splash for the stores (e.g. `flutter_launcher_icons`).

---

## بالعربية

**التشغيل بدون أي إعداد:** شغّل `flutter pub get` ثم `flutter run`. التطبيق يعمل في «الوضع التجريبي»: سائقون
افتراضيون يقدّمون عروض أسعار لطلبك ويكملون الرحلة، وأي رمز تحقق من 6 أرقام يعمل.

**ربط Firebase:** أنشئ مشروعاً في Firebase، وفعّل تسجيل الدخول بالهاتف وقاعدة Firestore. ضع ملف
`google-services.json` في `android/app/`، وأضف `GoogleService-Info.plist` إلى `ios/Runner` عبر Xcode.
ثم انشر القواعد بالأمر `firebase deploy --only firestore`.

**خرائط Google:** ضع المفتاح `MAPS_API_KEY` في `android/local.properties` وفي `ios/Flutter/Secrets.xcconfig`،
ثم شغّل `flutter run --dart-define=USE_GOOGLE_MAPS=true`.

**قبل الإطلاق:** يجب ربط بوابة دفع حقيقية ونقل عمليات المحفظة إلى Cloud Functions، وإضافة الإشعارات (FCM)
وتتبع موقع السائق الحي.
