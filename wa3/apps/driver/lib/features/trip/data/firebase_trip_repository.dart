import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/trip_repository.dart';

class FirebaseTripRepository implements TripRepository {
  FirebaseTripRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Stream<Live<Trip?>> watchTrip(String tripId) => _db
      .collection('trips')
      .doc(tripId)
      .snapshots(includeMetadataChanges: true)
      .map((s) => Live(s.exists ? Trip.fromJson(s.id, s.data()!) : null, fromCache: s.metadata.isFromCache));

  @override
  Future<void> stage(String command, {required String tripId, required int expectedRevision, required IntentKey key}) =>
      _api.stage(command, tripId: tripId, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> recordCash({required String tripId, required int amount, required int expectedRevision, required IntentKey key}) =>
      _api.recordCash(tripId: tripId, amount: amount, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> cancel({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key}) =>
      _api.cancelTrip(tripId: tripId, reason: reason, note: note, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> rateRider({required String tripId, required int stars, String? comment, required IntentKey key}) =>
      _api.rateTrip(tripId: tripId, stars: stars, comment: comment, key: key);
}
