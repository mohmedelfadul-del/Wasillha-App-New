import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

abstract class TripRepository {
  /// trips/{tripId}; null if it doesn't exist or isn't readable.
  Stream<Live<Trip?>> watchTrip(String tripId);

  /// ackAssignment | markArrived | startTrip | finishTrip.
  Future<void> stage(String command, {required String tripId, required int expectedRevision, required IntentKey key});
  Future<void> recordCash({required String tripId, required int amount, required int expectedRevision, required IntentKey key});
  Future<void> cancel({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key});
  Future<void> rateRider({required String tripId, required int stars, String? comment, required IntentKey key});
}
