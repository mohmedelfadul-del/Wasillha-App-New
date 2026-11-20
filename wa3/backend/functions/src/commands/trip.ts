import { FieldValue } from "firebase-admin/firestore";
import { fail } from "../domain/errors";
import { command, int, optStr, str } from "../lib/command";
import { C, db } from "../lib/firestore";
import { actorFor, loadTrip, transition } from "../lib/trips";

/** Rider or assigned driver cancels before pickup, with a coded reason. */
export const cancelTrip = command("cancelTrip", { audience: "any", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const actor = actorFor(ctx, trip);
  const reason = str(data.reason, "Reason", 40);
  const offers = await tx!.get(ref.collection(C.offers).where("status", "==", "active"));
  const res = transition(tx!, ref, trip, "cancel", actor, ctx, {
    expectedRevision: data.expectedRevision,
    cancelReason: reason,
    patch: { cancellation: { actor, reason, note: optStr(data.note, 300), at: ctx.now }, expiresAt: null },
  });
  for (const o of offers.docs) tx!.update(o.ref, { status: "expired", decidedAt: ctx.now });
  if (trip.driverId) tx!.update(db.collection(C.drivers).doc(trip.driverId), { activeTripId: null, activeRiderId: null, updatedAt: ctx.now });
  return res;
});

/** Each side rates the other once, after completion. Revision-free: ratings don't move the state. */
export const rateTrip = command("rateTrip", { audience: "any", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const actor = actorFor(ctx, trip);
  if (trip.state !== "completed" && trip.state !== "disputed") fail("invalid_transition", "You can rate once the trip is completed");
  const stars = int(data.stars, "Rating", 1, 5);
  const rating = { stars, comment: optStr(data.comment, 500), at: ctx.now };
  if (actor === "rider") {
    if (trip.riderRating) fail("invalid_transition", "You already rated this trip");
    tx!.update(ref, { riderRating: rating, updatedAt: ctx.now });
    tx!.update(db.collection(C.drivers).doc(trip.driverId!), { ratingSum: FieldValue.increment(stars), ratingCount: FieldValue.increment(1) });
  } else if (actor === "driver") {
    if (trip.driverRating) fail("invalid_transition", "You already rated this rider");
    tx!.update(ref, { driverRating: rating, updatedAt: ctx.now });
    tx!.set(db.collection(C.riders).doc(trip.riderId), { ratingSum: FieldValue.increment(stars), ratingCount: FieldValue.increment(1) }, { merge: true });
  } else fail("permission_denied", "Only the rider or driver can rate");
  return { ok: true };
});

/** Rider or driver disputes a completed trip within the window → disputed + case. */
export const disputeTrip = command("disputeTrip", { audience: "any", mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const actor = actorFor(ctx, trip);
  const caseRef = db.collection(C.cases).doc();
  const res = transition(tx!, ref, trip, "dispute", actor, ctx, {
    expectedRevision: data.expectedRevision,
    patch: { dispute: { caseId: caseRef.id, by: actor, at: ctx.now } },
  });
  tx!.set(caseRef, {
    type: "dispute", tripId: ref.id, reporterId: ctx.uid, reporterRole: actor,
    subjectDriverId: trip.driverId, description: str(data.reason, "Reason", 1000),
    status: "open", ownerId: null, priority: "normal", createdAt: ctx.now, updatedAt: ctx.now,
  });
  return { ...res, caseId: caseRef.id };
});
