import { doc, getDoc } from "firebase/firestore";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { geohashForLocation } from "geofire-common";
import { admin, client, closeAll, DROPOFF, key, NEAR_PICKUP, PICKUP, seed, waitFor, type Client } from "./helpers";

let rider: Client, driver: Client, kyc: Client, kyc2: Client, finance: Client;
let tripId = "";
let rev = 0;


beforeAll(async () => {
  await seed();
  rider = await client("rider-1", { phone: "+249911111111" });
  driver = await client("driver-1", { phone: "+249922222222" });
  kyc = await client("staff-kyc", { claims: { staff: true, role: "kyc" } });
  kyc2 = await client("staff-kyc2", { claims: { staff: true, role: "kyc" } });
  finance = await client("staff-fin", { claims: { staff: true, role: "finance" } });
}, 60000);
afterAll(closeAll);

describe("full trip: onboarding → request → offer → accept → track → finish → cash → rate → settle", () => {
  it("driver onboards; submitting documents does not grant work", async () => {
    await driver.call("registerDriver", { idempotencyKey: key(), name: "Mostafa Ibrahim" });
    for (const type of ["national_id", "driving_license", "driver_photo"]) {
      await driver.call("submitDocument", { idempotencyKey: key(), type, storagePath: `drivers/driver-1/${type}.jpg` });
    }
    const { vehicleId } = await driver.call("addVehicle", { idempotencyKey: key(), category: "economy", make: "Toyota", model: "Corolla", color: "White", plate: "kh 4721", year: 2015 });
    for (const type of ["vehicle_registration", "insurance", "vehicle_photo"]) {
      await driver.call("submitDocument", { idempotencyKey: key(), type, vehicleId, storagePath: `drivers/driver-1/${vehicleId}/${type}.jpg` });
    }
    expect((await admin.doc("drivers/driver-1").get()).get("status")).toBe("underReview");
    expect(await driver.code("setActiveVehicle", { idempotencyKey: key(), vehicleId })).toBe("not_verified");
  });

  it("KYC: claim locks the item; decisions roll up to approval", async () => {
    const pending = await admin.collectionGroup("documents").where("status", "==", "pending").get();
    expect(pending.size).toBe(6);
    const first = pending.docs[0].ref.path;
    await kyc.call("claimReview", { idempotencyKey: key(), path: first });
    expect(await kyc2.code("claimReview", { idempotencyKey: key(), path: first })).toBe("already_claimed");
    expect(await kyc2.code("decideReview", { idempotencyKey: key(), path: first, decision: "approved" })).toBe("already_claimed");
    // A rejection needs a reason.
    expect(await kyc.code("decideReview", { idempotencyKey: key(), path: first, decision: "rejected" })).toBe("validation_failed");
    for (const d of pending.docs) {
      if (d.ref.path !== first) await kyc.call("claimReview", { idempotencyKey: key(), path: d.ref.path });
      await kyc.call("decideReview", { idempotencyKey: key(), path: d.ref.path, decision: "approved" });
    }
    expect((await admin.doc("drivers/driver-1").get()).get("status")).toBe("approved");
    const audit = await admin.collection("audit").where("actor", "==", "staff-kyc").get();
    expect(audit.size).toBeGreaterThanOrEqual(12);
  });

  it("driver chooses vehicle, reports GPS and goes online", async () => {
    const v = await admin.collection("vehicles").where("driverId", "==", "driver-1").get();
    expect(v.docs[0].get("status")).toBe("approved");
    await driver.call("setActiveVehicle", { idempotencyKey: key(), vehicleId: v.docs[0].id });
    expect(await driver.code("goOnline")).toBe("validation_failed"); // no location yet
    await admin.doc("presence/driver-1").set({ lat: NEAR_PICKUP.lat, lng: NEAR_PICKUP.lng, geohash: geohashForLocation([NEAR_PICKUP.lat, NEAR_PICKUP.lng]), updatedAt: Date.now() });
    const r = await driver.call("goOnline");
    expect(r.online).toBe(true);
  });

  it("rider gets a draft with reference price and bounds, proposes within bounds", async () => {
    await rider.call("registerRider", { idempotencyKey: key(), name: "Ahmed Hassan", lang: "ar" });
    const k = key();
    const d = await rider.call("createDraft", { idempotencyKey: k, pickup: PICKUP, dropoff: DROPOFF, category: "economy" });
    const replay = await rider.call("createDraft", { idempotencyKey: k, pickup: PICKUP, dropoff: DROPOFF, category: "economy" });
    expect(replay.tripId).toBe(d.tripId); // retried request does not create a second draft
    tripId = d.tripId;
    expect(d.quote.minFare).toBeLessThanOrEqual(d.quote.referenceFare);
    expect(await rider.code("confirmRequest", { idempotencyKey: key(), tripId, proposedFare: d.quote.maxFare + 1, expectedRevision: 1 })).toBe("out_of_bounds");
    const c = await rider.call("confirmRequest", { idempotencyKey: key(), tripId, proposedFare: d.quote.referenceFare, expectedRevision: 1 });
    expect(c.state).toBe("searching");
    rev = c.revision;
  });

  it("nearby online driver receives a sanitized request card and sends an offer", async () => {
    const card = await waitFor(async () => (await admin.doc(`inbox/driver-1/requests/${tripId}`).get()).data(), "inbox card");
    expect(card.riderId).toBeUndefined();
    expect(card.distanceToPickupKm).toBeLessThan(15);
    await driver.call("submitOffer", { idempotencyKey: key(), tripId, price: card.proposedFare, etaMinutes: 4 });
    const t = (await admin.doc(`trips/${tripId}`).get()).data()!;
    expect(t.state).toBe("offering");
    rev = t.revision;
  });

  it("accept: stale revision is rejected; a retry never double-accepts", async () => {
    expect(await rider.code("acceptOffer", { idempotencyKey: key(), tripId, offerId: "driver-1", expectedRevision: rev - 1 })).toBe("stale_revision");
    const k = key();
    const a = await rider.call("acceptOffer", { idempotencyKey: k, tripId, offerId: "driver-1", expectedRevision: rev });
    const again = await rider.call("acceptOffer", { idempotencyKey: k, tripId, offerId: "driver-1", expectedRevision: rev });
    expect(again).toEqual(a);
    expect(await rider.code("acceptOffer", { idempotencyKey: k, tripId, offerId: "someone-else", expectedRevision: rev })).toBe("idempotency_mismatch");
    expect(a.state).toBe("driverAssigned");
    rev = a.revision;
    const t = (await admin.doc(`trips/${tripId}`).get()).data()!;
    expect(t.driver.phone).toBe("+249922222222");
    expect(t.vehicle.plate).toBe("KH 4721");
    await waitFor(async () => !(await admin.doc(`inbox/driver-1/requests/${tripId}`).get()).exists, "inbox cleanup");
  });

  it("rider can read the assigned driver's live location; driver drives the stages", async () => {
    const p = await getDoc(doc(rider.db, "presence", "driver-1"));
    expect(p.exists()).toBe(true);
    for (const cmd of ["ackAssignment", "markArrived", "startTrip"]) {
      const r = await driver.call(cmd, { idempotencyKey: key(), tripId, expectedRevision: rev });
      rev = r.revision;
    }
    expect(await rider.code("cancelTrip", { idempotencyKey: key(), tripId, reason: "change_of_plans", expectedRevision: rev })).toBe("invalid_transition");
    const f = await driver.call("finishTrip", { idempotencyKey: key(), tripId, expectedRevision: rev });
    expect(f.state).toBe("paymentPending");
    rev = f.revision;
  });

  it("cash is recorded once; commission becomes driver debt in the ledger", async () => {
    const t = (await admin.doc(`trips/${tripId}`).get()).data()!;
    const k = key();
    const r = await driver.call("recordCash", { idempotencyKey: k, tripId, amount: t.fare, expectedRevision: rev });
    await driver.call("recordCash", { idempotencyKey: k, tripId, amount: t.fare, expectedRevision: rev }); // network retry
    expect(r.state).toBe("completed");
    const ledger = await admin.collection("ledger").where("tripId", "==", tripId).get();
    expect(ledger.size).toBe(2);
    const commission = ledger.docs.find((d) => d.get("kind") === "commission_due")!.get("amountMinor");
    expect(commission).toBe(Math.floor((t.fare * 1500 + 5000) / 10000) * 100);
    expect(ledger.docs.every((d) => Number.isInteger(d.get("amountMinor")))).toBe(true);
    expect((await admin.doc("drivers/driver-1").get()).get("activeTripId")).toBeNull();
  });

  it("both sides rate once", async () => {
    await rider.call("rateTrip", { idempotencyKey: key(), tripId, stars: 5, comment: "ممتاز" });
    expect(await rider.code("rateTrip", { idempotencyKey: key(), tripId, stars: 1 })).toBe("invalid_transition");
    await driver.call("rateTrip", { idempotencyKey: key(), tripId, stars: 4 });
    expect((await admin.doc("drivers/driver-1").get()).get("ratingCount")).toBe(1);
  });

  it("finance sees what is owed and settles it; over-settling is refused", async () => {
    const m = await finance.call("driverMoney", { driverId: "driver-1" });
    expect(m.owedMinor).toBeGreaterThan(0);
    expect(m.owedMinor % 100).toBe(0);
    const owedUnits = m.owedMinor / 100;
    expect(await finance.code("recordSettlement", { idempotencyKey: key(), driverId: "driver-1", amount: owedUnits + 1, reference: "R-1" })).toBe("out_of_bounds");
    const s = await finance.call("recordSettlement", { idempotencyKey: key(), driverId: "driver-1", amount: owedUnits, reference: "R-1" });
    expect(s.owedMinor).toBe(0);
    const e = await driver.call("myEarnings");
    expect(e.owedMinor).toBe(0);
    expect(e.earnedMinor).toBe(e.collectedMinor - e.commissionMinor);
  });

  it("rider can dispute within the window", async () => {
    const t = (await admin.doc(`trips/${tripId}`).get()).data()!;
    const d = await rider.call("disputeTrip", { idempotencyKey: key(), tripId, reason: "Charged twice", expectedRevision: t.revision });
    expect(d.state).toBe("disputed");
    expect((await admin.doc(`cases/${d.caseId}`).get()).get("type")).toBe("dispute");
  });
});

describe("expiry", () => {
  it("a request with no accepted offer expires and the rider is told why", async () => {
    const r2 = await client("rider-2", { phone: "+249933333333" });
    await r2.call("registerRider", { idempotencyKey: key(), name: "Sara" });
    const d = await r2.call("createDraft", { idempotencyKey: key(), pickup: PICKUP, dropoff: DROPOFF, category: "comfort" });
    await r2.call("confirmRequest", { idempotencyKey: key(), tripId: d.tripId, proposedFare: d.quote.referenceFare, expectedRevision: 1 });
    await admin.doc(`trips/${d.tripId}`).update({ expiresAt: Date.now() - 1000 });
    const { sweep } = await import("../../src/triggers");
    await sweep();
    const t = (await admin.doc(`trips/${d.tripId}`).get()).data()!;
    expect(t.state).toBe("cancelled");
    expect(t.cancellation).toMatchObject({ actor: "system", reason: "no_offers" });
  });
});
