import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/request_repository.dart';

class FirebaseRequestRepository implements RequestRepository {
  FirebaseRequestRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Stream<Live<List<RequestCard>>> watchInbox(String uid) => _db
      .collection('inbox')
      .doc(uid)
      .collection('requests')
      .snapshots(includeMetadataChanges: true)
      .map((q) => Live(q.docs.map((d) => RequestCard.fromJson(d.id, d.data())).toList(), fromCache: q.metadata.isFromCache));

  @override
  Stream<Offer?> watchMyOffer({required String tripId, required String uid}) =>
      _db.collection('trips').doc(tripId).collection('offers').doc(uid).snapshots().map((s) => s.exists ? Offer.fromJson(s.id, s.data()!) : null);

  @override
  Future<DateTime> submitOffer({required String tripId, required int price, required int etaMinutes, required IntentKey key}) async {
    final r = await _api.submitOffer(tripId: tripId, price: price, etaMinutes: etaMinutes, key: key);
    return DateTime.fromMillisecondsSinceEpoch((r['expiresAt'] as num).toInt());
  }
}
