import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/history_repository.dart';

class FirebaseHistoryRepository implements HistoryRepository {
  FirebaseHistoryRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Future<TripPage> page(String uid, {Object? after}) async {
    var q = _db.collection('trips').where('driverId', isEqualTo: uid).orderBy('createdAt', descending: true).limit(historyPageSize);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    try {
      final r = await q.get();
      return TripPage(
        trips: r.docs.map((d) => Trip.fromJson(d.id, d.data())).toList(),
        cursor: r.docs.isEmpty ? null : r.docs.last,
        hasMore: r.docs.length == historyPageSize,
      );
    } on FirebaseException catch (e) {
      throw ApiFailure(e.code == 'permission-denied' ? 'permission_denied' : 'network', e.message ?? e.code);
    }
  }
}
