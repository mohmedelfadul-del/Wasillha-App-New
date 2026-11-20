import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/finance_repository.dart';

class FirestoreFinanceRepository implements FinanceRepository {
  FirestoreFinanceRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Future<DriverMoney> driverMoney(String driverId) async => DriverMoney.fromJson(await _api.driverMoney(driverId: driverId));

  @override
  Stream<Live<List<LedgerRecord>>> ledger(String driverId, {int limit = 50}) => _db
      .collection('ledger')
      .where('driverId', isEqualTo: driverId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .live((d) => LedgerRecord(d.id, LedgerEntry.fromJson(d.data() ?? const {}), createdBy: d.data()?['createdBy'] as String?));

  @override
  Future<int> recordSettlement({required String driverId, required int amount, required String reference, required IntentKey key}) async {
    final r = await _api.recordSettlement(driverId: driverId, amount: amount, reference: reference, key: key);
    return (r['owedMinor'] as num?)?.toInt() ?? 0;
  }
}
