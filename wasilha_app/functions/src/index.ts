/**
 * Wasilha Cloud Functions.
 *
 * Moves everything that touches money or other users off the phone:
 *  - push notifications (new requests, bids, accepted, driver arriving, chat, orders)
 *  - charging the rider and crediting the driver when a trip is rated
 *  - charging food orders
 *  - crediting wallet top-ups (after the payment provider confirms — see paymentWebhook)
 *
 * The app writes "intent" documents; these functions apply the effects atomically.
 */
import * as crypto from "crypto";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Transaction } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = getFirestore();
const COMMISSION = Number(process.env.COMMISSION_RATE ?? "0.15");
const ALLOW_FAKE_TOPUPS = process.env.ALLOW_FAKE_TOPUPS === "true";

type Data = FirebaseFirestore.DocumentData;

// ── Helpers ─────────────────────────────────────────────────

/** Sends a push to every device of a user and drops tokens that are no longer valid. */
async function notifyUser(uid: string | undefined | null, title: string, body: string, data: Record<string, string> = {}) {
  if (!uid) return;
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  const tokens: string[] = snap.get("fcmTokens") ?? [];
  // Keep an in-app copy (Notifications screen).
  await ref.collection("notifications").add({
    title, body, kind: data.kind ?? "trip", createdAt: Date.now(), read: false,
  });
  if (tokens.length === 0) return;
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
  const dead = res.responses
    .map((r, i) => (!r.success && /registration-token-not-registered|invalid-argument/.test(r.error?.code ?? "") ? tokens[i] : null))
    .filter((t): t is string => t !== null);
  if (dead.length) await ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
}

function txn(tx: Transaction, uid: string, title: string, amount: number, kind: string) {
  tx.set(db.collection("users").doc(uid).collection("transactions").doc(), {
    title, amount, kind, createdAt: Date.now(),
  });
}

const sdg = (n: number) => `${Math.round(n).toLocaleString("en-US")} SDG`;

// ── Trips ───────────────────────────────────────────────────

/** New ride request → notify online drivers. */
export const onTripCreated = onDocumentCreated("trips/{tripId}", async (event) => {
  const t = event.data?.data();
  if (!t || t.status !== "requested") return;
  const drivers = await db.collection("users")
    .where("role", "==", "driver").where("online", "==", true).limit(50).get();
  await Promise.all(drivers.docs
    .filter((d) => d.id !== t.riderId)
    .map((d) => notifyUser(d.id, "New request nearby",
      `${t.pickup?.name ?? "Pickup"} → ${t.dropoff?.name ?? "Drop-off"} · ${sdg(t.offeredFare ?? 0)}`,
      { route: "driverRequests", tripId: event.params.tripId, kind: "trip" })));
});

/** Driver bid → notify the rider. */
export const onBidCreated = onDocumentCreated("trips/{tripId}/bids/{driverId}", async (event) => {
  const bid = event.data?.data();
  if (!bid) return;
  const trip = (await db.collection("trips").doc(event.params.tripId).get()).data();
  if (!trip || trip.status !== "requested") return;
  await notifyUser(trip.riderId, "New offer",
    `${bid.driverName || "A driver"} offers ${sdg(bid.amount)} · ${bid.etaMin} min away`,
    { route: "offer", tripId: event.params.tripId, kind: "trip" });
});

/** Status changes → notifications; first rating → charge rider and pay driver. */
export const onTripUpdated = onDocumentUpdated("trips/{tripId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const tripId = event.params.tripId;
  const d = { tripId, kind: "trip" };

  if (before.status !== after.status) {
    switch (after.status) {
      case "accepted":
        await notifyUser(after.driverId, "Offer accepted",
          `${after.riderName || "Your rider"} accepted ${sdg(after.finalFare ?? after.offeredFare)} — head to ${after.pickup?.name}.`,
          { ...d, route: "driverDelivery" });
        await notifyUser(after.riderId, "Driver confirmed",
          `${after.driverName} · ${after.driverVehicle ?? ""} ${after.driverPlate ?? ""}`.trim(), { ...d, route: "tracking" });
        break;
      case "arriving":
        await notifyUser(after.riderId, "Driver on the way", `${after.driverName} is heading to ${after.pickup?.name}.`, { ...d, route: "tracking" });
        break;
      case "inProgress":
        await notifyUser(after.riderId, "Trip started", `Enjoy the ride to ${after.dropoff?.name}.`, { ...d, route: "tracking" });
        break;
      case "completed":
        await notifyUser(after.riderId, "You've arrived", `Rate your trip with ${after.driverName}.`, { ...d, route: "complete" });
        break;
      case "cancelled":
        await notifyUser(after.driverId, "Trip cancelled", "The rider cancelled this trip.", { ...d, route: "driverHome" });
        break;
    }
  }

  // Fare is settled once when the trip completes; a tip added at rating time is settled separately.
  if (after.status === "completed" && !after.charged) await settleTrip(tripId);
  if (after.status === "completed" && Number(after.tip ?? 0) > 0 && !after.tipCharged) await settleTip(tripId);
});

