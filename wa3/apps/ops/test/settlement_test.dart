import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha_ops/features/finance/domain/settlement_validation.dart';
import 'package:wasilha_ops/features/finance/presentation/settlement_form.dart';

import 'support/harness.dart';

void main() {
  group('validateSettlementAmount', () {
    test('rejects amounts above what is owed', () {
      expect(validateSettlementAmount('51', 5000), SettlementError.overOwed);
      expect(validateSettlementAmount('50', 5000), isNull);
      expect(validateSettlementAmount('1', 5000), isNull);
    });
    test('requires a whole positive amount', () {
      expect(validateSettlementAmount('', 5000), SettlementError.required);
      expect(validateSettlementAmount('12.5', 5000), SettlementError.wholeNumber);
      expect(validateSettlementAmount('-3', 5000), SettlementError.wholeNumber);
      expect(validateSettlementAmount('0', 5000), SettlementError.tooSmall);
      expect(validateSettlementAmount('1,000', 200000), isNull);
    });
    test('nothing owed means nothing to settle', () {
      expect(validateSettlementAmount('10', 0), SettlementError.nothingOwed);
      expect(maxSettleUnits(5000), 50);
    });
  });

  testWidgets('over-owed amount is blocked before any confirmation or call', (tester) async {
    final submitted = <String>[];
    await pumpWidgetIn(
      tester,
      SingleChildScrollView(child: SettlementForm(owedMinor: 5000, driverName: 'Osman', onSubmit: (a, r) async => submitted.add('$a $r'))),
    );
    await tester.enterText(find.byKey(const Key('settle-amount')), '60');
    await tester.enterText(find.byKey(const Key('settle-reference')), 'RCPT-1');
    await tester.tap(find.byKey(const Key('settle-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('More than is owed'), findsOneWidget);
    expect(find.text('Record settlement?'), findsNothing);
    expect(submitted, isEmpty);
  });

  testWidgets('missing receipt reference is blocked', (tester) async {
    final submitted = <String>[];
    await pumpWidgetIn(tester, SingleChildScrollView(child: SettlementForm(owedMinor: 5000, driverName: 'Osman', onSubmit: (a, r) async => submitted.add('$a'))));
    await tester.enterText(find.byKey(const Key('settle-amount')), '20');
    await tester.tap(find.byKey(const Key('settle-submit')));
    await tester.pumpAndSettle();
    expect(find.text('A receipt reference is required'), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('valid settlement asks for confirmation, then records', (tester) async {
    final submitted = <String>[];
    await pumpWidgetIn(tester, SingleChildScrollView(child: SettlementForm(owedMinor: 5000, driverName: 'Osman', onSubmit: (a, r) async => submitted.add('$a $r'))));
    await tester.enterText(find.byKey(const Key('settle-amount')), '50');
    await tester.enterText(find.byKey(const Key('settle-reference')), 'RCPT-9');
    await tester.tap(find.byKey(const Key('settle-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Record settlement?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Record'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(submitted, ['50 RCPT-9']);
  });
}
