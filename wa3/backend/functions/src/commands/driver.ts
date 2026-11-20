import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { CATEGORIES, DOCUMENT_TYPES, OPEN_REQUEST_STATES, TUNABLES, type Category, type DocumentType } from "../domain/contract";
import { fail } from "../domain/errors";
import { assertWithinBounds, commissionMinor, toMinor } from "../domain/pricing";
import { entry } from "../domain/ledger";
import { command, int, str } from "../lib/command";
import { backfillForDriver, clearInbox } from "../lib/dispatch";
import { C, db } from "../lib/firestore";
import { insidePolygon, km, type LatLng } from "../lib/geo";
import { loadTrip, transition, type TripDoc } from "../lib/trips";

export const DRIVER_DOCS: readonly DocumentType[] = ["national_id", "driving_license", "driver_photo"];
export const VEHICLE_DOCS: readonly DocumentType[] = ["vehicle_registration", "insurance", "vehicle_photo"];

const driverRef = (uid: string) => db.collection(C.drivers).doc(uid);

export const registerDriver = command("registerDriver", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const name = str(data.name, "Name", 60);
  const user = await getAuth().getUser(ctx.uid);
  const ref = driverRef(ctx.uid);
  const snap = await tx!.get(ref);
  if (snap.exists) {
    tx!.update(ref, { name, updatedAt: ctx.now });
  } else {
    tx!.set(ref, {
      name, phone: user.phoneNumber ?? "", status: "onboarding", online: false,
      activeVehicleId: null, activeCategory: null, activeTripId: null, activeRiderId: null,
      zoneId: null, ratingSum: 0, ratingCount: 0, completedTrips: 0, createdAt: ctx.now, updatedAt: ctx.now,
    });
  }
  return { ok: true };
});

/** Registers an uploaded file (Storage path under drivers/{uid}/) for review. */
export const submitDocument = command("submitDocument", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const type = data.type as DocumentType;
  if (!DOCUMENT_TYPES.includes(type)) fail("validation_failed", "Unknown document type");
  const path = str(data.storagePath, "File", 300);
  if (!path.startsWith(`drivers/${ctx.uid}/`)) fail("permission_denied", "Upload the file to your own folder first");
  const vehicleId = typeof data.vehicleId === "string" ? data.vehicleId : null;
  if (VEHICLE_DOCS.includes(type) !== (vehicleId !== null)) fail("validation_failed", "Vehicle documents belong to a vehicle; personal documents do not");

  const driver = await tx!.get(driverRef(ctx.uid));
  if (!driver.exists) fail("permission_denied", "Create your driver account first");
  let docRef = driverRef(ctx.uid).collection(C.documents).doc(type);
  if (vehicleId) {
    const v = await tx!.get(db.collection(C.vehicles).doc(vehicleId));
    if (!v.exists || v.get("driverId") !== ctx.uid) fail("permission_denied", "Not your vehicle");
    docRef = db.collection(C.vehicles).doc(vehicleId).collection(C.documents).doc(type);
  }
  const existing = await tx!.get(docRef);
  if (existing.get("status") === "approved") fail("invalid_transition", "This document is already approved. Contact support to replace it.");
  // Read all personal docs before writing, to decide the driver's status.
  const personal = vehicleId ? null : await tx!.get(driverRef(ctx.uid).collection(C.documents));

  tx!.set(docRef, {
    type, storagePath: path, status: "pending", reason: null, driverId: ctx.uid, vehicleId,
    submittedAt: ctx.now, claimedBy: null, claimedAt: null, decidedBy: null, decidedAt: null,
  });
  if (personal) {
    const submitted = new Set(personal.docs.map((d) => d.id)).add(type);
    if (DRIVER_DOCS.every((t) => submitted.has(t)) && driver.get("status") === "onboarding") {
      tx!.update(driverRef(ctx.uid), { status: "underReview", updatedAt: ctx.now });
    }
  }
  // Submitting never grants permission to work.
  return { status: "pending" };
});

export const addVehicle = command("addVehicle", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const category = data.category as Category;
  if (!CATEGORIES.includes(category)) fail("validation_failed", "Unknown vehicle category");
  const driver = await tx!.get(driverRef(ctx.uid));
  if (!driver.exists) fail("permission_denied", "Create your driver account first");
  const ref = db.collection(C.vehicles).doc();
  tx!.set(ref, {
    driverId: ctx.uid, category,
    make: str(data.make, "Make", 40), model: str(data.model, "Model", 40),
    color: str(data.color, "Color", 30), plate: str(data.plate, "Plate number", 20).toUpperCase(),
    year: int(data.year, "Year", 1980, 2100), status: "pending", createdAt: ctx.now, updatedAt: ctx.now,
  });
  return { vehicleId: ref.id };
});

