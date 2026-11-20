import { describe, expect, it } from "vitest";
import { assertSettlementAllowed, entry, summarize, type LedgerEntry } from "../../src/domain/ledger";

const base = { driverId: "d1", createdBy: "system", createdAt: 0 };
const code = (f: () => unknown) => { try { f(); return "ok"; } catch (e: any) { return e.code; } };

describe("ledger", () => {
  const entries: LedgerEntry[] = [
    entry({ ...base, kind: "cash_collected", amountMinor: 234000, tripId: "t1" }),
    entry({ ...base, kind: "commission_due", amountMinor: 35100, tripId: "t1" }),
    entry({ ...base, kind: "cash_collected", amountMinor: 150000, tripId: "t2" }),
    entry({ ...base, kind: "commission_due", amountMinor: 22500, tripId: "t2" }),
    entry({ ...base, kind: "settlement", amountMinor: 40000, createdBy: "ops1" }),
  ];
  it("derives earned and owed from entries", () => {
    expect(summarize(entries)).toEqual({
      collectedMinor: 384000,
      commissionMinor: 57600,
      earnedMinor: 326400,
      settledMinor: 40000,
      owedMinor: 17600,
    });
  });
  it("adjustments move what is owed in either direction", () => {
    const s = summarize([...entries,
      entry({ ...base, kind: "adjustment", amountMinor: 1000, sign: 1, reason: "late fee" }),
      entry({ ...base, kind: "adjustment", amountMinor: 600, sign: -1, reason: "refund" })]);
    expect(s.owedMinor).toBe(18000);
  });
  it("rejects non-integer, zero and negative amounts", () => {
    expect(code(() => entry({ ...base, kind: "settlement", amountMinor: 10.5 }))).toBe("validation_failed");
    expect(code(() => entry({ ...base, kind: "settlement", amountMinor: 0 }))).toBe("validation_failed");
    expect(code(() => entry({ ...base, kind: "settlement", amountMinor: -5 }))).toBe("validation_failed");
  });
  it("adjustments need sign and reason; others may not carry a sign", () => {
    expect(code(() => entry({ ...base, kind: "adjustment", amountMinor: 5 } as LedgerEntry))).toBe("validation_failed");
    expect(code(() => entry({ ...base, kind: "adjustment", amountMinor: 5, sign: 1 }))).toBe("validation_failed");
    expect(code(() => entry({ ...base, kind: "settlement", amountMinor: 5, sign: 1 }))).toBe("validation_failed");
  });
  it("settlement cannot exceed what is owed", () => {
    const s = summarize(entries);
    expect(code(() => assertSettlementAllowed(s, 17601))).toBe("out_of_bounds");
    expect(code(() => assertSettlementAllowed(s, 17600))).toBe("ok");
  });
});
