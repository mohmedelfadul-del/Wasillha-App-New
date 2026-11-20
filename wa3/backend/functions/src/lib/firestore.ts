import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";

if (getApps().length === 0) initializeApp();

export const db: Firestore = getFirestore();

/** Collection names — the only place they are spelled. */
export const C = {
  riders: "riders",
  drivers: "drivers",
  documents: "documents",      // drivers/{uid}/documents/{type}
  vehicles: "vehicles",
  presence: "presence",        // presence/{driverUid}  (driver-written GPS)
  trips: "trips",
  offers: "offers",            // trips/{id}/offers/{driverUid}
  dispatch: "dispatch",        // trips/{id}/private/dispatch (server only)
  inbox: "inbox",              // inbox/{driverUid}/requests/{tripId}
  ledger: "ledger",
  idempotency: "idempotency",
  pricing: "pricing",          // pricing/{zoneId}__{category}
  zones: "zones",
  cases: "cases",
  audit: "audit",
  staff: "staff",
  shares: "shares",
} as const;

/** Injectable clock so tests and the sweeper agree on "now". */
export const now = () => Date.now();