export const setActiveVehicle = command("setActiveVehicle", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const id = str(data.vehicleId, "Vehicle", 128);
  const v = await tx!.get(db.collection(C.vehicles).doc(id));
  if (!v.exists || v.get("driverId") !== ctx.uid) fail("permission_denied", "Not your vehicle");
  if (v.get("status") !== "approved") fail("not_verified", "This vehicle hasn't been approved yet");
  const d = await tx!.get(driverRef(ctx.uid));
  if (d.get("activeTripId")) fail("driver_busy", "Finish your current trip first");
  tx!.update(driverRef(ctx.uid), { activeVehicleId: id, activeCategory: v.get("category"), updatedAt: ctx.now });
  return { ok: true };
});

/** Online requires: approved driver, approved active vehicle, fresh GPS inside an active zone. */
export const goOnline = command("goOnline", { audience: "driver", mutating: false }, async (ctx) => {
  const [d, p, zones] = await Promise.all([
    driverRef(ctx.uid).get(),
    db.collection(C.presence).doc(ctx.uid).get(),
    db.collection(C.zones).where("active", "==", true).get(),
  ]);
  if (d.get("status") !== "approved") fail("not_verified", "Your account is not approved yet");
  if (!d.get("activeVehicleId")) fail("validation_failed", "Choose an approved vehicle first");
  const pos = { lat: p.get("lat") as number, lng: p.get("lng") as number };
  if (!p.exists || ctx.now - (p.get("updatedAt") as number) > TUNABLES.locationStaleSeconds * 1000) {
    fail("validation_failed", "We can't see your location. Turn on location and try again.");
  }
  const zone = zones.docs.find((z) => insidePolygon(pos, (z.get("polygon") ?? []) as LatLng[]));
  if (!zone) fail("outside_zone", "You are outside the operating area");
  await driverRef(ctx.uid).update({ online: true, zoneId: zone!.id, onlineSince: ctx.now, updatedAt: ctx.now });
  const waiting = await backfillForDriver(ctx.uid, pos, String(d.get("activeCategory")), zone!.id);
  return { online: true, zoneId: zone!.id, waitingRequests: waiting };
});

export const goOffline = command("goOffline", { audience: "driver", mutating: false }, async (ctx) => {
  await driverRef(ctx.uid).update({ online: false, updatedAt: ctx.now });
  await clearInbox(ctx.uid);
  return { online: false };
});

/** Offer = price + ETA on an open nearby request. One offer per driver per trip (re-offer replaces). */
export const submitOffer = command("submitOffer", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const d = await tx!.get(driverRef(ctx.uid));
  const p = await tx!.get(db.collection(C.presence).doc(ctx.uid));
  const offerRef = ref.collection(C.offers).doc(ctx.uid);
  const prev = await tx!.get(offerRef);
  const vehicle = await tx!.get(db.collection(C.vehicles).doc(String(d.get("activeVehicleId") ?? "-")));

  if (d.get("status") !== "approved") fail("not_verified", "Your account is not approved yet");
  if (d.get("online") !== true) fail("validation_failed", "Go online to send offers");
  if (d.get("activeTripId")) fail("driver_busy", "You already have an active trip");
  if (!vehicle.exists || vehicle.get("status") !== "approved") fail("not_verified", "Your active vehicle isn't approved");
  if (vehicle.get("category") !== trip.category) fail("validation_failed", "Your vehicle doesn't match this request's category");
  if (!OPEN_REQUEST_STATES.includes(trip.state)) fail("offer_expired", "This request is no longer open");
  if ((trip.expiresAt ?? 0) <= ctx.now) fail("offer_expired", "This request has expired");
  if (trip.riderId === ctx.uid) fail("permission_denied", "You can't offer on your own request");
  const pos = { lat: p.get("lat") as number, lng: p.get("lng") as number };
  if (!p.exists || km(pos, trip.pickup) > TUNABLES.nearbyRadiusKm) fail("validation_failed", "This request is too far from you");
  if (!prev.exists && trip.offerCount >= TUNABLES.maxOffersPerTrip) fail("offer_expired", "This request already has enough offers");

  const price = assertWithinBounds(int(data.price, "Price"), trip.quote, "Price");
  const etaMinutes = int(data.etaMinutes, "ETA", 1, 60);
  const ratingCount = (d.get("ratingCount") as number) || 0;
  tx!.set(offerRef, {
    driverId: ctx.uid, price, etaMinutes, status: "active",
    expiresAt: ctx.now + TUNABLES.offerTtlSeconds * 1000, createdAt: ctx.now,
    driver: { name: d.get("name"), ratingAvg: ratingCount ? Math.round(((d.get("ratingSum") as number) / ratingCount) * 10) / 10 : null },
    vehicle: { category: vehicle.get("category"), make: vehicle.get("make"), model: vehicle.get("model"), color: vehicle.get("color"), plate: vehicle.get("plate") },
  });
  if (!prev.exists) tx!.update(ref, { offerCount: FieldValue.increment(1), updatedAt: ctx.now });
  if (trip.state === "searching") transition(tx!, ref, trip, "firstOffer", "system", ctx);
  return { offerId: ctx.uid, expiresAt: ctx.now + TUNABLES.offerTtlSeconds * 1000 };
});

