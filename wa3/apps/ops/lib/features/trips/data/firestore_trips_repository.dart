import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/data_errors.dart';
import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/trips_repository.dart';

class FirestoreTripsRepository implements TripsRepository {
  FirestoreTripsRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  CollectionReference<Json> get _trips => _db.collection('trips');

  @override
  Stream<Live<List<TripRecord>>> live({int limit = 300}) =>
      _trips.where('state', whereIn: liveStates.map((s) => s.name).toList()).orderBy('updatedAt').limit(limit).live(tripRecordOf);

  @override
  Stream<Live<TripRecord?>> watch(String id) => _trips.doc(id).live(tripRecordOf);

  @override
  Future<TripRecord?> get(String id) => guarded(() async {
        final d = await _trips.doc(id).get();
        return d.exists ? tripRecordOf(d) : null;
      });

  @override
  Stream<Live<List<TripRecord>>> recentForRider(String riderId, {int limit = 20}) =>
      _trips.where('riderId', isEqualTo: riderId).orderBy('createdAt', descending: true).limit(limit).live(tripRecordOf);

  @override
  Stream<Live<List<TripRecord>>> recentForDriver(String driverId, {int limit = 20}) =>
      _trips.where('driverId', isEqualTo: driverId).orderBy('createdAt', descending: true).limit(limit).live(tripRecordOf);

  @override
  Future<void> opsCancel({required String tripId, required String reason, required String note, required int expectedRevision, required IntentKey key}) =>
      _api.opsCancelTrip(tripId: tripId, reason: reason, note: note, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> resolveDispute({required String tripId, required String resolution, required int expectedRevision, required IntentKey key}) =>
      _api.resolveDispute(tripId: tripId, resolution: resolution, expectedRevision: expectedRevision, key: key);
}

TripRecord tripRecordOf(DocumentSnapshot<Json> d) {
  final m = d.data() ?? const <String, dynamic>{};
  final dispute = m['dispute'];
  return TripRecord(
    Trip.fromJson(d.id, m),
    updatedAt: millisToDate(m['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    disputeResolution: dispute is Map ? dispute['resolution'] as String? : null,
  );
}
