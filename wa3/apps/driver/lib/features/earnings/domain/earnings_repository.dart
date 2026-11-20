import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

/// Today's work, derived from the driver's own trips and ledger rows.
class TodaySummary {
  const TodaySummary({required this.completedTrips, required this.collectedMinor, required this.commissionMinor});
  final int completedTrips;
  final int collectedMinor;
  final int commissionMinor;
  int get netMinor => collectedMinor - commissionMinor;

  static TodaySummary compute({required List<Trip> trips, required List<LedgerEntry> ledger, required DateTime startOfDay}) {
    bool today(DateTime? t) => t != null && !t.isBefore(startOfDay);
    final done = trips.where((t) => t.state == TripState.completed && today(t.stamp(TripState.completed))).length;
    var collected = 0, commission = 0;
    for (final e in ledger.where((e) => today(e.createdAt))) {
      if (e.kind == LedgerKind.cash_collected) collected += e.amountMinor;
      if (e.kind == LedgerKind.commission_due) commission += e.amountMinor;
    }
    return TodaySummary(completedTrips: done, collectedMinor: collected, commissionMinor: commission);
  }
}

DateTime startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

abstract class EarningsRepository {
  /// Derived totals and ledger history from the server (`myEarnings`).
  Future<DriverMoney> myEarnings();
  Stream<Live<TodaySummary>> watchToday(String uid, DateTime startOfDay);
}
