import { describe, expect, it } from "vitest";
import { assertKey, assertRevision, fingerprint, replayDecision } from "../../src/domain/idempotency";

const code = (f: () => unknown) => { try { f(); return "ok"; } catch (e: any) { return e.code; } };

describe("idempotency", () => {
  it("fingerprint ignores key order and the key itself", () => {
    const a = fingerprint("acceptOffer", { tripId: "t", offerId: "o", idempotencyKey: "k1k1k1k1k1k1k1k1" });
    const b = fingerprint("acceptOffer", { offerId: "o", tripId: "t", idempotencyKey: "other-key-000000" });
    expect(a).toBe(b);
  });
  it("fingerprint differs by command and payload", () => {
    expect(fingerprint("a", { x: 1 })).not.toBe(fingerprint("b", { x: 1 }));
    expect(fingerprint("a", { x: 1 })).not.toBe(fingerprint("a", { x: 2 }));
  });
  it("replays the stored result for the same request", () => {
    const fp = fingerprint("acceptOffer", { tripId: "t" });
    const d = replayDecision({ fingerprint: fp, result: { revision: 4 }, command: "acceptOffer", uid: "u", createdAt: 0 }, fp);
    expect(d).toEqual({ replay: true, result: { revision: 4 } });
  });
  it("rejects a reused key with a different payload", () => {
    const rec = { fingerprint: fingerprint("x", { a: 1 }), result: null, command: "x", uid: "u", createdAt: 0 };
    expect(code(() => replayDecision(rec, fingerprint("x", { a: 2 })))).toBe("idempotency_mismatch");
  });
  it("runs when there is no record", () => {
    expect(replayDecision(undefined, "fp")).toEqual({ replay: false });
  });
  it("validates key shape", () => {
    expect(code(() => assertKey("short"))).toBe("validation_failed");
    expect(code(() => assertKey("has spaces in it!!!!"))).toBe("validation_failed");
    expect(assertKey("01HZX3Q8W9ABCDEF12")).toBe("01HZX3Q8W9ABCDEF12");
  });
  it("revision must match exactly", () => {
    expect(code(() => assertRevision(5, 4))).toBe("stale_revision");
    expect(code(() => assertRevision(5, undefined))).toBe("validation_failed");
    expect(code(() => assertRevision(5, 5))).toBe("ok");
  });
});
