# Wasilha · وصلها — Flutter app

A Flutter port of the Wasilha prototype (`../project/`, `../Wasilha.html`): rides (raksha, motor, car),
fare bidding, live tracking, delivery, food, wallet, safety, plus driver and store modes. Android and iOS.

## Download the APK (no build needed)

Every push to `main` runs **GitHub Actions** (`.github/workflows/wasilha.yml`), which analyzes, tests and builds an Android APK.
To download it: open the repository on GitHub → **Actions** → the latest **Wasilha app** run → **Artifacts** → `wasilha-apk`.
Unzip it, copy `app-release.apk` to your phone and open it. You need to allow "install unknown apps".
This APK runs in demo mode, because the Firebase config isn't in the repository.

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
5. Deploy the rules, indexes and Cloud Functions (the functions need the Blaze plan):
   ```bash
   npm i -g firebase-tools && firebase login
   firebase use --add            # pick your project
   cp functions/.env.example functions/.env   # set ALLOW_FAKE_TOPUPS=false for production
   (cd functions && npm install)
   firebase deploy --only firestore,functions
   ```
   The Cloud Functions do everything that moves money or reaches other users:
   - push notifications
   - charging the rider and paying the driver (minus `COMMISSION_RATE`)
   - charging and refunding food orders
   - crediting top-ups

   In Firebase mode the app only records the intent, and the security rules stop it changing balances itself.
6. `flutter run`. The app finds the config files and uses Firebase. To force demo mode anyway, run
   `flutter run --dart-define=WASILHA_DEMO=true`.

Both config files are listed in `.gitignore`.

## Google Maps

By default the app draws the illustrated map from the design. To use real Google Maps:

1. In Google Cloud, enable **Maps SDK for Android** and **Maps SDK for iOS** and create an API key.
2. Android: add `MAPS_API_KEY=your_key` to `android/local.properties`.
3. iOS: create `ios/Flutter/Secrets.xcconfig` containing `MAPS_API_KEY=your_key`.
4. Run with `flutter run --dart-define=USE_GOOGLE_MAPS=true`.

### Address search and road routes

Enable **Places API (New)** and **Routes API** on the same Google Cloud project, then run with
`--dart-define=GOOGLE_API_KEY=your_key`:

- **Destination search** adds Google results, biased to Khartoum, to the built-in places list.
- **The route** on the Google map follows the roads.

Without the key, search uses `lib/data/catalog.dart` and the route is a straight line.
Restrict the key to these two APIs and to your app's package name and bundle id.

## Push notifications

Push works automatically in Firebase mode: the app saves the device's FCM token and the Cloud Functions send the messages.

- **Android:** no extra setup.
- **iOS:**
  1. Upload an APNs key in the Firebase console → Project settings → Cloud Messaging.
  2. The entitlements file (`ios/Runner/Runner.entitlements`) and the background mode are already set up.
     In Xcode, just pick your team under Signing & Capabilities.

## Test the backend locally (Firebase emulator)

```bash
(cd functions && npm install && npm run build)
firebase emulators:start --only auth,firestore,functions --project demo-wasilha
```

## Build for release

Android signing: create an upload key, then add `android/key.properties` (not committed):

```
storeFile=/absolute/path/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
flutter build appbundle           # Android → build/app/outputs/bundle/release/
flutter build ipa                 # iOS (on a Mac with Xcode)
```

Without `key.properties`, release builds are signed with the debug key, which is fine for testing only.
For iOS, choose your team and provisioning profile in Xcode.

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
  data/geo_api.dart         Google Places search + Routes API (optional key)
  core/location.dart        GPS pickup + driver position streaming
  core/push.dart            FCM registration, in-app banners, tap → screen
functions/src/index.ts      Cloud Functions: notifications, settlement, orders, top-ups
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
| `trips/{id}/messages` | rider ↔ driver chat |
| `topups/{id}` | top-up intents (`pending` → `paid` by the server) |
| `orders/{id}` | food and store orders |

Trip flow: the rider creates a trip (`requested`) → drivers bid → the rider accepts one (`accepted`) → the driver
moves it to `arriving`, then `inProgress`, then `completed` → the rider rates it and the wallet is charged.

## What's left before launch

- **Real payment provider.** `functions/src/index.ts` has the full flow ready:
  - `onTopupCreated` is where you create the payment session with your provider (Bankak / mBOK / card acquirer).
  - `paymentWebhook` is the HMAC-verified callback that credits the wallet. Set `PAYMENT_WEBHOOK_SECRET` in Secret Manager.
  - Until then, `ALLOW_FAKE_TOPUPS=true` credits top-ups instantly, so keep it for testing only.
- The APNs key in Firebase, for iOS push (see above).
- Fill in the `[bracketed]` values in `docs/privacy-policy.md` and `docs/terms-of-use.md`, have a lawyer review them,
  and host them at a public URL. Both stores ask for that link.
- Store screenshots. The listing text and data-safety answers are in `docs/store-listing.md`.

---

## بالعربية

**التشغيل بدون أي إعداد:** شغّل `flutter pub get` ثم `flutter run`. التطبيق يعمل في «الوضع التجريبي»: سائقون
افتراضيون يقدّمون عروض أسعار لطلبك ويكملون الرحلة، وأي رمز تحقق من 6 أرقام يعمل.

**ربط Firebase:** أنشئ مشروعاً في Firebase، وفعّل تسجيل الدخول بالهاتف وقاعدة Firestore. ضع ملف
`google-services.json` في `android/app/`، وأضف `GoogleService-Info.plist` إلى `ios/Runner` عبر Xcode.
ثم انشر القواعد بالأمر `firebase deploy --only firestore`.

**خرائط Google:** ضع المفتاح `MAPS_API_KEY` في `android/local.properties` وفي `ios/Flutter/Secrets.xcconfig`،
ثم شغّل `flutter run --dart-define=USE_GOOGLE_MAPS=true`.

**ما أُنجز:**
- المحادثة بين الراكب والسائق.
- موقع السائق الحي من GPS، وتحديد موقعك تلقائياً كنقطة انطلاق.
- الإشعارات (FCM).
- عمليات المحفظة على الخادم (Cloud Functions) مع قواعد حماية تمنع التلاعب بالرصيد.
- البحث عن العناوين ومسار الرحلة على الشوارع (بمفتاح Google).
- توقيع نسخة الإصدار.

**المتبقي قبل الإطلاق:**
- ربط مزوّد دفع حقيقي في `functions/src/index.ts`.
- تفعيل الإشعارات في Xcode لنسخة iOS.
- سياسة الخصوصية وصور المتجر.
