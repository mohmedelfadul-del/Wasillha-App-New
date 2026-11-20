# Architecture

## Principles

1. **The server owns the truth.**
   - Clients read Firestore documents, and only request changes through callable commands (`backend/functions/src/commands`).
   - The single exception is the driver's own GPS document, `presence/{uid}`.
2. **Commands are idempotent and revision-checked.**
   - `command()` (`lib/command.ts`) opens one transaction. In it, the command reads `idempotency/{uid}_{key}`, runs the handler, and stores the result.
   - A retry with the same key replays the first result. The same key with a different payload is rejected (`idempotency_mismatch`).
   - Trip transitions require `expectedRevision`. A stale value returns `stale_revision`.
3. **One state machine.** `domain/tripMachine.ts` is the only place that decides which transitions are legal, and for which actor.
4. **Money is a ledger.** `domain/ledger.ts`:
   - Entries are append-only, positive integers in minor units, with a kind.
   - Balances are derived, never stored.
   - Settlements cannot exceed what is owed.
5. **Least privilege.** Enforced by `backend/firestore.rules` and proven by `test/emulator/rules.test.ts`:
   - Riders see only their trips.
   - Drivers see only their own inbox of sanitized nearby requests, and their assigned trip.
   - Staff access is role-scoped and audited (`audit` collection, immutable).

## Trip state machine

```
draft → searching → offering → driverAssigned → driverEnRoute → driverArrived
      → inProgress → arrived → paymentPending → completed
any pre-pickup state → cancelled (actor + coded reason)
completed → disputed (rider or driver, within 48 h) → completed (ops resolves)
```

| Transition | Actor | Command |
|---|---|---|
| draft → searching | rider | `confirmRequest` (fare within quote bounds) |
| searching → offering | system | first `submitOffer` |
| offering → driverAssigned | rider | `acceptOffer` (other offers → `lost`; driver gets `activeTripId`) |
| driverAssigned → driverEnRoute | driver app (automatic) | `ackAssignment` |
| → driverArrived → inProgress | driver | `markArrived`, `startTrip` |
| inProgress → arrived → paymentPending | driver, then system | `finishTrip` (receipt issued in the same transaction) |
| paymentPending → completed | driver | `recordCash` → ledger `cash_collected` + `commission_due` |
| pre-pickup → cancelled | rider / driver (after assignment) / ops / system | `cancelTrip`, `opsCancelTrip`, sweeper (`no_offers`, `draft_expired`) |
| completed → disputed | rider / driver | `disputeTrip` (opens a dispute case) |
| disputed → completed | ops | `resolveDispute` |

## Dispatch

1. A trip enters `searching`.
2. The `onTripWritten` trigger finds drivers who meet all of these:
   - Online and approved.
   - Free (no active trip).
   - Active vehicle in the same category.
   - Fresh GPS within 15 km of pickup (geohash range queries on `presence`).
3. For each match, it writes a sanitized card to `inbox/{driverUid}/requests/{tripId}`.
4. The cards are removed when the request closes.
5. A driver who goes online receives a backfill of requests already waiting.

The `sweeper` runs every minute and does the following:
- Expires offers, requests and drafts.
- Flags trips as stuck (no state change within 10 min) or as having a stale driver location (none in 30 s). The console highlights both flags.
- Takes drivers offline after 2 min of silence.
- Logs `trip.stuck` as an error for alerting.

## Data model (Firestore)

| Path | Written by | Read by |
|---|---|---|
| `riders/{uid}` | functions | owner, staff |
| `drivers/{uid}` (+ `documents/{type}`) | functions | owner, staff |
| `vehicles/{id}` (+ `documents/{type}`) | functions | owning driver, staff |
| `presence/{driverUid}` | **driver client** (validated, server timestamp) | owner, assigned rider, staff |
| `trips/{id}` | functions | rider, assigned driver, staff |
| `trips/{id}/offers/{driverUid}` | functions | trip's rider, that driver, staff |
| `trips/{id}/private/dispatch` | functions | staff |
| `inbox/{driverUid}/requests/{tripId}` | functions | that driver |
| `ledger/{id}` | functions (append-only) | that driver, finance/operations |
| `pricing/{zone}__{category}` | functions (`updatePricing`, audited) | staff |
| `zones/{id}` | seed / admin | signed-in users |
| `cases/{id}` | functions | reporter, staff |
| `audit/{id}` | functions | admin |
| `idempotency/{uid}_{key}` | functions | nobody |
| `shares/{token}` | functions | `sharedTrip` HTTP page only (no phone numbers) |

## Maps

The `createDraft`, `placesSearch` and `placeLabel` commands call Google Routes, Places and Geocoding with a server-only secret. The apps hold only a restricted Maps SDK key, used for map tiles.

If routing fails, the server returns `maps_unavailable` and the apps say so. They never invent a price.
