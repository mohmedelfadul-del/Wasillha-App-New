import { logger } from "firebase-functions";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { DRIVER_ACTIVE_STATES, OPEN_REQUEST_STATES, TUNABLES, type TripState } from "./domain/contract";
import { nextState } from "./domain/tripMachine";
import { cleanup, clearInbox, fanOut } from "./lib/dispatch";
import { C, db, now } from "./lib/firestore";
import { millis } from "./lib/geo";
import type { TripDoc } from "./lib/trips";

const isOpen = (s?: TripState) => !!s && OPEN_REQUEST_STATES.includes(s);

/** Dispatch side effects of trip state changes. */
export const onTripWritten = onDocumentWritten({ document: "trips/{tripId}", region: "europe-west1" }, async (event) => {
  const before = event.data?.before.data() as TripDoc | undefined;
  const after = event.data?.after.data() as TripDoc | undefined;
  const id = event.params.tripId;
  if (!after) return;
  if (after.state === "searching" && before?.state !== "searching") {
    const n = await fanOut(id, after);
    logger.info("dispatch.fanout", { tripId: id, drivers: n });
  }
  if (isOpen(before?.state) && !isOpen(after.state)) await cleanup(id);
  if (after.state === "driverAssigned" && after.driverId) await clearInbox(after.driverId);
});

/** System cancel through the state machine (no revision: the system is authoritative). */
async function systemCancel(id: string, reason: "no_offers" | "draft_expired") {
  await db.runTransaction(async (tx) => {
    const ref = db.collection(C.trips).doc(id);
    const t = (await tx.get(ref)).data() as TripDoc | undefined;
    if (!t || (t.expiresAt ?? Infinity) > now()) return;
    const to = nextState({ state: t.state, transition: "cancel", actor: "system", cancelReason: reason });
    const offers = await tx.get(ref.collection(C.offers).where("status", "==", "active"));
    tx.update(ref, { state: to, revision: t.revision + 1, cancellation: { actor: "system", reason, note: null, at: now() }, expiresAt: null, [`timestamps.${to}`]: now(), updatedAt: now() });
    offers.docs.forEach((o) => tx.update(o.ref, { status: "expired", decidedAt: now() }));
  });
}

/**
 * Every minute: expire offers, requests and drafts; flag stuck trips and
 * stale driver locations; take silent drivers offline. Emits structured logs
 * that log-based alerts watch (see wa3/docs/operations.md).
 */
export const sweeper = onSchedule({ schedule: "every 1 minutes", region: "europe-west1" }, async () => {
  await sweep();
});

export async function sweep() {
  const t = now();
  const offers = await db.collectionGroup(C.offers).where("status", "==", "active").where("expiresAt", "<=", t).get();
  await Promise.all(offers.docs.map((o) => o.ref.update({ status: "expired", decidedAt: t })));

  const open = await db.collection(C.trips).where("state", "in", [...OPEN_REQUEST_STATES]).where("expiresAt", "<=", t).get();
  for (const d of open.docs) await systemCancel(d.id, "no_offers");
  const drafts = await db.collection(C.trips).where("state", "==", "draft").where("expiresAt", "<=", t).get();
  for (const d of drafts.docs) await systemCancel(d.id, "draft_expired");

  const active = await db.collection(C.trips).where("state", "in", [...DRIVER_ACTIVE_STATES]).get();
  for (const d of active.docs) {
    const trip = d.data() as TripDoc;
    const since = trip.timestamps[trip.state] ?? trip.updatedAt;
    const stuck = t - since > TUNABLES.stuckTripMinutes * 60_000;
    const p = trip.driverId ? await db.collection(C.presence).doc(trip.driverId).get() : null;
    const stale = !p?.exists || t - millis(p.get("updatedAt")) > TUNABLES.locationStaleSeconds * 1000;
    if (stuck !== trip.flags.stuck || stale !== trip.flags.locationStale) {
      await d.ref.update({ "flags.stuck": stuck, "flags.locationStale": stale });
    }
    if (stuck) logger.error("trip.stuck", { alert: "stuck_trip", tripId: d.id, state: trip.state, minutes: Math.round((t - since) / 60_000) });
  }

  // Drivers who stopped reporting location for 2 minutes go offline.
  const online = await db.collection(C.drivers).where("online", "==", true).get();
  for (const d of online.docs) {
    if (d.get("activeTripId")) continue;
    const p = await db.collection(C.presence).doc(d.id).get();
    if (!p.exists || t - millis(p.get("updatedAt")) > 120_000) {
      await d.ref.update({ online: false, offlineReason: "location_lost", updatedAt: t });
      await clearInbox(d.id);
    }
  }
  return { expiredOffers: offers.size, expiredRequests: open.size };
}

/** Public, read-only live view for a shared trip link. Shows no phone numbers. */
export const sharedTrip = onRequest({ region: "europe-west1" }, async (req, res) => {
  const token = String(req.query.t ?? "");
  const share = token ? await db.collection(C.shares).doc(token).get() : null;
  if (!share?.exists || (share.get("expiresAt") as number) < now()) {
    res.status(404).send("This link has expired.");
    return;
  }
  const trip = (await db.collection(C.trips).doc(share.get("tripId")).get()).data() as TripDoc | undefined;
  const p = trip?.driverId ? (await db.collection(C.presence).doc(trip.driverId).get()).data() : undefined;
  const fresh = p && now() - millis(p.updatedAt) <= TUNABLES.locationStaleSeconds * 1000;
  const esc = (s: unknown) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]!));
  res.set("Cache-Control", "no-store").send(`<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="15">
<title>وصلها · رحلة مشتركة</title><body style="font-family:system-ui;max-width:480px;margin:24px auto;padding:0 16px;color:#0A0908">
<h1 style="font-size:20px">رحلة مشتركة · Shared trip</h1>
<p>الحالة / Status: <b>${esc(trip?.state)}</b></p>
<p>السائق / Driver: ${esc(trip?.driver?.name?.split(" ")[0])} · ${esc(trip?.vehicle?.color)} ${esc(trip?.vehicle?.make)} ${esc(trip?.vehicle?.model)} · <bdi dir="ltr">${esc(trip?.vehicle?.plate)}</bdi></p>
<p>من / From: ${esc(trip?.pickup.label)}<br>إلى / To: ${esc(trip?.dropoff.label)}</p>
${p ? `<p>${fresh ? "الموقع مباشر · Live location" : "⚠ آخر موقع معروف قديم · Location is stale"}: <a href="https://maps.google.com/?q=${p.lat},${p.lng}">${(p.lat as number).toFixed(5)}, ${(p.lng as number).toFixed(5)}</a></p>` : ""}
<p style="color:#6B6862;font-size:13px">تتحدث الصفحة كل ١٥ ثانية · Refreshes every 15 s</p></body></html>`);
});
