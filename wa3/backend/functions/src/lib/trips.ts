import type { DocumentReference, Transaction } from "firebase-admin/firestore";
import type { Actor, Category, TripState } from "../domain/contract";
import { fail } from "../domain/errors";
import { assertRevision } from "../domain/idempotency";
import type { PricingConfig, Quote } from "../domain/pricing";
import { nextState, type Transition } from "../domain/tripMachine";
import type { Ctx } from "./command";
import { C, db } from "./firestore";
import type { PlacePoint } from "./geo";
import type { Route } from "./maps";

export interface TripDoc {
  riderId: string;
  riderName: string;
  riderPhone: string;
  state: TripState;
  revision: number;
  category: Category;
  zoneId: string;
  pickup: PlacePoint;
  dropoff: PlacePoint;
  route: Route;
  quote: Quote;
  commissionBps: number;
  currency: string;
  proposedFare: number | null;
  fare: number | null;
  driverId: string | null;
  driver: { name: string; phone: string; ratingAvg: number | null } | null;
  vehicle: { category: Category; make: string; model: string; color: string; plate: string } | null;
  acceptedOfferId: string | null;
  expiresAt: number | null;
  offerCount: number;
  cash: { amount: number; recordedAt: number; mismatch: boolean } | null;
  cancellation: { actor: Actor; reason: string; note: string | null; at: number } | null;
  riderRating: { stars: number; comment: string | null; at: number } | null;   // rider → driver
  driverRating: { stars: number; comment: string | null; at: number } | null;  // driver → rider
  dispute: { caseId: string; by: Actor; at: number } | null;
  timestamps: Partial<Record<TripState, number>>;
  flags: { stuck: boolean; locationStale: boolean };
  createdAt: number;
  updatedAt: number;
}

export const tripRef = (id: string) => db.collection(C.trips).doc(id) as DocumentReference<TripDoc>;

export async function loadTrip(tx: Transaction, id: unknown): Promise<{ ref: DocumentReference<TripDoc>; trip: TripDoc }> {
  if (typeof id !== "string" || !id) return fail("validation_failed", "tripId is required");
  const ref = tripRef(id);
  const snap = await tx.get(ref);
  if (!snap.exists) return fail("not_found", "Trip not found");
  return { ref, trip: snap.data()! };
}

/** Who is acting on this trip, and are they allowed to see it at all? */
export function actorFor(ctx: Ctx, trip: TripDoc): Actor {
  if (ctx.audience === "staff") return "ops";
  if ((ctx.audience === "rider" || ctx.audience === "any") && trip.riderId === ctx.uid) return "rider";
  if ((ctx.audience === "driver" || ctx.audience === "any") && trip.driverId === ctx.uid) return "driver";
  return fail("permission_denied", "This trip is not yours");
}

/**
 * Validates a transition against the state machine and the expected revision,
 * then writes the new state, bumps the revision and stamps the time.
 * Returns the new state and revision for the client to reconcile.
 */
export function transition(
  tx: Transaction,
  ref: DocumentReference<TripDoc>,
  trip: TripDoc,
  t: Transition,
  actor: Actor,
  ctx: Ctx,
  opts: { expectedRevision?: unknown; patch?: Record<string, unknown>; cancelReason?: string } = {},
) {
  if (opts.expectedRevision !== undefined || actor === "rider" || actor === "driver" || actor === "ops") {
    assertRevision(trip.revision, opts.expectedRevision);
  }
  const to = nextState({
    state: trip.state,
    transition: t,
    actor,
    cancelReason: opts.cancelReason,
    completedAt: trip.timestamps.completed,
    now: ctx.now,
  });
  const revision = trip.revision + 1;
  tx.update(ref, {
    ...opts.patch,
    state: to,
    revision,
    [`timestamps.${to}`]: ctx.now,
    updatedAt: ctx.now,
  });
  return { state: to, revision };
}

export async function zoneAndPricing(tx: Transaction, zoneId: string, category: Category): Promise<PricingConfig & { enabled: boolean }> {
  const snap = await tx.get(db.collection(C.pricing).doc(`${zoneId}__${category}`));
  const p = snap.data() as (PricingConfig & { enabled: boolean }) | undefined;
  if (!p || !p.enabled) return fail("validation_failed", "This vehicle category is not available in this area");
  return p;
}

export type RouteSnapshot = Route;