/** Moves money for a completed trip exactly once (guarded by `charged`). */
async function settleTrip(tripId: string) {
  await db.runTransaction(async (tx) => {
    const ref = db.collection("trips").doc(tripId);
    const t = (await tx.get(ref)).data();
    if (!t || t.charged || t.status !== "completed") return;
    const fare = Number(t.finalFare ?? t.offeredFare ?? 0);
    const tip = 0; // tips go through settleTip
    const label = `${String(t.service ?? "ride").replace(/^./, (c: string) => c.toUpperCase())} · ${t.dropoff?.name ?? ""}`;

    if (t.payment === "wallet") {
      const riderRef = db.collection("users").doc(t.riderId);
      tx.update(riderRef, { balance: FieldValue.increment(-(fare + tip)), trips: FieldValue.increment(1) });
      txn(tx, t.riderId, label, -(fare + tip), "ride");
    } else {
      tx.update(db.collection("users").doc(t.riderId), { trips: FieldValue.increment(1) });
    }
    if (t.driverId) {
      // Cash trips: driver collected the fare, so only the commission is owed.
      const commission = Math.round(fare * COMMISSION);
      const credit = t.payment === "wallet" ? fare + tip - commission : -commission;
      tx.update(db.collection("users").doc(t.driverId), { balance: FieldValue.increment(credit) });
      txn(tx, t.driverId, `Trip · ${t.riderName || "rider"}`, credit, "ride");
    }
    tx.update(ref, { charged: true });
  });
}

/** Charges the rider's tip (wallet trips) and passes 100% of it to the driver, once. */
async function settleTip(tripId: string) {
  await db.runTransaction(async (tx) => {
    const ref = db.collection("trips").doc(tripId);
    const t = (await tx.get(ref)).data();
    const tip = Number(t?.tip ?? 0);
    if (!t || t.tipCharged || tip <= 0 || !t.charged) return;
    if (t.payment === "wallet") {
      tx.update(db.collection("users").doc(t.riderId), { balance: FieldValue.increment(-tip) });
      txn(tx, t.riderId, `Tip · ${t.driverName ?? "driver"}`, -tip, "tip");
      if (t.driverId) {
        tx.update(db.collection("users").doc(t.driverId), { balance: FieldValue.increment(tip) });
        txn(tx, t.driverId, `Tip · ${t.riderName || "rider"}`, tip, "tip");
      }
    }
    tx.update(ref, { tipCharged: true });
  });
}

// ── Chat ────────────────────────────────────────────────────

export const onMessageCreated = onDocumentCreated("trips/{tripId}/messages/{msgId}", async (event) => {
  const m = event.data?.data();
  if (!m) return;
  const t = (await db.collection("trips").doc(event.params.tripId).get()).data();
  if (!t) return;
  const toRider = m.senderId !== t.riderId;
  await notifyUser(toRider ? t.riderId : t.driverId,
    toRider ? (t.driverName || "Driver") : (t.riderName || "Rider"),
    String(m.text).slice(0, 140), { route: "chat", tripId: event.params.tripId, kind: "trip" });
});

// ── Food & store orders ─────────────────────────────────────

/** New order → charge the customer's wallet (or decline) and notify the store. */
export const onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const orderId = event.params.orderId;
  const ok = await db.runTransaction(async (tx) => {
    const ref = db.collection("orders").doc(orderId);
    const o = (await tx.get(ref)).data();
    if (!o || o.paid) return false;
    const userRef = db.collection("users").doc(o.customerId);
    const balance = Number((await tx.get(userRef)).get("balance") ?? 0);
    if (balance < o.total) {
      tx.update(ref, { status: "declined", declineReason: "insufficient_balance" });
      return false;
    }
    tx.update(userRef, { balance: FieldValue.increment(-o.total) });
    txn(tx, o.customerId, "Food order", -o.total, "food");
    tx.update(ref, { paid: true });
    return true;
  });
  const o = event.data?.data();
  if (!o) return;
  if (!ok) {
    await notifyUser(o.customerId, "Order not placed", "Your wallet balance is too low — top up and try again.", { route: "topup", kind: "wallet" });
    return;
  }
  const staff = await db.collection("users").where("role", "==", "store").where("storeName", "==", o.storeId).get();
  await Promise.all(staff.docs.map((s) => notifyUser(s.id, "New order",
    `${o.customerName || "Customer"} · ${sdg(o.total)}`, { route: "store", kind: "trip" })));
});

