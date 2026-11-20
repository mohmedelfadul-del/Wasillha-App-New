import { getAuth } from "firebase-admin/auth";
import { CATEGORIES, TUNABLES, type Category } from "../domain/contract";
import { fail } from "../domain/errors";
import { assertWithinBounds, quote } from "../domain/pricing";
import { command, int, str } from "../lib/command";
import { C, db } from "../lib/firestore";
import { assertLatLng, assertPlace, insidePolygon, type LatLng } from "../lib/geo";
import { labelFor, route, searchPlaces } from "../lib/maps";
import { loadTrip, transition, zoneAndPricing, type TripDoc } from "../lib/trips";

const NON_TERMINAL = ["searching", "offering", "driverAssigned", "driverEnRoute", "driverArrived", "inProgress", "arrived", "paymentPending"];

async function zoneFor(p: LatLng): Promise<string> {
  const zones = await db.collection(C.zones).where("active", "==", true).get();
  const z = zones.docs.find((d) => insidePolygon(p, (d.get("polygon") ?? []) as LatLng[]));
  if (!z) return fail("outside_zone", "Wasilha doesn't operate at this pickup point yet");
  return z.id;
}

/** Minimal profile after phone sign-in. */
export const registerRider = command("registerRider", { audience: "rider", mutating: true }, async (ctx, data, tx) => {
  const name = str(data.name, "Name", 60);
  const lang = data.lang === "en" ? "en" : "ar";
  const user = await getAuth().getUser(ctx.uid);
  tx!.set(db.collection(C.riders).doc(ctx.uid), { name, lang, phone: user.phoneNumber ?? "", updatedAt: ctx.now, createdAt: ctx.now }, { merge: true });
  return { ok: true };
});

/**
 * Draft = route + reference price for one category. Replaces the rider's
 * previous draft. The route/maps call happens before the transaction.
 */
export const createDraft = command("createDraft", { audience: "rider", mutating: true, maps: true }, async (ctx, data, tx) => {
  const pickup = assertPlace(data.pickup, "pickup");
  const dropoff = assertPlace(data.dropoff, "destination");
  const category = data.category as Category;
  if (!CATEGORIES.includes(category)) fail("validation_failed", "Unknown vehicle category");
  const zoneId = await zoneFor(pickup);
  const r = await route(pickup, dropoff);
  if (r.distanceMeters < 200) fail("validation_failed", "Pickup and destination are too close");

  {
    const riderSnap = await tx!.get(db.collection(C.riders).doc(ctx.uid));
    if (!riderSnap.exists) fail("permission_denied", "Complete your profile first");
    const active = await tx!.get(db.collection(C.trips).where("riderId", "==", ctx.uid).where("state", "in", NON_TERMINAL).limit(1));
    if (!active.empty) fail("invalid_transition", "You already have an active trip", { tripId: active.docs[0].id });
    const drafts = await tx!.get(db.collection(C.trips).where("riderId", "==", ctx.uid).where("state", "==", "draft"));
    const pricing = await zoneAndPricing(tx!, zoneId, category);
    const q = quote(pricing, r.distanceMeters, r.durationSeconds);

    for (const d of drafts.docs) {
      tx!.update(d.ref, { state: "cancelled", revision: (d.get("revision") as number) + 1, cancellation: { actor: "system", reason: "draft_expired", note: null, at: ctx.now }, "timestamps.cancelled": ctx.now, updatedAt: ctx.now });
    }
    const ref = db.collection(C.trips).doc();
    const trip: TripDoc = {
      riderId: ctx.uid,
      riderName: String(riderSnap.get("name") ?? ""),
      riderPhone: String(riderSnap.get("phone") ?? ""),
      state: "draft",
      revision: 1,
      category,
      zoneId,
      pickup,
      dropoff,
      route: r,
      quote: q,
      commissionBps: pricing.commissionBps,
      currency: TUNABLES.currency,
      proposedFare: null,
      fare: null,
      driverId: null,
      driver: null,
      vehicle: null,
      acceptedOfferId: null,
      expiresAt: ctx.now + TUNABLES.draftTtlSeconds * 1000,
      offerCount: 0,
      cash: null,
      cancellation: null,
      riderRating: null,
      driverRating: null,
      dispute: null,
      timestamps: { draft: ctx.now },
      flags: { stuck: false, locationStale: false },
      createdAt: ctx.now,
      updatedAt: ctx.now,
    };
    tx!.set(ref, trip);
    return { tripId: ref.id, revision: 1, quote: q, route: { distanceMeters: r.distanceMeters, durationSeconds: r.durationSeconds, polyline: r.polyline, source: r.source } };
  }
});

