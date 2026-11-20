import { describe, expect, it } from "vitest";
import { assertWithinBounds, commissionMinor, quote, toMinor, validatePricingConfig, type PricingConfig } from "../../src/domain/pricing";

const cfg: PricingConfig = { baseFare: 500, perKm: 300, perMinute: 20, minFare: 800, maxFare: 50000, belowReferencePct: 0.2, aboveReferencePct: 0.5, commissionBps: 1500 };
const code = (f: () => unknown) => { try { f(); return "ok"; } catch (e: any) { return e.code; } };

describe("quote", () => {
  it("computes reference = base + km + minutes, rounded", () => {
    // 500 + 300*5.2 + 20*14 = 500 + 1560 + 280 = 2340
    expect(quote(cfg, 5200, 14 * 60).referenceFare).toBe(2340);
  });
  it("range is [ref*(1-below) rounded up, ref*(1+above) rounded down]", () => {
    const q = quote(cfg, 5200, 840);
    expect(q.minFare).toBe(1872);   // ceil(2340*0.8)
    expect(q.maxFare).toBe(3510);   // floor(2340*1.5)
  });
  it("never goes below the absolute floor", () => {
    const q = quote(cfg, 100, 30);
    expect(q.referenceFare).toBe(800);
    expect(q.minFare).toBe(800);
  });
  it("never exceeds the absolute ceiling", () => {
    const q = quote({ ...cfg, maxFare: 3000 }, 50_000, 3600);
    expect(q.referenceFare).toBe(3000);
    expect(q.maxFare).toBe(3000);
  });
  it("all outputs are whole numbers", () => {
    for (let m = 0; m < 40_000; m += 1777) {
      const q = quote(cfg, m, m / 8);
      expect([q.referenceFare, q.minFare, q.maxFare].every(Number.isInteger)).toBe(true);
      expect(q.minFare <= q.referenceFare && q.referenceFare <= q.maxFare).toBe(true);
    }
  });
});

describe("bounds", () => {
  const q = { minFare: 1872, maxFare: 3510 };
  it("accepts the edges", () => {
    expect(assertWithinBounds(1872, q)).toBe(1872);
    expect(assertWithinBounds(3510, q)).toBe(3510);
  });
  it("rejects outside and fractional", () => {
    expect(code(() => assertWithinBounds(1871, q))).toBe("out_of_bounds");
    expect(code(() => assertWithinBounds(3511, q))).toBe("out_of_bounds");
    expect(code(() => assertWithinBounds(2000.5, q))).toBe("validation_failed");
  });
});

describe("money", () => {
  it("toMinor is exact for whole units and rejects fractions", () => {
    expect(toMinor(2340)).toBe(234000);
    expect(code(() => toMinor(1.5))).toBe("validation_failed");
  });
  it("commission rounds half up to whole units (settleable in cash)", () => {
    expect(commissionMinor(234000, 1500)).toBe(35100);  // 351.00 exactly
    expect(commissionMinor(185000, 1500)).toBe(27800);  // 277.50 → 278
    expect(commissionMinor(184900, 1500)).toBe(27700);  // 277.35 → 277
    expect(commissionMinor(100, 1500)).toBe(0);         // 0.15 → 0
    for (let f = 0; f < 500000; f += 1300) expect(commissionMinor(f, 1500) % 100).toBe(0);
  });
});

describe("config validation", () => {
  it("rejects min > max and silly commissions", () => {
    expect(code(() => validatePricingConfig({ ...cfg, minFare: 60000 }))).toBe("validation_failed");
    expect(code(() => validatePricingConfig({ ...cfg, commissionBps: 6000 }))).toBe("validation_failed");
    expect(code(() => validatePricingConfig({ ...cfg, perKm: 2.5 }))).toBe("validation_failed");
  });
});
