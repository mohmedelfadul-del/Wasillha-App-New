import { addDoc, collection, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from "firebase/firestore";
import { geohashForLocation } from "geofire-common";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { admin, client, closeAll, type Client } from "./helpers";

let riderA: Client, riderB: Client, driverA: Client, driverB: Client;
const ok = async (p: Promise<unknown>) => { try { await p; return true; } catch { return false; } };

beforeAll(async () => {
  riderA = await client("rules-rider-a");
  riderB = await client("rules-rider-b");
  driverA = await client("rules-driver-a");
  driverB = await client("rules-driver-b");
  await admin.doc("trips/rules-trip").set({ riderId: "rules-rider-a", driverId: "rules-driver-a", state: "driverEnRoute", revision: 5 });
  await admin.doc("trips/rules-trip/offers/rules-driver-a").set({ driverId: "rules-driver-a", price: 100 });
  await admin.doc("drivers/rules-driver-a").set({ activeRiderId: "rules-rider-a", status: "approved" });
  await admin.doc("drivers/rules-driver-b").set({ activeRiderId: null, status: "approved" });
  await admin.doc("presence/rules-driver-a").set({ lat: 15.5, lng: 32.5, geohash: "s", updatedAt: Date.now() });
  await admin.doc("presence/rules-driver-b").set({ lat: 15.5, lng: 32.5, geohash: "s", updatedAt: Date.now() });
  await admin.collection("ledger").add({ driverId: "rules-driver-a", kind: "commission_due", amountMinor: 100 });
}, 60000);
afterAll(closeAll);

describe("trip privacy", () => {
  it("a rider can read their own trip but not another rider's", async () => {
    expect(await ok(getDoc(doc(riderA.db, "trips/rules-trip")))).toBe(true);
    expect(await ok(getDoc(doc(riderB.db, "trips/rules-trip")))).toBe(false);
  });
  it("only the assigned driver reads the trip", async () => {
    expect(await ok(getDoc(doc(driverA.db, "trips/rules-trip")))).toBe(true);
    expect(await ok(getDoc(doc(driverB.db, "trips/rules-trip")))).toBe(false);
  });
  it("nobody writes trips directly — not even the owner", async () => {
    expect(await ok(updateDoc(doc(riderA.db, "trips/rules-trip"), { state: "completed" }))).toBe(false);
    expect(await ok(updateDoc(doc(driverA.db, "trips/rules-trip"), { state: "completed" }))).toBe(false);
    expect(await ok(addDoc(collection(riderA.db, "trips"), { riderId: "rules-rider-a", state: "searching" }))).toBe(false);
  });
  it("a driver cannot act on a trip that isn't assigned to them", async () => {
    expect(await driverB.code("markArrived", { idempotencyKey: "rules-key-0000000001", tripId: "rules-trip", expectedRevision: 5 })).toBe("permission_denied");
    expect(await riderB.code("cancelTrip", { idempotencyKey: "rules-key-0000000002", tripId: "rules-trip", reason: "other", expectedRevision: 5 })).toBe("permission_denied");
  });
  it("offers: the rider of the trip and the offering driver only", async () => {
    expect(await ok(getDoc(doc(riderA.db, "trips/rules-trip/offers/rules-driver-a")))).toBe(true);
    expect(await ok(getDoc(doc(riderB.db, "trips/rules-trip/offers/rules-driver-a")))).toBe(false);
    expect(await ok(getDoc(doc(driverB.db, "trips/rules-trip/offers/rules-driver-a")))).toBe(false);
  });
});

describe("driver location", () => {
  it("the assigned rider sees the driver's location; other riders don't", async () => {
    expect(await ok(getDoc(doc(riderA.db, "presence/rules-driver-a")))).toBe(true);
    expect(await ok(getDoc(doc(riderB.db, "presence/rules-driver-a")))).toBe(false);
    expect(await ok(getDoc(doc(riderA.db, "presence/rules-driver-b")))).toBe(false);
  });
  it("a driver can't write someone else's location or forge the time", async () => {
    const p = { lat: 15.6, lng: 32.6, geohash: geohashForLocation([15.6, 32.6]) };
    expect(await ok(setDoc(doc(driverB.db, "presence/rules-driver-a"), { ...p, updatedAt: Date.now() }))).toBe(false);
    expect(await ok(setDoc(doc(driverB.db, "presence/rules-driver-b"), { ...p, updatedAt: 1 }))).toBe(false);
    expect(await ok(setDoc(doc(driverB.db, "presence/rules-driver-b"), { ...p, updatedAt: Date.now(), online: true }))).toBe(false);
  });
});

describe("money and inbox", () => {
  it("drivers read only their own ledger", async () => {
    expect(await ok(getDocs(query(collection(driverA.db, "ledger"), where("driverId", "==", "rules-driver-a"))))).toBe(true);
    expect(await ok(getDocs(query(collection(driverB.db, "ledger"), where("driverId", "==", "rules-driver-a"))))).toBe(false);
    expect(await ok(addDoc(collection(driverA.db, "ledger"), { driverId: "rules-driver-a", kind: "settlement", amountMinor: 100 }))).toBe(false);
  });
  it("inbox is private to its driver", async () => {
    await admin.doc("inbox/rules-driver-a/requests/x").set({ tripId: "x" });
    expect(await ok(getDocs(collection(driverA.db, "inbox/rules-driver-a/requests")))).toBe(true);
    expect(await ok(getDocs(collection(driverB.db, "inbox/rules-driver-a/requests")))).toBe(false);
  });
  it("riders can't use staff commands", async () => {
    expect(await riderA.code("recordSettlement", { idempotencyKey: "rules-key-0000000003", driverId: "x", amount: 1, reference: "r" })).toBe("permission_denied");
  });
});