/** Rider confirms a proposed fare within the server's bounds → searching. */
export const confirmRequest = command("confirmRequest", { audience: "rider", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  if (trip.riderId !== ctx.uid) fail("permission_denied", "This trip is not yours");
  const fare = assertWithinBounds(int(data.proposedFare, "Proposed fare"), trip.quote, "Proposed fare");
  return transition(tx!, ref, trip, "confirm", "rider", ctx, {
    expectedRevision: data.expectedRevision,
    patch: { proposedFare: fare, expiresAt: ctx.now + TUNABLES.requestTtlSeconds * 1000 },
  });
});

/** Rider accepts exactly one active, unexpired offer. Other offers are marked lost. */
export const acceptOffer = command("acceptOffer", { audience: "rider", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  if (trip.riderId !== ctx.uid) fail("permission_denied", "This trip is not yours");
  const offerId = str(data.offerId, "offerId", 128);
  const offerRef = ref.collection(C.offers).doc(offerId);
  const offerSnap = await tx!.get(offerRef);
  const offer = offerSnap.data();
  if (!offer || offer.status !== "active") fail("offer_expired", "This offer is no longer available");
  if ((offer!.expiresAt as number) <= ctx.now) fail("offer_expired", "This offer has expired");
  const driverRef = db.collection(C.drivers).doc(offerId);
  const driverSnap = await tx!.get(driverRef);
  if (driverSnap.get("activeTripId")) fail("driver_busy", "This driver just took another trip");
  if (driverSnap.get("online") !== true) fail("offer_expired", "This driver went offline");
  const others = await tx!.get(ref.collection(C.offers).where("status", "==", "active"));

  const res = transition(tx!, ref, trip, "acceptOffer", "rider", ctx, {
    expectedRevision: data.expectedRevision,
    patch: {
      driverId: offerId,
      // Phone is revealed only to the rider who accepted (for the call button).
      driver: { ...offer!.driver, phone: String(driverSnap.get("phone") ?? "") },
      vehicle: offer!.vehicle,
      fare: offer!.price,
      acceptedOfferId: offerId,
      expiresAt: null,
    },
  });
  tx!.update(offerRef, { status: "accepted", decidedAt: ctx.now });
  for (const o of others.docs) if (o.id !== offerId) tx!.update(o.ref, { status: "lost", decidedAt: ctx.now });
  tx!.update(driverRef, { activeTripId: ref.id, activeRiderId: ctx.uid, updatedAt: ctx.now });
  // Monitoring: time from request to assignment (log-based metric).
  console.log(JSON.stringify({ metric: "time_to_assign_seconds", value: Math.round((ctx.now - (trip.timestamps.searching ?? ctx.now)) / 1000), tripId: ref.id, zoneId: trip.zoneId }));
  return res;
});

/** In-trip safety report; opens a safety case for operations (state unchanged). */
export const reportSafety = command("reportSafety", { audience: "rider", mutating: true }, async (ctx, data, tx) => {
  const { trip } = await loadTrip(tx!, data.tripId);
  if (trip.riderId !== ctx.uid) fail("permission_denied", "This trip is not yours");
  const caseRef = db.collection(C.cases).doc();
  tx!.set(caseRef, {
    type: "safety", tripId: String(data.tripId), reporterId: ctx.uid, reporterRole: "rider",
    subjectDriverId: trip.driverId, description: str(data.description, "Description", 1000),
    status: "open", ownerId: null, priority: "urgent", createdAt: ctx.now, updatedAt: ctx.now,
  });
  return { caseId: caseRef.id };
});

/** Creates a time-limited share link for the live trip. */
export const shareTrip = command("shareTrip", { audience: "rider", mutating: true }, async (ctx, data, tx) => {
  const { trip } = await loadTrip(tx!, data.tripId);
  if (trip.riderId !== ctx.uid) fail("permission_denied", "This trip is not yours");
  const token = db.collection(C.shares).doc();
  tx!.set(token, { tripId: String(data.tripId), riderId: ctx.uid, createdAt: ctx.now, expiresAt: ctx.now + 6 * 3600_000 });
  return { token: token.id };
});

/** Places search through the server proxy (no client key). */
export const placesSearch = command("placesSearch", { audience: "rider", mutating: false, maps: true }, async (_ctx, data) => {
  const q = str(data.query, "Search text", 120);
  const near = assertLatLng(data.near, "location");
  return { results: await searchPlaces(q, near, String(data.lang ?? "ar")) };
});

export const placeLabel = command("placeLabel", { audience: "rider", mutating: false, maps: true }, async (_ctx, data) => {
  const p = assertLatLng(data.point, "point");
  return { label: await labelFor(p, String(data.lang ?? "ar")) };
});

