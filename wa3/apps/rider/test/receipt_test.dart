import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/receipt/presentation/receipt_view.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('payment pending shows the cash amount and no rating yet', (tester) async {
    await pumpRider(tester, ReceiptView(trip: makeTrip(state: TripState.paymentPending, driverId: 'drv-1', fare: 2350)));
    expect(find.text('Pay the driver in cash'), findsOneWidget);
    expect(find.text(money(2350, ar: false)), findsOneWidget);
    expect(find.text('Send rating'), findsNothing);
    expect(find.text('Report a problem with this trip'), findsNothing);
  });

  testWidgets('completed: rating needs stars, then sends rateTrip', (tester) async {
    final d = FakeDeps();
    await pumpRider(tester, ReceiptView(trip: makeTrip(state: TripState.completed, driverId: 'drv-1', fare: 2350)), deps: d);
    final send = find.widgetWithText(FilledButton, 'Send rating');
    await scrollTo(tester, send);
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.byTooltip('4 of 5'));
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    expect(d.trips.args['rateTrip'], {'stars': 4, 'comment': null});
  });

  testWidgets('dispute is offered within 48 h and sends the revision', (tester) async {
    final d = FakeDeps();
    final done = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
    await pumpRider(
      tester,
      ReceiptView(trip: makeTrip(state: TripState.completed, driverId: 'drv-1', fare: 2350, revision: 9, timestamps: {'completed': done})),
      deps: d,
    );
    final open = find.text('Report a problem with this trip');
    await scrollTo(tester, open);
    await tester.tap(open);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.widgetWithText(TextField, 'What went wrong?'), 'I was charged more than agreed');
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, 'Send').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(d.trips.args['disputeTrip'], {'reason': 'I was charged more than agreed', 'revision': 9});
  });

  testWidgets('dispute window closed after 48 h is stated, not offered', (tester) async {
    final done = DateTime.now().subtract(const Duration(hours: 50)).millisecondsSinceEpoch;
    await pumpRider(tester, ReceiptView(trip: makeTrip(state: TripState.completed, driverId: 'drv-1', fare: 2350, timestamps: {'completed': done})));
    await scrollTo(tester, find.textContaining('48-hour window'));
    expect(find.text('Report a problem with this trip'), findsNothing);
  });
}
