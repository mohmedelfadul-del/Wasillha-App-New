import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

/// Non-terminal states shown on the live board.
final liveStates = TripState.values.where((s) => s.isLive).toList();

/// A trip with the server's `updatedAt`, which the shared model doesn't carry.
class TripRecord {
  const TripRecord(this.trip, {required this.updatedAt, this.disputeResolution});
  final Trip trip;
  final DateTime updatedAt;
  final String? disputeResolution;

  /// When the trip entered its current state.
  DateTime get stateSince => trip.stamp(trip.state) ?? updatedAt;
  bool get flagged => trip.stuck || trip.locationStale;
}

abstract class TripsRepository {
  /// Trips in non-terminal states, ordered by `updatedAt` (oldest first).
  Stream<Live<List<TripRecord>>> live({int limit = 300});
  Stream<Live<TripRecord?>> watch(String id);
  Future<TripRecord?> get(String id);
  Stream<Live<List<TripRecord>>> recentForRider(String riderId, {int limit = 20});
  Stream<Live<List<TripRecord>>> recentForDriver(String driverId, {int limit = 20});
  Future<void> opsCancel({required String tripId, required String reason, required String note, required int expectedRevision, required IntentKey key});
  Future<void> resolveDispute({required String tripId, required String resolution, required int expectedRevision, required IntentKey key});
}
