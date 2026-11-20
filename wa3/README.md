# Wasilha v1 · وصلها

An on-demand ride platform for Khartoum:
- A rider sets pickup and destination and sees a fair reference price.
- The rider proposes a fare within server-defined bounds, and nearby verified drivers reply with offers (price + ETA).
- The rider accepts one, tracks the driver live, pays in **cash** and rates the trip.
- An operations team supervises everything from a web console.

| Product | Path | Platform |
|---|---|---|
| Rider app | `apps/rider` | Flutter (Android/iOS) |
| Driver app | `apps/driver` | Flutter (Android/iOS) |
| Operations console | `apps/ops` | Flutter Web |
| Backend | `backend/` | Firebase: Auth, Firestore, Cloud Functions (TypeScript) |
| Shared contract and design system | `packages/wa3_core` | Dart package |

Three separate products with their own auth roles, navigation and release cycle. No role switching.
For the architecture, the trip state machine and the data model, see [`docs/architecture.md`](docs/architecture.md).

## Assumptions (each is a single setting)

| Brief placeholder | Assumed value | Where to change |
|---|---|---|
| Product name `[WA 3]` | Wasilha · وصلها | app labels, `S` strings |
| City | Khartoum, Omdurman, Bahri (one zone) | `backend/functions/src/seedData.ts` (zone polygon) |
| Languages | Arabic (RTL) primary, English secondary | `wa3_core/lib/src/l10n/strings.dart` |
| Currency | SDG, whole units; the ledger stores ×100 integers | `TUNABLES.currency`, `minorPerUnit` |
| Categories | rickshaw, motorbike, economy, comfort, family | `contract.ts` `CATEGORIES` (+ Dart mirror) |
| Offer expiry `[N]` | 60 s | `TUNABLES.offerTtlSeconds` |
| Request expiry `[N]` | 5 min, then cancelled with reason `no_offers`; the rider gets a one-tap retry | `TUNABLES.requestTtlSeconds` |
| Dispute window `[N]` | 48 h | `TUNABLES.disputeWindowHours` |
| Stuck trip `[N]` | 10 min in one state | `TUNABLES.stuckTripMinutes` |
| Nearby radius | 15 km | `TUNABLES.nearbyRadiusKm` |
| Pricing | Placeholder fares per category, 10–15 % commission. **Not researched — set real prices in the console.** | `seedData.ts`, then the console |
| Brand / action / ink / surface colors | `#9D00FF` / `#6F00B8` (8.9:1 with white) / `#0A0908` / `#FBFAF6` | `wa3_core/lib/src/design/tokens.dart` |
| Fonts | IBM Plex Sans Arabic (headings and body), bundled locally | `wa3_core/fonts` |
| Database | **Firestore instead of PostgreSQL** (your choice). See below. | — |
| Device attestation | Firebase App Check: Play Integrity / App Attest | `APP_CHECK_ENFORCE` |
| SMS OTP | Firebase Phone Auth | — |
| Ops 2FA | Firebase Auth TOTP multi-factor (needs Identity Platform) | `REQUIRE_STAFF_MFA` |

**Assumptions about the state machine:**
- `driverAssigned → driverEnRoute` happens when the driver app acknowledges the assignment. It does this automatically, and idempotently.
- When the driver taps Finish, the trip moves to `arrived`, and the server issues the receipt (`paymentPending`) in the same command.
- If the driver records a cash amount that differs from the fare, the trip still completes and a support case opens.
- A dispute resolved by operations returns the trip to `completed`, with the resolution recorded.

**Firestore in place of PostgreSQL:**
- The trip state machine runs in Cloud Functions transactions. Every command carries an idempotency key, which is stored in the same transaction, and the expected revision.
- The ledger is an append-only collection that only functions can write. Amounts are integer minor units, and balances are always derived (`summarize`), never stored.
- Commission is rounded to whole SDG so every debt can be settled in cash. The tests caught this: a fractional commission left a debt that could never be paid.

## Run it locally (emulator)

```bash
# 1. Backend
cd backend/functions && npm ci && npm run build && cd ..
npx firebase-tools emulators:start --only auth,firestore,functions,storage --project demo-wa3
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/scripts/seed.js        # zone + pricing

# 2. Apps (another terminal). On the Android emulator use EMULATOR_HOST=10.0.2.2
cd apps/rider  && flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2
cd apps/driver && flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2
cd apps/ops    && flutter run -d chrome --dart-define=USE_EMULATOR=true --dart-define=FIREBASE_PROJECT_ID=demo-wa3 \
                  --dart-define=FIREBASE_API_KEY=fake --dart-define=FIREBASE_APP_ID=1:1:web:1
```

- The emulator uses `MAPS_FAKE=true`, so routes are straight-line estimates and the apps label them that way. It also turns staff MFA off.
- Phone sign-in on the auth emulator: the SMS code appears in the emulator log.
- To grant a staff role: `node functions/scripts/seed.js --staff <uid> <admin|operations|kyc|support|finance>`.

## Tests

| Where | What | Command |
|---|---|---|
| `backend/functions/test/unit` | State machine, pricing bounds, ledger math, idempotency/revision (44) | `npm test` |
| `backend/functions/test/emulator` | Full trip E2E through the real commands, KYC claim locking, settlement, expiry, security rules (22) | see CI |
| `packages/wa3_core/test` | Contract matches the server, formatting, geohash, state widgets at 320 px / 200 % text, RTL | `flutter test` |
| `apps/*/test` | Screen states per app | `flutter test` |

CI: `.github/workflows/wa3.yml` runs all of these and builds the APKs and the console.

## Deploy (staging / prod)

1. Create one Firebase project per environment (`wa3-staging`, `wa3-prod`) and enable:
   - Phone Auth.
   - Identity Platform, with TOTP MFA turned on.
   - Firestore in `europe-west1`.
   - Storage.
   - App Check.
2. `cp functions/.env.example functions/.env.wa3-staging`. Then set the Maps key as a secret: `firebase functions:secrets:set GOOGLE_MAPS_SERVER_KEY`. That key needs the Routes, Places and Geocoding APIs, and only the server uses it.
3. `firebase deploy --only firestore,storage,functions --project wa3-staging`, then run the seed script with a service account.
4. Apps:
   - `google-services.json` / `GoogleService-Info.plist` for `sd.wasilha.rider` and `sd.wasilha.driver`.
   - A Maps SDK key restricted to the apps, for map tiles only.
   - The ops console gets its web config through `--dart-define`.

**Automated:** see [`docs/deploy.md`](docs/deploy.md) — the **WA3 deploy** workflow does all of the above.

See [`docs/operations.md`](docs/operations.md) for monitoring, alerts and the backup drill.
