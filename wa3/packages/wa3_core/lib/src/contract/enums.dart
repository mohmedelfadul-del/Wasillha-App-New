/// Dart mirror of wa3/backend/functions/src/domain/contract.ts.
/// test/contract_test.dart fails if the two drift apart.
library;

enum TripState {
  draft,
  searching,
  offering,
  driverAssigned,
  driverEnRoute,
  driverArrived,
  inProgress,
  arrived,
  paymentPending,
  completed,
  cancelled,
  disputed;

  static TripState parse(Object? s) =>
      TripState.values.firstWhere((e) => e.name == s, orElse: () => TripState.draft);

  bool get isOpenRequest => this == searching || this == offering;
  bool get isPrePickup => index <= driverArrived.index;
  bool get hasDriver => index >= driverAssigned.index && index <= paymentPending.index;
  bool get isTerminal => this == completed || this == cancelled || this == disputed;
  bool get isLive => !isTerminal && this != draft;
}

/// States before pickup, in which a cancellation is allowed.
const prePickupStates = {
  TripState.draft,
  TripState.searching,
  TripState.offering,
  TripState.driverAssigned,
  TripState.driverEnRoute,
  TripState.driverArrived,
};

enum Category {
  rickshaw,
  motorbike,
  economy,
  comfort,
  family;

  static Category parse(Object? s) =>
      Category.values.firstWhere((e) => e.name == s, orElse: () => Category.economy);
}

/// Coded cancellation reasons per actor (server validates the same lists).
const cancelReasons = <String, List<String>>{
  'rider': ['change_of_plans', 'driver_too_far', 'wrong_location', 'other'],
  'driver': ['rider_no_show', 'rider_unreachable', 'vehicle_issue', 'unsafe_situation', 'other'],
  'ops': ['safety', 'fraud', 'duplicate', 'rider_request', 'driver_request', 'other'],
  'system': ['no_offers', 'draft_expired'],
};

enum DocumentType {
  national_id,
  driving_license,
  vehicle_registration,
  insurance,
  driver_photo,
  vehicle_photo;

  static DocumentType parse(Object? s) =>
      DocumentType.values.firstWhere((e) => e.name == s, orElse: () => DocumentType.national_id);
}

const driverDocumentTypes = [DocumentType.national_id, DocumentType.driving_license, DocumentType.driver_photo];
const vehicleDocumentTypes = [DocumentType.vehicle_registration, DocumentType.insurance, DocumentType.vehicle_photo];

enum ReviewStatus {
  pending,
  approved,
  rejected,
  changesRequested;

  static ReviewStatus parse(Object? s) =>
      ReviewStatus.values.firstWhere((e) => e.name == s, orElse: () => ReviewStatus.pending);
}

enum DriverStatus {
  onboarding,
  underReview,
  approved,
  suspended;

  static DriverStatus parse(Object? s) =>
      DriverStatus.values.firstWhere((e) => e.name == s, orElse: () => DriverStatus.onboarding);
}

enum OfferStatus {
  active,
  accepted,
  expired,
  withdrawn,
  lost;

  static OfferStatus parse(Object? s) =>
      OfferStatus.values.firstWhere((e) => e.name == s, orElse: () => OfferStatus.expired);
}

enum LedgerKind { cash_collected, commission_due, settlement, adjustment }

enum StaffRole { admin, operations, kyc, support, finance }

enum CaseType { dispute, safety, support }

/// Error codes the server returns in `details.code`.
const errorCodes = [
  'invalid_transition',
  'stale_revision',
  'not_found',
  'permission_denied',
  'out_of_bounds',
  'offer_expired',
  'driver_busy',
  'not_verified',
  'outside_zone',
  'idempotency_mismatch',
  'dispute_window_closed',
  'validation_failed',
  'maps_unavailable',
  'mfa_required',
  'already_claimed',
];

/// Operational tunables mirrored from the server (display only — the server enforces).
class Tunables {
  const Tunables._();
  static const offerTtlSeconds = 60;
  static const requestTtlSeconds = 300;
  static const locationStaleSeconds = 30;
  static const disputeWindowHours = 48;
  static const nearbyRadiusKm = 15;
  static const minorPerUnit = 100;
  static const currency = 'SDG';

  /// Driver location cadence (brief: ~5 s moving, ~15 s heartbeat stationary).
  static const locationMovingSeconds = 5;
  static const locationHeartbeatSeconds = 15;
}
