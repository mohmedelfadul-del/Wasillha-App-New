import { createHash } from "crypto";
import { fail } from "./errors";

/**
 * Every mutating command carries `idempotencyKey` and (for trip commands)
 * `expectedRevision`. The stored record makes a retried request return the
 * original result instead of acting twice.
 */
export interface IdempotencyRecord {
  fingerprint: string;
  result: unknown;
  command: string;
  uid: string;
  createdAt: number;
}

const KEY_RE = /^[A-Za-z0-9_-]{16,80}$/;

export function assertKey(key: unknown): string {
  if (typeof key !== "string" || !KEY_RE.test(key)) {
    fail("validation_failed", "idempotencyKey must be 16–80 URL-safe characters");
  }
  return key as string;
}

/** Stable hash of the command payload (key order independent, key itself excluded). */
export function fingerprint(command: string, payload: Record<string, unknown>): string {
  const { idempotencyKey: _ignored, ...rest } = payload;
  return createHash("sha256").update(command + ":" + stableStringify(rest)).digest("hex");
}

/**
 * Decide what to do with an existing record:
 *  - none → run the command
 *  - same fingerprint → replay the stored result
 *  - different fingerprint → the key was reused for another request: reject
 */
export function replayDecision(existing: IdempotencyRecord | undefined, fp: string): { replay: false } | { replay: true; result: unknown } {
  if (!existing) return { replay: false };
  if (existing.fingerprint !== fp) {
    return fail("idempotency_mismatch", "This idempotency key was already used for a different request");
  }
  return { replay: true, result: existing.result };
}

export function assertRevision(current: number, expected: unknown) {
  if (typeof expected !== "number" || !Number.isInteger(expected)) {
    fail("validation_failed", "expectedRevision is required");
  }
  if (current !== expected) {
    fail("stale_revision", "The trip changed since you last saw it. Refresh and try again.", { currentRevision: current });
  }
}

function stableStringify(v: unknown): string {
  if (v === null || typeof v !== "object") return JSON.stringify(v);
  if (Array.isArray(v)) return "[" + v.map(stableStringify).join(",") + "]";
  const o = v as Record<string, unknown>;
  return "{" + Object.keys(o).sort().map((k) => JSON.stringify(k) + ":" + stableStringify(o[k])).join(",") + "}";
}
