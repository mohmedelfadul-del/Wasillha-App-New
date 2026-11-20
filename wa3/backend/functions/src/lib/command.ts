import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import type { Transaction } from "firebase-admin/firestore";
import type { StaffRole } from "../domain/contract";
import { DomainError, fail } from "../domain/errors";
import { assertKey, fingerprint, replayDecision, type IdempotencyRecord } from "../domain/idempotency";
import { C, db, now } from "./firestore";

export type Audience = "rider" | "driver" | "staff" | "any";

export interface Ctx {
  uid: string;
  audience: Audience;
  role?: StaffRole;
  now: number;
}

interface Options {
  audience: Audience;
  /** Staff roles allowed (admin is always allowed). */
  roles?: readonly StaffRole[];
  /** Run inside a Firestore transaction with idempotency (all mutating commands). */
  mutating?: boolean;
  /** Needs the Google Maps server key (bound from Secret Manager). */
  maps?: boolean;
}

const REQUIRE_STAFF_MFA = process.env.REQUIRE_STAFF_MFA !== "false";
const ENFORCE_APP_CHECK = process.env.APP_CHECK_ENFORCE !== "false";

const HTTPS_CODE: Record<string, ConstructorParameters<typeof HttpsError>[0]> = {
  invalid_transition: "failed-precondition",
  stale_revision: "aborted",
  not_found: "not-found",
  permission_denied: "permission-denied",
  out_of_bounds: "out-of-range",
  offer_expired: "failed-precondition",
  driver_busy: "failed-precondition",
  not_verified: "permission-denied",
  outside_zone: "failed-precondition",
  idempotency_mismatch: "already-exists",
  dispute_window_closed: "failed-precondition",
  validation_failed: "invalid-argument",
  maps_unavailable: "unavailable",
  mfa_required: "unauthenticated",
  already_claimed: "failed-precondition",
};

function authorize(req: CallableRequest, opts: Options): Ctx {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first", { code: "permission_denied" });
  const token = auth.token as Record<string, unknown> & { firebase?: { sign_in_second_factor?: string } };
  const ctx: Ctx = { uid: auth.uid, audience: opts.audience, now: now() };
  if (opts.audience === "staff") {
    const role = token.role as StaffRole | undefined;
    if (token.staff !== true || !role) fail("permission_denied", "Staff only");
    if (REQUIRE_STAFF_MFA && token.firebase?.sign_in_second_factor !== "totp") {
      fail("mfa_required", "Sign in with your authenticator code");
    }
    if (opts.roles && role !== "admin" && !opts.roles.includes(role!)) {
      fail("permission_denied", `Requires role: ${opts.roles.join(" or ")}`);
    }
    ctx.role = role;
  } else if (token.staff === true && opts.audience !== "any") {
    // Staff accounts never act as riders or drivers.
    fail("permission_denied", "Staff accounts cannot use rider or driver commands");
  }
  return ctx;
}

/**
 * Wraps a command handler as a callable function.
 * Mutating commands run in one transaction that also stores the idempotency
 * record, so a retry either replays the first result or does nothing new.
 */
export function command<T>(
  name: string,
  opts: Options,
  handler: (ctx: Ctx, data: Record<string, unknown>, tx: Transaction | null) => Promise<T>,
) {
  const secrets = opts.maps && process.env.MAPS_FAKE !== "true" ? ["GOOGLE_MAPS_SERVER_KEY"] : [];
  return onCall({ enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1", secrets }, async (req) => {
    try {
      const ctx = authorize(req, opts);
      const data = (req.data ?? {}) as Record<string, unknown>;
      if (!opts.mutating) return await handler(ctx, data, null);

      const key = assertKey(data.idempotencyKey);
      const fp = fingerprint(name, data);
      const ref = db.collection(C.idempotency).doc(`${ctx.uid}_${key}`);
      return await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const decision = replayDecision(snap.exists ? (snap.data() as IdempotencyRecord) : undefined, fp);
        if (decision.replay) return decision.result as T;
        const result = await handler(ctx, data, tx);
        const rec: IdempotencyRecord = { fingerprint: fp, result: result ?? null, command: name, uid: ctx.uid, createdAt: ctx.now };
        tx.set(ref, rec);
        return result;
      });
    } catch (e) {
      if (e instanceof DomainError) {
        throw new HttpsError(HTTPS_CODE[e.code] ?? "failed-precondition", e.message, { code: e.code, ...e.details });
      }
      if (e instanceof HttpsError) throw e;
      logger.error(`command ${name} failed`, e);
      throw new HttpsError("internal", "Something went wrong on our side. Please try again.", { code: "internal" });
    }
  });
}

/** Writes an immutable audit entry inside the same transaction. */
export function audit(tx: Transaction, ctx: Ctx, action: string, target: string, data: Record<string, unknown> = {}) {
  tx.set(db.collection(C.audit).doc(), { actor: ctx.uid, role: ctx.role ?? ctx.audience, action, target, data, at: ctx.now });
}

export const str = (v: unknown, what: string, max = 500): string => {
  const s = typeof v === "string" ? v.trim() : "";
  if (!s) fail("validation_failed", `${what} is required`);
  return s.slice(0, max);
};

export const optStr = (v: unknown, max = 500): string | null => (typeof v === "string" && v.trim() ? v.trim().slice(0, max) : null);

export const int = (v: unknown, what: string, min = 0, max = Number.MAX_SAFE_INTEGER): number => {
  if (typeof v !== "number" || !Number.isInteger(v) || v < min || v > max) fail("validation_failed", `${what} must be a whole number between ${min} and ${max}`);
  return v as number;
};
