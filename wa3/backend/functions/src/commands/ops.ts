import { CANCEL_REASONS, CATEGORIES, type Category } from "../domain/contract";
import { fail } from "../domain/errors";
import { assertSettlementAllowed, entry, summarize, type LedgerEntry } from "../domain/ledger";
import { toMinor, validatePricingConfig, type PricingConfig } from "../domain/pricing";
import { audit, command, int, optStr, str } from "../lib/command";
import { C, db } from "../lib/firestore";
import { loadTrip, transition } from "../lib/trips";
import { DRIVER_DOCS, VEHICLE_DOCS } from "./driver";

const CLAIM_TTL_MS = 15 * 60_000;
const REVIEW_PATH = /^(drivers|vehicles)\/[A-Za-z0-9_-]+\/documents\/[a-z_]+$/;

function reviewRef(path: unknown) {
  if (typeof path !== "string" || !REVIEW_PATH.test(path)) return fail("validation_failed", "Invalid review item");
  return db.doc(path);
}

/** Claim a KYC item. Locks it to one reviewer so decisions can't conflict. */
export const claimReview = command("claimReview", { audience: "staff", roles: ["kyc"], mutating: true }, async (ctx, data, tx) => {
  const ref = reviewRef(data.path);
  const snap = await tx!.get(ref);
  if (!snap.exists) fail("not_found", "Document not found");
  if (snap.get("status") !== "pending") fail("invalid_transition", "This document was already decided");
  const holder = snap.get("claimedBy") as string | null;
  if (holder && holder !== ctx.uid && ctx.now - (snap.get("claimedAt") as number) < CLAIM_TTL_MS) {
    fail("already_claimed", "Another reviewer is working on this item", { claimedBy: holder });
  }
  tx!.update(ref, { claimedBy: ctx.uid, claimedAt: ctx.now });
  audit(tx!, ctx, "review.claim", ref.path);
  return { claimedBy: ctx.uid, expiresAt: ctx.now + CLAIM_TTL_MS };
});

/** Approve / reject / request changes. Requires holding the claim. Rolls up driver & vehicle status. */
export const decideReview = command("decideReview", { audience: "staff", roles: ["kyc"], mutating: true }, async (ctx, data, tx) => {
  const ref = reviewRef(data.path);
  const decision = data.decision as string;
  if (!["approved", "rejected", "changesRequested"].includes(decision)) fail("validation_failed", "Unknown decision");
  const reason = decision === "approved" ? optStr(data.reason, 500) : str(data.reason, "Reason", 500);
  const snap = await tx!.get(ref);
  if (!snap.exists) fail("not_found", "Document not found");
  if (snap.get("status") !== "pending") fail("invalid_transition", "This document was already decided");
  if (snap.get("claimedBy") !== ctx.uid) fail("already_claimed", "Claim this item before deciding");

  const owner = ref.parent.parent!; // drivers/{uid} or vehicles/{vid}
  const siblings = await tx!.get(owner.collection(C.documents));
  const required = owner.parent.id === C.drivers ? DRIVER_DOCS : VEHICLE_DOCS;
  const statuses = new Map(siblings.docs.map((d) => [d.id, d.get("status") as string]));
  statuses.set(ref.id, decision);
  const allApproved = required.every((t) => statuses.get(t) === "approved");

  tx!.update(ref, { status: decision, reason, decidedBy: ctx.uid, decidedAt: ctx.now, claimedBy: null, claimedAt: null });
  if (owner.parent.id === C.drivers) {
    tx!.update(owner, { status: allApproved ? "approved" : "underReview", updatedAt: ctx.now });
  } else {
    tx!.update(owner, { status: allApproved ? "approved" : decision === "approved" ? "pending" : "changesRequested", updatedAt: ctx.now });
  }
  audit(tx!, ctx, `review.${decision}`, ref.path, { reason });
  return { status: decision, ownerApproved: allApproved };
});

export const opsCancelTrip = command("opsCancelTrip", { audience: "staff", roles: ["operations", "support"], mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const reason = str(data.reason, "Reason", 40);
  if (!(CANCEL_REASONS.ops as readonly string[]).includes(reason)) fail("validation_failed", "Unknown reason");
  const note = str(data.note, "Note", 500);
  const offers = await tx!.get(ref.collection(C.offers).where("status", "==", "active"));
  const res = transition(tx!, ref, trip, "cancel", "ops", ctx, {
    expectedRevision: data.expectedRevision, cancelReason: reason,
    patch: { cancellation: { actor: "ops", reason, note, at: ctx.now }, expiresAt: null },
  });
  for (const o of offers.docs) tx!.update(o.ref, { status: "expired", decidedAt: ctx.now });
  if (trip.driverId) tx!.update(db.collection(C.drivers).doc(trip.driverId), { activeTripId: null, activeRiderId: null });
  audit(tx!, ctx, "trip.cancel", ref.path, { reason, note });
  return res;
});

export const resolveDispute = command("resolveDispute", { audience: "staff", roles: ["support"], mutating: true }, async (ctx, data, tx) => {
  const { ref, trip } = await loadTrip(tx!, data.tripId);
  const resolution = str(data.resolution, "Resolution", 1000);
  const caseRef = trip.dispute ? db.collection(C.cases).doc(trip.dispute.caseId) : null;
  const res = transition(tx!, ref, trip, "resolveDispute", "ops", ctx, { expectedRevision: data.expectedRevision, patch: { "dispute.resolution": resolution } });
  if (caseRef) tx!.update(caseRef, { status: "resolved", resolution, resolvedBy: ctx.uid, updatedAt: ctx.now });
  audit(tx!, ctx, "dispute.resolve", ref.path, { resolution });
  return res;
});

