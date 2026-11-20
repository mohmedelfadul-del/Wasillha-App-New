import { TUNABLES } from "./contract";
import { fail } from "./errors";

/** Per zone × category pricing, edited in the operations console. Whole currency units. */
export interface PricingConfig {
  baseFare: number;
  perKm: number;
  perMinute: number;
  /** Absolute floor for any proposal or offer. */
  minFare: number;
  /** Absolute ceiling for any proposal or offer. */
  maxFare: number;
  /** How far below the reference a rider may propose, 0–1 (e.g. 0.2 = 20 %). */
  belowReferencePct: number;
  /** How far above the reference a proposal / offer may go, 0–5. */
  aboveReferencePct: number;
  /** Company commission in basis points (1500 = 15 %). */
  commissionBps: number;
}

export interface Quote {
  referenceFare: number;
  minFare: number;
  maxFare: number;
}

const isWhole = (n: unknown): n is number => typeof n === "number" && Number.isInteger(n) && n >= 0;

export function validatePricingConfig(c: PricingConfig): PricingConfig {
  const whole = ["baseFare", "perKm", "perMinute", "minFare", "maxFare", "commissionBps"] as const;
  for (const k of whole) if (!isWhole(c[k])) fail("validation_failed", `${k} must be a whole, non-negative number`);
  if (c.minFare > c.maxFare) fail("validation_failed", "minFare must not exceed maxFare");
  if (!(c.belowReferencePct >= 0 && c.belowReferencePct < 1)) fail("validation_failed", "belowReferencePct must be in [0, 1)");
  if (!(c.aboveReferencePct >= 0 && c.aboveReferencePct <= 5)) fail("validation_failed", "aboveReferencePct must be in [0, 5]");
  if (c.commissionBps > 5000) fail("validation_failed", "commissionBps above 50 % is not allowed");
  return c;
}

/**
 * Reference fare and the allowed range for a route. Whole units only:
 * the lower bound rounds up and the upper bound rounds down so the range
 * never exceeds the configured percentages.
 */
export function quote(c: PricingConfig, distanceMeters: number, durationSeconds: number): Quote {
  if (!(distanceMeters >= 0) || !(durationSeconds >= 0)) fail("validation_failed", "Route distance and duration are required");
  const raw = c.baseFare + (c.perKm * distanceMeters) / 1000 + (c.perMinute * durationSeconds) / 60;
  const referenceFare = clamp(Math.round(raw), c.minFare, c.maxFare);
  const minFare = clamp(Math.ceil(referenceFare * (1 - c.belowReferencePct)), c.minFare, c.maxFare);
  const maxFare = clamp(Math.floor(referenceFare * (1 + c.aboveReferencePct)), minFare, c.maxFare);
  return { referenceFare, minFare, maxFare };
}

/** Throws out_of_bounds unless `fare` is a whole number within the quote's range. */
export function assertWithinBounds(fare: number, q: Pick<Quote, "minFare" | "maxFare">, what = "Fare"): number {
  if (!Number.isInteger(fare)) fail("validation_failed", `${what} must be a whole number`);
  if (fare < q.minFare || fare > q.maxFare) {
    fail("out_of_bounds", `${what} must be between ${q.minFare} and ${q.maxFare}`, { min: q.minFare, max: q.maxFare });
  }
  return fare;
}

/** Converts whole currency units to integer minor units. */
export const toMinor = (units: number) => {
  if (!Number.isInteger(units)) fail("validation_failed", "Amounts must be whole currency units");
  return units * TUNABLES.minorPerUnit;
};

/**
 * Commission in minor units, rounded half-up to a WHOLE currency unit.
 * Cash and settlements move in whole units, so a fractional commission would
 * leave a debt that can never be settled.
 */
export function commissionMinor(fareMinor: number, bps: number): number {
  if (!Number.isInteger(fareMinor) || !Number.isInteger(bps)) fail("validation_failed", "Integer inputs required");
  const unit = TUNABLES.minorPerUnit;
  // fareMinor * bps / 10000 / unit, rounded half-up, in integer arithmetic.
  const denom = 10000 * unit;
  return Math.floor((fareMinor * bps + denom / 2) / denom) * unit;
}

const clamp = (n: number, lo: number, hi: number) => Math.min(Math.max(n, lo), hi);
