import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/earnings_repository.dart';

class FirebaseEarningsRepository implements EarningsRepository {
  FirebaseEarningsRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Future<DriverMoney> myEarnings() async => DriverMoney.fromJson(await _api.myEarnings());

  @override
  Stream<Live<TodaySummary>> watchToday(String uid, DateTime start) {
    // Trips created up to a day earlier can still complete today.
    final trips = _db
        .collection('trips')
        .where('driverId', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: start.subtract(const Duration(days: 1)).millisecondsSinceEpoch)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots(includeMetadataChanges: true);
    final ledger = _db
        .collection('ledger')
        .where('driverId', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true);
    return combineLatest2(trips, ledger, (QuerySnapshot<Map<String, dynamic>> t, QuerySnapshot<Map<String, dynamic>> l) => Live(
          TodaySummary.compute(
            trips: t.docs.map((d) => Trip.fromJson(d.id, d.data())).toList(),
            ledger: l.docs.map((d) => LedgerEntry.fromJson(d.data())).toList(),
            startOfDay: start,
          ),
          fromCache: t.metadata.isFromCache || l.metadata.isFromCache,
        ));
  }
}