export const claimCase = command("claimCase", { audience: "staff", roles: ["support", "operations"], mutating: true }, async (ctx, data, tx) => {
  const ref = db.collection(C.cases).doc(str(data.caseId, "caseId", 128));
  const snap = await tx!.get(ref);
  if (!snap.exists) fail("not_found", "Case not found");
  if (snap.get("ownerId") && snap.get("ownerId") !== ctx.uid) fail("already_claimed", "Another agent owns this case");
  tx!.update(ref, { ownerId: ctx.uid, status: snap.get("status") === "open" ? "inProgress" : snap.get("status"), updatedAt: ctx.now });
  audit(tx!, ctx, "case.claim", ref.path);
  return { ownerId: ctx.uid };
});

export const closeCase = command("closeCase", { audience: "staff", roles: ["support", "operations"], mutating: true }, async (ctx, data, tx) => {
  const ref = db.collection(C.cases).doc(str(data.caseId, "caseId", 128));
  const snap = await tx!.get(ref);
  if (!snap.exists) fail("not_found", "Case not found");
  if (snap.get("ownerId") !== ctx.uid) fail("already_claimed", "Claim the case before closing it");
  const resolution = str(data.resolution, "Resolution", 1000);
  tx!.update(ref, { status: "resolved", resolution, resolvedBy: ctx.uid, updatedAt: ctx.now });
  audit(tx!, ctx, "case.close", ref.path, { resolution });
  return { status: "resolved" };
});

export const updatePricing = command("updatePricing", { audience: "staff", roles: [], mutating: true }, async (ctx, data, tx) => {
  const zoneId = str(data.zoneId, "Zone", 64);
  const category = data.category as Category;
  if (!CATEGORIES.includes(category)) fail("validation_failed", "Unknown category");
  const c = validatePricingConfig(data.config as PricingConfig);
  const ref = db.collection(C.pricing).doc(`${zoneId}__${category}`);
  const before = (await tx!.get(ref)).data() ?? null;
  const reason = str(data.reason, "Reason for the change", 300);
  const next = {
    zoneId, category, enabled: data.enabled !== false,
    baseFare: c.baseFare, perKm: c.perKm, perMinute: c.perMinute, minFare: c.minFare, maxFare: c.maxFare,
    belowReferencePct: c.belowReferencePct, aboveReferencePct: c.aboveReferencePct, commissionBps: c.commissionBps,
    version: ((before?.version as number) ?? 0) + 1, updatedBy: ctx.uid, updatedAt: ctx.now,
  };
  tx!.set(ref, next);
  audit(tx!, ctx, "pricing.update", ref.path, { before, after: next, reason });
  return { version: next.version };
});

async function ledgerFor(driverId: string): Promise<LedgerEntry[]> {
  const q = await db.collection(C.ledger).where("driverId", "==", driverId).get();
  return q.docs.map((d) => d.data() as LedgerEntry);
}

/** Records cash a driver handed to the company. Append-only; cannot exceed what is owed. */
export const recordSettlement = command("recordSettlement", { audience: "staff", roles: ["finance"], mutating: true }, async (ctx, data, tx) => {
  const driverId = str(data.driverId, "Driver", 128);
  const amountMinor = toMinor(int(data.amount, "Amount", 1));
  const reference = str(data.reference, "Receipt reference", 120);
  // Read the ledger inside the transaction so two settlements can't both pass the check.
  const q = await tx!.get(db.collection(C.ledger).where("driverId", "==", driverId));
  const money = summarize(q.docs.map((d) => d.data() as LedgerEntry));
  assertSettlementAllowed(money, amountMinor);
  tx!.set(db.collection(C.ledger).doc(), entry({ driverId, kind: "settlement", amountMinor, reason: reference, createdBy: ctx.uid, createdAt: ctx.now }));
  audit(tx!, ctx, "ledger.settlement", `drivers/${driverId}`, { amountMinor, reference });
  return { owedMinor: money.owedMinor - amountMinor };
});

export const recordAdjustment = command("recordAdjustment", { audience: "staff", roles: [], mutating: true }, async (ctx, data, tx) => {
  const driverId = str(data.driverId, "Driver", 128);
  const amountMinor = toMinor(int(data.amount, "Amount", 1));
  const sign = data.sign === -1 ? -1 : 1;
  const reason = str(data.reason, "Reason", 300);
  tx!.set(db.collection(C.ledger).doc(), entry({ driverId, kind: "adjustment", amountMinor, sign, reason, createdBy: ctx.uid, createdAt: ctx.now }));
  audit(tx!, ctx, "ledger.adjustment", `drivers/${driverId}`, { amountMinor, sign, reason });
  return { ok: true };
});

/** Read model for the settlement screen: derived balances per driver. */
export const driverMoney = command("driverMoney", { audience: "staff", roles: ["finance", "operations"], mutating: false }, async (_ctx, data) => {
  const driverId = str(data.driverId, "Driver", 128);
  return summarize(await ledgerFor(driverId));
});

/** Driver's own earnings (derived from the ledger, never a stored balance). */
export const myEarnings = command("myEarnings", { audience: "driver", mutating: false }, async (ctx) => {
  const entries = await ledgerFor(ctx.uid);
  return { ...summarize(entries), entries: entries.sort((a, b) => b.createdAt - a.createdAt).slice(0, 100) };
});