/** Driver-stage commands share one shape: transition with the expected revision. */
function stage(name: string, t: "ackAssignment" | "markArrived" | "startTrip") {
  return command(name, { audience: "driver", mutating: true }, async (ctx, data, tx) => {
    const { ref, trip } = await loadTrip(tx!, data.tripId);
    if (trip.driverId !== ctx.uid) fail("permission_denied", "This trip is not assigned to you");
    return transition(tx!, ref, trip, t, "driver", ctx, { expectedRevision: data.expectedRevision });
  });
}
export const ackAssignment = stage("ackAssignment", "ackAssignment");
export const markArrived = stage("markArrived", "markArrived");
export const startTrip = stage("startTrip", "startTrip");

/** Finish at the destination → arrived, and the server issues the receipt → paymentPending. */
export const finishTrip = command("finishTrip", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  if (trip.driverId !== ctx.uid) fail("permission_denied", "This trip is not assigned to you");
  const a = transition(tx!, ref, trip, "finishTrip", "driver", ctx, { expectedRevision: data.expectedRevision });
  const arrived: TripDoc = { ...trip, state: a.state, revision: a.revision, timestamps: { ...trip.timestamps, arrived: ctx.now } };
  return transition(tx!, ref, arrived, "issueReceipt", "system", ctx, { patch: { amountDue: trip.fare } });
});

/** Driver records the cash collected → ledger (cash + commission) → completed. */
export const recordCash = command("recordCash", { audience: "driver", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  if (trip.driverId !== ctx.uid) fail("permission_denied", "This trip is not assigned to you");
  const fare = trip.fare ?? 0;
  const amount = int(data.amount, "Cash amount", 0, Math.max(fare * 3, 1));
  const mismatch = amount !== fare;
  const res = transition(tx!, ref, trip, "recordCash", "driver", ctx, {
    expectedRevision: data.expectedRevision,
    patch: { cash: { amount, recordedAt: ctx.now, mismatch } },
  });
  const ledger = db.collection(C.ledger);
  if (amount > 0) {
    tx!.set(ledger.doc(), entry({ driverId: ctx.uid, kind: "cash_collected", amountMinor: toMinor(amount), tripId: ref.id, createdBy: ctx.uid, createdAt: ctx.now }));
  }
  const commission = commissionMinor(toMinor(fare), trip.commissionBps);
  if (commission > 0) {
    tx!.set(ledger.doc(), entry({ driverId: ctx.uid, kind: "commission_due", amountMinor: commission, tripId: ref.id, createdBy: "system", createdAt: ctx.now }));
  }
  if (mismatch) {
    tx!.set(db.collection(C.cases).doc(), {
      type: "support", tripId: ref.id, reporterId: "system", reporterRole: "system", subjectDriverId: ctx.uid,
      description: `Cash recorded (${amount}) differs from the agreed fare (${fare}).`,
      status: "open", ownerId: null, priority: "normal", createdAt: ctx.now, updatedAt: ctx.now,
    });
  }
  tx!.update(driverRef(ctx.uid), { activeTripId: null, activeRiderId: null, completedTrips: FieldValue.increment(1), updatedAt: ctx.now });
  return { ...res, commissionMinor: commission };
});
