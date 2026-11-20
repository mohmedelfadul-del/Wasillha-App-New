import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/features/earnings/domain/earnings_labels.dart';
import 'package:wasilha_driver/features/earnings/domain/earnings_repository.dart';
import 'package:wasilha_driver/features/earnings/presentation/earnings_screen.dart';

import 'fakes.dart';

void main() {
  final t0 = DateTime(2026, 11, 20, 9);
  final money = DriverMoney(
    collectedMinor: 1000000,
    commissionMinor: 100000,
    earnedMinor: 900000,
    settledMinor: 40000,
    owedMinor: 60000,
    entries: [
      LedgerEntry(kind: LedgerKind.cash_collected, amountMinor: 150000, tripId: 't1', createdAt: t0),
      LedgerEntry(kind: LedgerKind.commission_due, amountMinor: 15000, tripId: 't1', createdAt: t0),
      LedgerEntry(kind: LedgerKind.settlement, amountMinor: 40000, reason: 'RCPT-7', createdAt: t0),
      LedgerEntry(kind: LedgerKind.adjustment, amountMinor: 5000, sign: -1, reason: 'Fuel refund', createdAt: t0),
    ],
  );

  testWidgets('English wording is unambiguous and amounts use moneyMinor', (t) async {
    final f = Fakes();
    f.earnings.money = money;
    await pumpHome(t, const EarningsScreen(), services: f.services(lang: 'en'));
    await t.pumpAndSettle();
    for (final label in ['You collected', 'Company commission', 'Your net earnings', 'You paid the company', 'You still owe']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(moneyMinor(1000000, ar: false)), findsOneWidget);
    expect(find.text(moneyMinor(60000, ar: false)), findsOneWidget);
    for (final row in ['Cash you collected from a rider', 'Commission you owe the company', 'Payment you made to the company', 'Adjustment: reduces what you owe']) {
      await t.scrollUntilVisible(find.text(row), 200);
      expect(find.text(row), findsOneWidget, reason: row);
    }
  });

  testWidgets('nothing owed says so plainly', (t) async {
    final f = Fakes();
    f.earnings.money = const DriverMoney(collectedMinor: 0, commissionMinor: 0, earnedMinor: 0, settledMinor: 0, owedMinor: 0);
    await pumpHome(t, const EarningsScreen(), services: f.services(lang: 'en'));
    await t.pumpAndSettle();
    expect(find.text('You owe the company nothing'), findsOneWidget);
    expect(find.text('You still owe'), findsNothing);
    expect(find.text('No entries yet'), findsOneWidget);
  });

  test('Arabic labels exist for every figure', () {
    const l = EarningsLabels(S('ar'));
    expect({l.collected, l.commission, l.net, l.settled, l.owed}.length, 5);
    expect(l.owed, 'ما زلت مديناً به');
  });

  test('today summary counts only today', () {
    final start = DateTime(2026, 11, 20);
    final done = trip(state: TripState.completed, extra: {
      'timestamps': {'completed': DateTime(2026, 11, 20, 10).millisecondsSinceEpoch},
    });
    final yesterday = trip(state: TripState.completed, extra: {
      'timestamps': {'completed': DateTime(2026, 11, 19, 22).millisecondsSinceEpoch},
    });
    final s = TodaySummary.compute(trips: [done, yesterday], ledger: [
      LedgerEntry(kind: LedgerKind.cash_collected, amountMinor: 150000, createdAt: DateTime(2026, 11, 20, 10)),
      LedgerEntry(kind: LedgerKind.commission_due, amountMinor: 15000, createdAt: DateTime(2026, 11, 20, 10)),
      LedgerEntry(kind: LedgerKind.cash_collected, amountMinor: 99900, createdAt: DateTime(2026, 11, 19, 22)),
    ], startOfDay: start);
    expect(s.completedTrips, 1);
    expect(s.collectedMinor, 150000);
    expect(s.netMinor, 135000);
  });

  testWidgets('a negative balance reads as the company owing the driver', (t) async {
    final f = Fakes();
    await pumpHome(t, const Scaffold(body: EarningsView(money: DriverMoney(collectedMinor: 0, commissionMinor: 0, earnedMinor: 0, settledMinor: 0, owedMinor: -500))), services: f.services(lang: 'en'));
    expect(find.text('The company owes you'), findsOneWidget);
  });
}
