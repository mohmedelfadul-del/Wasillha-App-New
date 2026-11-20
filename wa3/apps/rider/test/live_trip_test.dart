import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/live_trip/presentation/live_trip_view.dart';

import 'support/fakes.dart';

void main() {
  Trip trip() => makeTrip(state: TripState.driverEnRoute, driverId: 'drv-1', fare: 2000);

  testWidgets('fresh driver location: no stale warning; header shows driver, vehicle and plate', (tester) async {
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(DriverPosition(point: const GeoPoint(15.595, 32.535), updatedAt: DateTime.now().subtract(const Duration(seconds: 5))));
    await pumpRider(tester, LiveTripView(trip: trip()), deps: d);
    await tester.pump();

    expect(find.text('Osman Ali'), findsOneWidget);
    expect(find.textContaining('KH 1234'), findsOneWidget);
    expect(find.text('Driver on the way'), findsWidgets);
    expect(find.textContaining('out of date'), findsNothing);
    expect(find.text('Call driver'), findsOneWidget);
    expect(find.text('Share trip'), findsOneWidget);
    expect(find.text('Cancel trip'), findsOneWidget);
    expect(d.maps.last.pins.any((p) => p.id == 'driver'), isTrue);
  });

  testWidgets('driver location older than 30 s shows the stale banner', (tester) async {
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(DriverPosition(point: const GeoPoint(15.595, 32.535), updatedAt: DateTime.now().subtract(const Duration(seconds: 75))));
    await pumpRider(tester, LiveTripView(trip: trip()), deps: d);
    await tester.pump();

    expect(find.textContaining('Driver location is out of date'), findsOneWidget);
  });

  testWidgets('location turns stale while watching', (tester) async {
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(DriverPosition(point: const GeoPoint(15.595, 32.535), updatedAt: DateTime.now().subtract(const Duration(milliseconds: 29500))));
    await pumpRider(tester, LiveTripView(trip: trip()), deps: d);
    await tester.pump();
    expect(find.textContaining('out of date'), findsNothing);

    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1600)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Driver location is out of date'), findsOneWidget);
  });

  testWidgets('no position yet says the location is unavailable', (tester) async {
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(null);
    await pumpRider(tester, LiveTripView(trip: trip()), deps: d);
    await tester.pump();
    expect(find.text('The driver’s location isn’t available right now.'), findsOneWidget);
  });

  testWidgets('after pickup there is no cancel; safety report needs a description and confirmation', (tester) async {
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(DriverPosition(point: const GeoPoint(15.6, 32.54), updatedAt: DateTime.now()));
    await pumpRider(tester, LiveTripView(trip: makeTrip(state: TripState.inProgress, driverId: 'drv-1')), deps: d);
    await tester.pump();
    expect(find.text('Cancel trip'), findsNothing);

    await tester.tap(find.text('Safety'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Send report'));
    await tester.pump();
    expect(find.textContaining('at least 5 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Driver is speeding');
    await tester.tap(find.text('Send report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Send safety report?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(d.trips.args['reportSafety'], {'description': 'Driver is speeding'});
    expect(find.textContaining('Report sent'), findsOneWidget);
  });
}
