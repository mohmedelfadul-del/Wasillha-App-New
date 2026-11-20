import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/app/live.dart';
import 'package:wasilha_driver/features/trip/domain/stage_action.dart';
import 'package:wasilha_driver/features/trip/presentation/active_trip_screen.dart';
import 'package:wasilha_driver/features/trip/presentation/cash_sheet.dart';

import 'fakes.dart';

void main() {
  group('stage action per trip state', () {
    const en = S('en');
    final expected = <TripState, (StageCommand?, String?)>{
      TripState.driverAssigned: (null, null),
      TripState.driverEnRoute: (StageCommand.markArrived, 'Arrived'),
      TripState.driverArrived: (StageCommand.startTrip, 'Start trip'),
      TripState.inProgress: (StageCommand.finishTrip, 'Finish'),
      TripState.arrived: (null, null),
      TripState.paymentPending: (StageCommand.recordCash, 'Record cash'),
      TripState.completed: (null, null),
      TripState.cancelled: (null, null),
    };
    expected.forEach((state, e) {
      test('$state → ${e.$1?.name}', () {
        final cmd = stageCommandFor(state);
        expect(cmd, e.$1);
        if (cmd != null) expect(stageLabel(en, cmd), e.$2);
      });
    });

    test('wire command names match the backend', () {
      expect(StageCommand.values.map((c) => c.name), ['markArrived', 'startTrip', 'finishTrip', 'recordCash']);
    });

    test('driver cancels only between assignment and pickup', () {
      expect(TripState.values.where(driverCanCancel), [TripState.driverAssigned, TripState.driverEnRoute, TripState.driverArrived]);
    });
  });

  group('ActiveTripScreen', () {
    Future<Fakes> pump(WidgetTester t, Trip tr, {String lang = 'en'}) async {
      final f = Fakes();
      f.trips.trip.add(Live(tr));
      await pumpHome(t, ActiveTripScreen(tripId: 't1', onDone: () {}), services: f.services(lang: lang));
      await t.pump();
      return f;
    }

    for (final (state, label, command) in [
      (TripState.driverEnRoute, 'Arrived', 'markArrived'),
      (TripState.driverArrived, 'Start trip', 'startTrip'),
      (TripState.inProgress, 'Finish', 'finishTrip'),
    ]) {
      testWidgets('$state: one primary button "$label" sends $command with the rendered revision', (t) async {
        final f = await pump(t, trip(state: state, revision: 7));
        expect(find.widgetWithText(PrimaryAction, label), findsOneWidget);
        expect(find.byType(PrimaryAction), findsOneWidget);
        await t.tap(find.widgetWithText(PrimaryAction, label));
        await t.pumpAndSettle();
        expect(f.trips.calls.single.command, command);
        expect(f.trips.calls.single.revision, 7);
      });
    }

    testWidgets('driverAssigned acknowledges automatically exactly once', (t) async {
      final f = await pump(t, trip(state: TripState.driverAssigned, revision: 3));
      f.trips.trip.add(Live(trip(state: TripState.driverAssigned, revision: 3), fromCache: true));
      await t.pump();
      f.trips.trip.add(Live(trip(state: TripState.driverAssigned, revision: 3)));
      await t.pump();
      expect(f.trips.calls.where((c) => c.command == 'ackAssignment').length, 1);
      expect(f.trips.calls.single.revision, 3);
      expect(find.byType(PrimaryAction), findsNothing);
      expect(find.text('Confirming the trip…'), findsWidgets);
    });

    testWidgets('failed acknowledgement shows the error and retries with the same key', (t) async {
      final f = Fakes();
      f.trips.stageFailure = const ApiFailure('permission_denied', 'no');
      f.trips.trip.add(Live(trip(state: TripState.driverAssigned, revision: 3)));
      await pumpHome(t, ActiveTripScreen(tripId: 't1', onDone: () {}), services: f.services(lang: 'en'));
      await t.pump();
      expect(find.text('Try again'), findsOneWidget);
      f.trips.stageFailure = null;
      await t.tap(find.text('Try again'));
      await t.pump();
      expect(f.trips.calls.length, 2);
      expect(f.trips.calls[0].key, f.trips.calls[1].key);
    });

    testWidgets('paymentPending: Record cash is prefilled with the fare', (t) async {
      final f = await pump(t, trip(state: TripState.paymentPending, fare: 1500));
      await t.tap(find.widgetWithText(PrimaryAction, 'Record cash'));
      await t.pumpAndSettle();
      expect(find.byType(CashSheet), findsOneWidget);
      expect(find.widgetWithText(TextField, '1500'), findsOneWidget);
      await t.tap(find.descendant(of: find.byType(CashSheet), matching: find.byType(PrimaryAction)));
      await t.pumpAndSettle();
      expect(f.trips.cash, [1500]);
    });

    testWidgets('paymentPending: a different amount asks for confirmation', (t) async {
      final f = await pump(t, trip(state: TripState.paymentPending, fare: 1500));
      await t.tap(find.widgetWithText(PrimaryAction, 'Record cash'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '1200');
      await t.tap(find.descendant(of: find.byType(CashSheet), matching: find.byType(PrimaryAction)));
      // The sheet's button spins while the dialog is open, so no pumpAndSettle.
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Amount differs from the fare'), findsOneWidget);
      expect(f.trips.cash, isEmpty);
      await t.tap(find.text('Record this amount'));
      await t.pump();
      await t.pumpAndSettle();
      expect(f.trips.cash, [1200]);
    });

    test('cash validation: whole numbers within 0..3× fare', () {
      const s = S('en');
      expect(validateCash(s, '1500', 1500), isNull);
      expect(validateCash(s, '0', 1500), isNull);
      expect(validateCash(s, '12.5', 1500), isNotNull);
      expect(validateCash(s, '', 1500), isNotNull);
      expect(validateCash(s, '4501', 1500), isNotNull);
    });

    testWidgets('navigation handoff and call use the trip data', (t) async {
      final f = await pump(t, trip(state: TripState.driverEnRoute));
      await t.tap(find.text('Directions to pickup'));
      await t.pump();
      expect(f.launcher.opened.single.toString(), contains('destination=15.5,32.5'));
      await t.tap(find.byIcon(Icons.call_outlined));
      await t.pump();
      expect(f.launcher.opened.last, Uri(scheme: 'tel', path: '+249911111111'));
    });

    testWidgets('pre-pickup cancel sends a coded reason', (t) async {
      final f = await pump(t, trip(state: TripState.driverArrived, revision: 9));
      await t.scrollUntilVisible(find.text('Cancel trip'), 200);
      await t.tap(find.text('Cancel trip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Rider didn’t show up'));
      await t.pump();
      await t.tap(find.widgetWithText(FilledButton, 'Cancel trip'));
      await t.pumpAndSettle();
      expect(f.trips.calls.single.command, 'cancelTrip:rider_no_show');
      expect(f.trips.calls.single.revision, 9);
    });

    testWidgets('no cancel once the trip started', (t) async {
      await pump(t, trip(state: TripState.inProgress));
      expect(find.text('Cancel trip'), findsNothing);
    });

    testWidgets('completed: rate the rider', (t) async {
      await pump(t, trip(state: TripState.completed, extra: {'cash': {'amount': 1500}}));
      expect(find.text('Rate the rider'), findsOneWidget);
      expect(find.widgetWithText(PrimaryAction, 'Send rating'), findsOneWidget);
    });
  });
}
