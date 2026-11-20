import { CANCEL_REASONS, PRE_PICKUP_STATES, TUNABLES, type Actor, type TripState } from "./contract";
import { fail } from "./errors";

/**
 * The single trip state machine. Clients request transitions by name; this
 * module decides whether the transition is legal for that actor in the
 * current state. Side effects (offers, ledger, inbox) live in the commands.
 */

export type Transition =
  | "confirm"          // draft → searching (rider confirms fare)
  | "firstOffer"       // searching → offering (system, on first driver offer)
  | "acceptOffer"      // offering → driverAssigned (rider)
  | "ackAssignment"    // driverAssigned → driverEnRoute (driver app, automatic)
  | "markArrived"      // driverEnRoute → driverArrived (driver)
  | "startTrip"        // driverArrived → inProgress (driver)
  | "finishTrip"       // inProgress → arrived (driver)
  | "issueReceipt"     // arrived → paymentPending (system, same command as finish)
  | "recordCash"       // paymentPending → completed (driver)
  | "cancel"           // pre-pickup → cancelled (rider | driver | ops | system)
  | "dispute"          // completed → disputed (rider | driver, within window)
  | "resolveDispute";  // disputed → completed (ops)

interface Rule {
  from: readonly TripState[];
  to: TripState;
  actors: readonly Actor[];
}

const RULES: Record<Transition, Rule> = {
  confirm: { from: ["draft"], to: "searching", actors: ["rider"] },
  firstOffer: { from: ["searching"], to: "offering", actors: ["system"] },
  acceptOffer: { from: ["offering"], to: "driverAssigned", actors: ["rider"] },
  ackAssignment: { from: ["driverAssigned"], to: "driverEnRoute", actors: ["driver"] },
  markArrived: { from: ["driverEnRoute"], to: "driverArrived", actors: ["driver"] },
  startTrip: { from: ["driverArrived"], to: "inProgress", actors: ["driver"] },
  finishTrip: { from: ["inProgress"], to: "arrived", actors: ["driver"] },
  issueReceipt: { from: ["arrived"], to: "paymentPending", actors: ["system"] },
  recordCash: { from: ["paymentPending"], to: "completed", actors: ["driver"] },
  cancel: { from: PRE_PICKUP_STATES, to: "cancelled", actors: ["rider", "driver", "ops", "system"] },
  dispute: { from: ["completed"], to: "disputed", actors: ["rider", "driver"] },
  resolveDispute: { from: ["disputed"], to: "completed", actors: ["ops"] },
};

/** Driver may only cancel once assigned (before that the trip isn't theirs). */
const DRIVER_CANCEL_FROM: readonly TripState[] = ["driverAssigned", "driverEnRoute", "driverArrived"];

export interface TransitionInput {
  state: TripState;
  transition: Transition;
  actor: Actor;
  cancelReason?: string;
  completedAt?: number;   // ms, for dispute window
  now?: number;           // ms
}

/** Returns the next state or throws a DomainError explaining why not. */
export function nextState(input: TransitionInput): TripState {
  const rule = RULES[input.transition];
  if (!rule) return fail("invalid_transition", `Unknown transition ${input.transition}`);
  if (!rule.actors.includes(input.actor)) {
    return fail("permission_denied", `${input.actor} cannot ${input.transition}`);
  }
  if (!rule.from.includes(input.state)) {
    return fail("invalid_transition", `Cannot ${input.transition} from ${input.state}`, {
      state: input.state,
      transition: input.transition,
    });
  }
  if (input.transition === "cancel") {
    if (input.actor === "driver" && !DRIVER_CANCEL_FROM.includes(input.state)) {
      return fail("invalid_transition", `Driver cannot cancel from ${input.state}`);
    }
    const allowed: readonly string[] = CANCEL_REASONS[input.actor];
    if (!input.cancelReason || !allowed.includes(input.cancelReason)) {
      return fail("validation_failed", "A valid cancellation reason is required", { allowed });
    }
  }
  if (input.transition === "dispute") {
    const now = input.now ?? Date.now();
    const windowMs = TUNABLES.disputeWindowHours * 3600_000;
    if (!input.completedAt || now - input.completedAt > windowMs) {
      return fail("dispute_window_closed", `Disputes must be opened within ${TUNABLES.disputeWindowHours} hours`);
    }
  }
  return rule.to;
}

export function canTransition(input: TransitionInput): boolean {
  try {
    nextState(input);
    return true;
  } catch {
    return false;
  }
}

export const isTerminal = (s: TripState) => s === "cancelled" || s === "completed" || s === "disputed";

/** Timestamp field recorded when a trip enters each state. */
export const stampField = (s: TripState) => `timestamps.${s}`;
