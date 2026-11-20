/**
 * Wire contract shared by the backend and the three clients.
 * The Dart mirror lives in wa3/packages/wa3_core/lib/src/contract/; the
 * contract test (test/unit/contract.test.ts) fails if the two drift apart.
 */

export const TRIP_STATES = [
  "draft",
  "searching",
  "offering",
  "driverAssigned",
  "driverEnRoute",
  "driverArrived",
  "inProgress",
  "arrived",
  "paymentPending",
  "completed",
  "cancelled",
  "disputed",
] as const;
export type TripState = (typeof TRIP_STATES)[number];

/** States in which the trip can still be cancelled (before pickup). */
export const PRE_PICKUP_STATES: readonly TripState[] = [
  "draft",
  "searching",
  "offering",
  "driverAssigned",
  "driverEnRoute",
  "driverArrived",
];

/** States in which a driver is committed to the trip. */
export const DRIVER_ACTIVE_STATES: readonly TripState[] = [
  "driverAssigned",
  "driverEnRoute",
  "driverArrived",
  "inProgress",
  "arrived",
  "paymentPending",
];

export const OPEN_REQUEST_STATES: readonly TripState[] = ["searching", "offering"];

export type Actor = "rider" | "driver" | "ops" | "system";

export const CATEGORIES = ["rickshaw", "motorbike", "economy", "comfort", "family"] as const;
export type Category = (typeof CATEGORIES)[number];

export const CANCEL_REASONS = {
  rider: ["change_of_plans", "driver_too_far", "wrong_location", "other"],
  driver: ["rider_no_show", "rider_unreachable", "vehicle_issue", "unsafe_situation", "other"],
  ops: ["safety", "fraud", "duplicate", "rider_request", "driver_request", "other"],
  system: ["no_offers", "draft_expired"],
} as const satisfies Record<Actor, readonly string[]>;

export const DOCUMENT_TYPES = ["national_id", "driving_license", "vehicle_registration", "insurance", "driver_photo", "vehicle_photo"] as const;
export type DocumentType = (typeof DOCUMENT_TYPES)[number];

export const REVIEW_STATUSES = ["pending", "approved", "rejected", "changesRequested"] as const;
export type ReviewStatus = (typeof REVIEW_STATUSES)[number];

export const DRIVER_STATUSES = ["onboarding", "underReview", "approved", "suspended"] as const;
export type DriverStatus = (typeof DRIVER_STATUSES)[number];

export const OFFER_STATUSES = ["active", "accepted", "expired", "withdrawn", "lost"] as const;
export type OfferStatus = (typeof OFFER_STATUSES)[number];

export const LEDGER_KINDS = ["cash_collected", "commission_due", "settlement", "adjustment"] as const;
export type LedgerKind = (typeof LEDGER_KINDS)[number];

export const STAFF_ROLES = ["admin", "operations", "kyc", "support", "finance"] as const;
export type StaffRole = (typeof STAFF_ROLES)[number];

export const CASE_TYPES = ["dispute", "safety", "support"] as const;
export type CaseType = (typeof CASE_TYPES)[number];

/** Error codes returned to clients (HttpsError details.code). */
export const ERROR_CODES = [
  "invalid_transition",
  "stale_revision",
  "not_found",
  "permission_denied",
  "out_of_bounds",
  "offer_expired",
  "driver_busy",
  "not_verified",
  "outside_zone",
  "idempotency_mismatch",
  "dispute_window_closed",
  "validation_failed",
  "maps_unavailable",
  "mfa_required",
  "already_claimed",
] as const;
export type ErrorCode = (typeof ERROR_CODES)[number];

/**
 * Operational tunables. All `[N]` values from the brief live here so they are
 * one edit away. Assumed values — change freely.
 */
export const TUNABLES = {
  offerTtlSeconds: 60,
  requestTtlSeconds: 5 * 60,
  draftTtlSeconds: 15 * 60,
  disputeWindowHours: 48,
  stuckTripMinutes: 10,
  nearbyRadiusKm: 15,
  locationStaleSeconds: 30,
  maxOffersPerTrip: 10,
  /** Minor units per whole currency unit (SDG piastres). */
  minorPerUnit: 100,
  currency: "SDG",
} as const;
