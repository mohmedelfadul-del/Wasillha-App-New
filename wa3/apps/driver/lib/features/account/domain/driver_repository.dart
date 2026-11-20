import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

/// The driver's own document (drivers/{uid}) plus fields the shared model
/// doesn't carry.
class DriverState {
  const DriverState({required this.profile, required this.ratingCount, this.updatedAt});
  final DriverProfile profile;
  final int ratingCount;
  final DateTime? updatedAt;

  bool get approved => profile.status == DriverStatus.approved;
  bool get hasTrip => profile.activeTripId != null;
  bool get locationLost => !profile.online && profile.offlineReason == 'location_lost';
}

abstract class DriverRepository {
  /// Emits null while the driver hasn't registered yet.
  Stream<Live<DriverState?>> watchDriver(String uid);
  Future<void> register({required String name, required IntentKey key});
  Future<void> setActiveVehicle({required String vehicleId, required IntentKey key});

  /// Throws [ApiFailure] with the server's exact reason (not_verified,
  /// outside_zone, validation_failed for stale location, …).
  Future<void> goOnline();
  Future<void> goOffline();
}
