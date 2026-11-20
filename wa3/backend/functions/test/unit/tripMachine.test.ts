import { describe, expect, it } from "vitest";
import { TRIP_STATES, type TripState } from "../../src/domain/contract";
import { canTransition, nextState, type Transition } from "../../src/domain/tripMachine";

const code = (f: () => unknown) => { try { f(); return "ok"; } catch (e: any) { return e.code; } };

describe("trip state machine — happy path", () => {
  const path: [TripState, Transition, "rider" | "driver" | "system", TripState][] = [
    ["draft", "confirm", "rider", "searching"],
    ["searching", "firstOffer", "system", "offering"],
    ["offering", "acceptOffer", "rider", "driverAssigned"],
    ["driverAssigned", "ackAssignment", "driver", "driverEnRoute"],
    ["driverEnRoute", "markArrived", "driver", "driverArrived"],
    ["driverArrived", "startTrip", "driver", "inProgress"],
    ["inProgress", "finishTrip", "driver", "arrived"],
    ["arrived", "issueReceipt", "system", "paymentPending"],
    ["paymentPending", "recordCash", "driver", "completed"],
  ];
  it.each(path)("%s --%s(%s)--> %s", (state, transition, actor, to) => {
    expect(nextState({ state, transition, actor })).toBe(to);
  });
});

describe("illegal transitions", () => {
  it("cannot accept an offer while still searching (no offers yet)", () => {
    expect(code(() => nextState({ state: "searching", transition: "acceptOffer", actor: "rider" }))).toBe("invalid_transition");
  });
  it("rider cannot drive the trip forward", () => {
    expect(code(() => nextState({ state: "driverArrived", transition: "startTrip", actor: "rider" }))).toBe("permission_denied");
  });
  it("cannot record cash twice", () => {
    expect(code(() => nextState({ state: "completed", transition: "recordCash", actor: "driver" }))).toBe("invalid_transition");
  });
  it("every transition from a terminal cancelled trip fails", () => {
    const all: Transition[] = ["confirm", "firstOffer", "acceptOffer", "ackAssignment", "markArrived", "startTrip", "finishTrip", "issueReceipt", "recordCash", "cancel", "dispute", "resolveDispute"];
    for (const t of all) for (const a of ["rider", "driver", "ops", "system"] as const) {
      expect(canTransition({ state: "cancelled", transition: t, actor: a, cancelReason: "other" })).toBe(false);
    }
  });
});

describe("cancellation", () => {
  it("rider can cancel any pre-pickup state with a valid reason", () => {
    for (const s of ["draft", "searching", "offering", "driverAssigned", "driverEnRoute", "driverArrived"] as TripState[]) {
      expect(nextState({ state: s, transition: "cancel", actor: "rider", cancelReason: "change_of_plans" })).toBe("cancelled");
    }
  });
  it("nobody can cancel once the trip is in progress", () => {
    for (const a of ["rider", "driver", "ops"] as const) {
      expect(code(() => nextState({ state: "inProgress", transition: "cancel", actor: a, cancelReason: "other" }))).toBe("invalid_transition");
    }
  });
  it("requires a reason from the actor's own list", () => {
    expect(code(() => nextState({ state: "searching", transition: "cancel", actor: "rider" }))).toBe("validation_failed");
    expect(code(() => nextState({ state: "searching", transition: "cancel", actor: "rider", cancelReason: "rider_no_show" }))).toBe("validation_failed");
  });
  it("driver can only cancel after assignment", () => {
    expect(code(() => nextState({ state: "offering", transition: "cancel", actor: "driver", cancelReason: "other" }))).toBe("invalid_transition");
    expect(nextState({ state: "driverArrived", transition: "cancel", actor: "driver", cancelReason: "rider_no_show" })).toBe("cancelled");
  });
  it("system expires requests with no_offers", () => {
    expect(nextState({ state: "offering", transition: "cancel", actor: "system", cancelReason: "no_offers" })).toBe("cancelled");
  });
});

describe("disputes", () => {
  const completedAt = Date.UTC(2026, 0, 1);
  it("allowed inside the window", () => {
    expect(nextState({ state: "completed", transition: "dispute", actor: "rider", completedAt, now: completedAt + 47 * 3600_000 })).toBe("disputed");
  });
  it("rejected after the window", () => {
    expect(code(() => nextState({ state: "completed", transition: "dispute", actor: "rider", completedAt, now: completedAt + 49 * 3600_000 }))).toBe("dispute_window_closed");
  });
  it("only ops resolves", () => {
    expect(nextState({ state: "disputed", transition: "resolveDispute", actor: "ops" })).toBe("completed");
    expect(code(() => nextState({ state: "disputed", transition: "resolveDispute", actor: "rider" }))).toBe("permission_denied");
  });
});

it("every state is reachable from draft", () => {
  const reach = new Set<TripState>(["draft"]);
  const ts: Transition[] = ["confirm", "firstOffer", "acceptOffer", "ackAssignment", "markArrived", "startTrip", "finishTrip", "issueReceipt", "recordCash", "cancel", "dispute", "resolveDispute"];
  let grew = true;
  while (grew) {
    grew = false;
    for (const s of [...reach]) for (const t of ts) for (const a of ["rider", "driver", "ops", "system"] as const) {
      try {
        const n = nextState({ state: s, transition: t, actor: a, cancelReason: a === "system" ? "no_offers" : "other", completedAt: 1, now: 2 });
        if (!reach.has(n)) { reach.add(n); grew = true; }
      } catch { /* not allowed */ }
    }
  }
  expect([...reach].sort()).toEqual([...TRIP_STATES].sort());
});
