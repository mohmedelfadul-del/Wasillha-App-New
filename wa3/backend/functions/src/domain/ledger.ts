import type { LedgerKind } from "./contract";
import { fail } from "./errors";

/**
 * Append-only money ledger. Every amount is a positive integer in minor
 * units; the kind gives it meaning. Balances are always derived, never stored.
 *
 *  cash_collected  driver received cash from the rider (driver's money)
 *  commission_due  driver owes the company this commission
 *  settlement      driver paid the company (reduces what is owed)
 *  adjustment      ops correction; `sign` +1 increases owed, −1 decreases it
 */
export interface LedgerEntry {
  driverId: string;
  kind: LedgerKind;
  amountMinor: number;
  sign?: 1 | -1;          // adjustments only
  tripId?: string;
  reason?: string;
  createdBy: string;      // uid or "system"
  createdAt: number;      // ms
}

export interface DriverMoney {
  /** Cash the driver collected from riders. */
  collectedMinor: number;
  /** Commission charged by the company on those trips. */
  commissionMinor: number;
  /** collected − commission: what the driver earned. */
  earnedMinor: number;
  /** Settlements the driver has paid to the company. */
  settledMinor: number;
  /** commission + adjustments − settlements: what the driver still owes. */
  owedMinor: number;
}

export function entry(e: LedgerEntry): LedgerEntry {
  if (!Number.isInteger(e.amountMinor) || e.amountMinor <= 0) {
    fail("validation_failed", "Ledger amounts must be positive integers in minor units");
  }
  if (e.kind === "adjustment" && e.sign !== 1 && e.sign !== -1) fail("validation_failed", "Adjustments need a sign");
  if (e.kind !== "adjustment" && e.sign !== undefined) fail("validation_failed", "Only adjustments carry a sign");
  if (e.kind === "adjustment" && !e.reason) fail("validation_failed", "Adjustments need a reason");
  return e;
}

export function summarize(entries: readonly LedgerEntry[]): DriverMoney {
  let collected = 0, commission = 0, settled = 0, adjust = 0;
  for (const e of entries) {
    switch (e.kind) {
      case "cash_collected": collected += e.amountMinor; break;
      case "commission_due": commission += e.amountMinor; break;
      case "settlement": settled += e.amountMinor; break;
      case "adjustment": adjust += (e.sign ?? 1) * e.amountMinor; break;
    }
  }
  return {
    collectedMinor: collected,
    commissionMinor: commission,
    earnedMinor: collected - commission,
    settledMinor: settled,
    owedMinor: commission + adjust - settled,
  };
}

/** Settlements may not exceed what is owed (no negative debt from a typo). */
export function assertSettlementAllowed(current: DriverMoney, amountMinor: number) {
  if (amountMinor > current.owedMinor) {
    fail("out_of_bounds", "Settlement exceeds the amount owed", { owedMinor: current.owedMinor });
  }
}