export const onOrderUpdated = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  const text: Record<string, string> = {
    preparing: "The kitchen is preparing your order.",
    courier: "A courier picked up your order.",
    delivered: "Your order was delivered. Enjoy!",
    declined: "The store couldn't take your order. You have been refunded.",
  };
  if (after.status === "declined" && after.paid && !after.refunded) {
    await db.runTransaction(async (tx) => {
      tx.update(db.collection("users").doc(after.customerId), { balance: FieldValue.increment(after.total) });
      txn(tx, after.customerId, "Refund · food order", after.total, "refund");
      tx.update(db.collection("orders").doc(event.params.orderId), { refunded: true });
    });
  }
  if (text[after.status]) await notifyUser(after.customerId, "Order update", text[after.status], { route: "food", kind: "trip" });
});

// ── Wallet top-ups ──────────────────────────────────────────

/** Credits a top-up exactly once. */
async function creditTopup(topupId: string, providerRef: string) {
  await db.runTransaction(async (tx) => {
    const ref = db.collection("topups").doc(topupId);
    const t = (await tx.get(ref)).data();
    if (!t || t.status === "paid") return;
    tx.update(db.collection("users").doc(t.uid), { balance: FieldValue.increment(t.amount) });
    txn(tx, t.uid, `Top-up · ${t.method}`, t.amount, "topup");
    tx.update(ref, { status: "paid", providerRef, paidAt: Date.now() });
  });
}

/**
 * The app creates `topups/{id}` with status "pending". In production you'd now
 * create a payment session with your provider (Bankak / mBOK / card acquirer)
 * and store its checkout URL on the doc; the provider then calls paymentWebhook.
 * With ALLOW_FAKE_TOPUPS=true (testing) the amount is credited immediately.
 */
export const onTopupCreated = onDocumentCreated("topups/{topupId}", async (event) => {
  const t = event.data?.data();
  if (!t || t.status !== "pending") return;
  if (!Number.isFinite(t.amount) || t.amount <= 0 || t.amount > 1_000_000) {
    await event.data!.ref.update({ status: "rejected" });
    return;
  }
  if (ALLOW_FAKE_TOPUPS) {
    await creditTopup(event.params.topupId, "test");
    await notifyUser(t.uid, "Wallet topped up", `${sdg(t.amount)} added via ${t.method}.`, { route: "wallet", kind: "wallet" });
    return;
  }
  // TODO(payments): create the provider checkout here and save `checkoutUrl` on the doc.
  logger.info("Top-up awaiting payment provider", { topupId: event.params.topupId });
});

/**
 * Payment provider callback: POST {topupId, providerRef, status} with header
 * `x-signature: hex(HMAC-SHA256(rawBody, PAYMENT_WEBHOOK_SECRET))`.
 * Adapt the verification to your provider's real scheme.
 */
export const paymentWebhook = onRequest({ secrets: ["PAYMENT_WEBHOOK_SECRET"] }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).end();
    return;
  }
  const secret = process.env.PAYMENT_WEBHOOK_SECRET ?? "";
  const expected = crypto.createHmac("sha256", secret).update(req.rawBody).digest("hex");
  const given = String(req.header("x-signature") ?? "");
  const valid = secret.length > 0 && given.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(given), Buffer.from(expected));
  if (!valid) {
    res.status(401).send("bad signature");
    return;
  }
  const { topupId, providerRef, status } = req.body ?? {};
  if (typeof topupId !== "string" || status !== "paid") {
    res.status(400).send("ignored");
    return;
  }
  await creditTopup(topupId, String(providerRef ?? ""));
  const t = (await db.collection("topups").doc(topupId).get()).data();
  if (t) await notifyUser(t.uid, "Wallet topped up", `${sdg(t.amount)} added via ${t.method}.`, { route: "wallet", kind: "wallet" });
  res.status(200).send("ok");
});

// Exported for unit tests.
export type { Data };
