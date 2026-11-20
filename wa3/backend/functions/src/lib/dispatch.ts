import { FieldValue } from "firebase-admin/firestore";
import { OPEN_REQUEST_STATES, TUNABLES } from "../domain/contract";
import { C, db, now } from "./firestore";
import { geohashBounds, km, millis, type LatLng } from "./geo";
import type { TripDoc } from "./trips";

/**
 * Least-privilege request feed: drivers never query trips. The server writes a
 * sanitized card into inbox/{driverUid}/requests/{tripId} for each eligible
 * driver within the radius, and removes it when the request closes.
 */

export interface InboxCard {
  tripId: string;
  category: string;
  pickup: { lat: number; lng: number; label: string };
  dropoffLabel: string;
  distanceToPickupKm: number;
  tripDistanceMeters: number;
  proposedFare: number;
  minFare: number;
  maxFare: number;
  currency: string;
  expiresAt: number;
  createdAt: number;
}

const dispatchRef = (tripId: string) => db.collection(C.trips).doc(tripId).collection("private").doc(C.dispatch);

export function cardFor(tripId: string, t: TripDoc, driverPos: LatLng): InboxCard {
  return {
    tripId,
    category: t.category,
    pickup: t.pickup,
    dropoffLabel: t.dropoff.label,
    distanceToPickupKm: Math.round(km(driverPos, t.pickup) * 10) / 10,
    tripDistanceMeters: t.route.distanceMeters,
    proposedFare: t.proposedFare ?? t.quote.referenceFare,
    minFare: t.quote.minFare,
    maxFare: t.quote.maxFare,
    currency: t.currency,
    expiresAt: t.expiresAt ?? now(),
    createdAt: now(),
  };
}

interface Candidate { uid: string; pos: LatLng }

/** Online, approved, free drivers whose active vehicle matches, within the radius. */
async function eligibleDriversNear(t: TripDoc): Promise<Candidate[]> {
  const fresh = now() - TUNABLES.locationStaleSeconds * 1000 * 4; // tolerate a missed heartbeat or two
  const bounds = geohashBounds(t.pickup, TUNABLES.nearbyRadiusKm);
  const snaps = await Promise.all(bounds.map(([s, e]) =>
    db.collection(C.presence).orderBy("geohash").startAt(s).endAt(e).get()));
  const near = new Map<string, LatLng>();
  for (const q of snaps) for (const d of q.docs) {
    const p = { lat: d.get("lat") as number, lng: d.get("lng") as number };
    if (millis(d.get("updatedAt")) >= fresh && km(p, t.pickup) <= TUNABLES.nearbyRadiusKm) near.set(d.id, p);
  }
  if (near.size === 0) return [];
  const ids = [...near.keys()];
  const drivers = await db.getAll(...ids.map((id) => db.collection(C.drivers).doc(id)));
  return drivers
    .filter((d) => d.exists && d.get("status") === "approved" && d.get("online") === true && !d.get("activeTripId")
      && d.get("activeCategory") === t.category && d.id !== t.riderId)
    .map((d) => ({ uid: d.id, pos: near.get(d.id)! }));
}

/** New open request → cards for every eligible driver nearby. */
export async function fanOut(tripId: string, t: TripDoc) {
  const drivers = await eligibleDriversNear(t);
  const batch = db.batch();
  for (const d of drivers) {
    batch.set(db.collection(C.inbox).doc(d.uid).collection("requests").doc(tripId), cardFor(tripId, t, d.pos));
  }
  batch.set(dispatchRef(tripId), { drivers: FieldValue.arrayUnion(...drivers.map((d) => d.uid), "_"), updatedAt: now() }, { merge: true });
  await batch.commit();
  return drivers.length;
}

/** Request closed (assigned, cancelled, expired) → remove every card. */
export async function cleanup(tripId: string) {
  const snap = await dispatchRef(tripId).get();
  const ids = ((snap.get("drivers") as string[] | undefined) ?? []).filter((x) => x !== "_");
  const batch = db.batch();
  for (const id of ids) batch.delete(db.collection(C.inbox).doc(id).collection("requests").doc(tripId));
  await batch.commit();
}

/** Driver just went online → show open requests already waiting nearby. */
export async function backfillForDriver(uid: string, pos: LatLng, category: string, zoneId: string) {
  const open = await db.collection(C.trips)
    .where("zoneId", "==", zoneId).where("state", "in", [...OPEN_REQUEST_STATES]).where("category", "==", category).get();
  let n = 0;
  for (const d of open.docs) {
    const t = d.data() as TripDoc;
    if (t.riderId === uid || km(pos, t.pickup) > TUNABLES.nearbyRadiusKm || (t.expiresAt ?? 0) <= now()) continue;
    await db.collection(C.inbox).doc(uid).collection("requests").doc(d.id).set(cardFor(d.id, t, pos));
    await dispatchRef(d.id).set({ drivers: FieldValue.arrayUnion(uid) }, { merge: true });
    n++;
  }
  return n;
}

/** Driver went offline or got a trip → clear their whole inbox. */
export async function clearInbox(uid: string) {
  const q = await db.collection(C.inbox).doc(uid).collection("requests").get();
  const batch = db.batch();
  q.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}
