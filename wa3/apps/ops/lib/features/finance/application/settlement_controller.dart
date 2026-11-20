import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/finance_repository.dart';

/// One driver's money. The ledger listener is the change signal; each signal
/// triggers the heavier `driverMoney` read (it sums the whole ledger on the
/// server), coalesced so bursts cost one call.
class SettlementController extends ChangeNotifier {
  SettlementController(this._repo, this.driverId) {
    _money = RefreshCoalescer(_readMoney);
    _listen();
  }

  final FinanceRepository _repo;
  final String driverId;
  late final RefreshCoalescer _money;
  StreamSubscription<dynamic>? _sub;
  bool _disposed = false;

  DriverMoney? money;
  Object? moneyError;
  List<LedgerRecord>? ledger;
  Object? ledgerError;
  bool ledgerFromCache = false;

  void _listen() {
    _sub?.cancel();
    _sub = _repo.ledger(driverId).listen((live) {
      ledger = live.value;
      ledgerFromCache = live.fromCache;
      ledgerError = null;
      _notify();
      _money.signal();
    }, onError: (Object e) {
      ledgerError = e;
      _notify();
      _money.signal(); // money may still be readable
    });
  }

  Future<void> _readMoney() async {
    try {
      money = await _repo.driverMoney(driverId);
      moneyError = null;
    } catch (e) {
      moneyError = e;
    }
    _notify();
  }

  void refreshMoney() {
    moneyError = null;
    _notify();
    _money.signal();
  }

  void retryLedger() {
    ledgerError = null;
    ledger = null;
    _notify();
    _listen();
  }

  Future<int> settle({required int amount, required String reference}) async {
    final owed = await _repo.recordSettlement(driverId: driverId, amount: amount, reference: reference, key: IntentKey.generate());
    _money.signal();
    return owed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _money.dispose();
    _sub?.cancel();
    super.dispose();
  }
}
