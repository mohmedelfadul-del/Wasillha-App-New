import 'package:wa3_core/wa3_core.dart';

import '../../common/domain/live.dart';

/// Result of `createDraft`: the server's route and reference price.
class DraftResult {
  const DraftResult({required this.tripId, required this.revision, required this.quote, required this.route});
  final String tripId;
  final int revision;
  final Quote quote;
  final RouteInfo route;
}

class TripPage {
  const TripPage({required this.trips, required this.cursor, required this.hasMore});
  final List<Trip> trips;

  /// Opaque position for the next page.
  final Object? cursor;
  final bool hasMore;
}

/// The rider's trips: authoritative reads (realtime) and server commands.
abstract class TripRepository {
  /// trips/{id}; value is null when the trip doesn't exist.
  Stream<Live<Trip?>> watchTrip(String tripId);

  /// Own trips in non-terminal states (excluding drafts), newest first.
  Stream<Live<List<Trip>>> watchActiveTrips();

  /// trips/{id}/offers with status active (expiry is filtered by the screen).
  Stream<Live<List<Offer>>> watchOffers(String tripId);

  /// presence/{driverId}; null when there is no position yet.
  Stream<DriverPosition?> watchDriverPosition(String driverId);

  /// Own trips, newest first.
  Future<TripPage> history({Object? after, int limit = 20});

  Future<DraftResult> createDraft({required Place pickup, required Place dropoff, required Category category, required IntentKey key});
  Future<void> confirmRequest({required String tripId, required int proposedFare, required int expectedRevision, required IntentKey key});
  Future<void> acceptOffer({required String tripId, required String offerId, required int expectedRevision, required IntentKey key});
  Future<void> cancelTrip({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key});
  Future<void> rateTrip({required String tripId, required int stars, String? comment, required IntentKey key});
  Future<void> disputeTrip({required String tripId, required String reason, required int expectedRevision, required IntentKey key});
  Future<void> reportSafety({required String tripId, required String description, required IntentKey key});

  /// `shareTrip` → public live-view link.
  Future<Uri> shareLink({required String tripId, required IntentKey key});
}

/// States the home screen treats as "active trip" (server's NON_TERMINAL).
const activeTripStates = [
  TripState.searching,
  TripState.offering,
  TripState.driverAssigned,
  TripState.driverEnRoute,
  TripState.driverArrived,
  TripState.inProgress,
  TripState.arrived,
  TripState.paymentPending,
];
