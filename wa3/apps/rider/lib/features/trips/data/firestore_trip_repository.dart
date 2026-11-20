import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../common/data/firestore_errors.dart';
import '../../common/domain/live.dart';
import '../domain/trip_repository.dart';

class FirestoreTripRepository implements TripRepository {
  FirestoreTripRepository(this._db, this._auth, this._api, {required this.shareBaseUrl});
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final WasilhaApi _api;

  /// e.g. `https://europe-west1-PROJECT.cloudfunctions.net/sharedTrip`.
  final String shareBaseUrl;

  CollectionReference<Map<String, dynamic>> get _trips => _db.collection('trips');

  String get _uid {
    final u = _auth.currentUser?.uid;
    if (u == null) throw const ApiFailure('permission_denied', 'Not signed in');
    return u;
  }

  @override
  Stream<Live<Trip?>> watchTrip(String tripId) => _trips
      .doc(tripId)
      .snapshots(includeMetadataChanges: true)
      .map((d) => Live(d.exists ? Trip.fromJson(d.id, d.data()!) : null, fromCache: d.metadata.isFromCache))
      .transform(mapFirestoreErrors());

  @override
  Stream<Live<List<Trip>>> watchActiveTrips() {
    final String uid;
    try {
      uid = _uid;
    } on ApiFailure catch (e) {
      return Stream.error(e);
    }
    // Index: riderId + state. Sorted here (newest first) — normally 0 or 1 trip.
    return _trips
        .where('riderId', isEqualTo: uid)
        .where('state', whereIn: activeTripStates.map((s) => s.name).toList())
        .snapshots(includeMetadataChanges: true)
        .map((q) {
      final list = q.docs.map((d) => Trip.fromJson(d.id, d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Live(list, fromCache: q.metadata.isFromCache);
    }).transform(mapFirestoreErrors());
  }

  @override
  Stream<Live<List<Offer>>> watchOffers(String tripId) => _trips
      .doc(tripId)
      .collection('offers')
      .where('status', isEqualTo: OfferStatus.active.name)
      .snapshots(includeMetadataChanges: true)
      .map((q) => Live(q.docs.map((d) => Offer.fromJson(d.id, d.data())).toList(), fromCache: q.metadata.isFromCache))
      .transform(mapFirestoreErrors());

  @override
  Stream<DriverPosition?> watchDriverPosition(String driverId) => _db
      .collection('presence')
      .doc(driverId)
      .snapshots()
      .map((d) => d.exists ? DriverPosition.fromJson(d.data()!) : null)
      .transform(mapFirestoreErrors());

  @override
  Future<TripPage> history({Object? after, int limit = 20}) async {
    try {
      Query<Map<String, dynamic>> q = _trips.where('riderId', isEqualTo: _uid).orderBy('createdAt', descending: true).limit(limit);
      if (after is DocumentSnapshot) q = q.startAfterDocument(after);
      final snap = await q.get();
      return TripPage(
        trips: snap.docs.map((d) => Trip.fromJson(d.id, d.data())).toList(),
        cursor: snap.docs.isEmpty ? after : snap.docs.last,
        hasMore: snap.docs.length == limit,
      );
    } catch (e) {
      throw mapFirestoreError(e);
    }
  }

  @override
  Future<DraftResult> createDraft({required Place pickup, required Place dropoff, required Category category, required IntentKey key}) async {
    final r = await _api.createDraft(pickup: pickup.toJson(), dropoff: dropoff.toJson(), category: category.name, key: key);
    return DraftResult(
      tripId: r['tripId'] as String,
      revision: (r['revision'] as num).toInt(),
      quote: Quote.fromJson(r['quote']),
      route: RouteInfo.fromJson(r['route']),
    );
  }

  @override
  Future<void> confirmRequest({required String tripId, required int proposedFare, required int expectedRevision, required IntentKey key}) =>
      _api.confirmRequest(tripId: tripId, proposedFare: proposedFare, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> acceptOffer({required String tripId, required String offerId, required int expectedRevision, required IntentKey key}) =>
      _api.acceptOffer(tripId: tripId, offerId: offerId, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> cancelTrip({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key}) =>
      _api.cancelTrip(tripId: tripId, reason: reason, note: note, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> rateTrip({required String tripId, required int stars, String? comment, required IntentKey key}) =>
      _api.rateTrip(tripId: tripId, stars: stars, comment: comment, key: key);

  @override
  Future<void> disputeTrip({required String tripId, required String reason, required int expectedRevision, required IntentKey key}) =>
      _api.disputeTrip(tripId: tripId, reason: reason, expectedRevision: expectedRevision, key: key);

  @override
  Future<void> reportSafety({required String tripId, required String description, required IntentKey key}) =>
      _api.reportSafety(tripId: tripId, description: description, key: key);

  @override
  Future<Uri> shareLink({required String tripId, required IntentKey key}) async {
    final token = await _api.shareTrip(tripId: tripId, key: key);
    return Uri.parse(shareBaseUrl).replace(queryParameters: {'t': token});
  }
}
