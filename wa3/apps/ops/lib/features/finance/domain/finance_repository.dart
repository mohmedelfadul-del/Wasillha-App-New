import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

class LedgerRecord {
  const LedgerRecord(this.id, this.entry, {this.createdBy});
  final String id;
  final LedgerEntry entry;
  final String? createdBy;
}

abstract class FinanceRepository {
  Future<DriverMoney> driverMoney(String driverId);

  /// Newest first.
  Stream<Live<List<LedgerRecord>>> ledger(String driverId, {int limit = 50});

  /// Returns what is still owed (minor units) after the settlement.
  Future<int> recordSettlement({required String driverId, required int amount, required String reference, required IntentKey key});
}
