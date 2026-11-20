import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/app/home_shell.dart';
import 'package:wasilha_driver/app/live.dart';
import 'package:wasilha_driver/features/account/domain/driver_repository.dart';
import 'package:wasilha_driver/features/availability/application/availability_controller.dart';
import 'package:wasilha_driver/features/availability/presentation/availability_screen.dart';
import 'package:wasilha_driver/features/location/domain/location_port.dart';
import 'package:wasilha_driver/features/trip/presentation/active_trip_screen.dart';

import 'fakes.dart';

Future<(Fakes, AvailabilityController)> pumpAvailability(WidgetTester t, DriverState d, {String lang = 'en', Size? size, double textScale = 1, LocationAccess access = LocationAccess.granted}) async {
  final f = Fakes();
  f.locationSource.access = access;
  final c = AvailabilityController(uid: 'd1', driverRepo: f.driver, location: f.location);
  addTearDown(c.dispose);
  await pumpHome(t, AvailabilityScreen(live: Live(d), controller: c), services: f.services(lang: lang), size: size, textScale: textScale);
  await t.pump();
  return (f, c);
}

void main() {
  testWidgets('approved, vehicle chosen, offline → one large Go online action', (t) async {
    await pumpAvailability(t, driverState());
    expect(find.text('Offline'), findsOneWidget);
    expect(find.widgetWithText(PrimaryAction, 'Go online'), findsOneWidget);
    expect(find.text('Completed trips'), findsOneWidget);
  });

  testWidgets('not approved → no toggle; explains that submitting does not grant work', (t) async {
    await pumpAvailability(t, driverState(status: DriverStatus.underReview));
    expect(find.widgetWithText(PrimaryAction, 'Go online'), findsNothing);
    expect(find.textContaining('can’t go online until your account is approved'), findsOneWidget);
    expect(find.widgetWithText(PrimaryAction, 'View documents'), findsOneWidget);
  });

  testWidgets('no active vehicle → choose a vehicle', (t) async {
    await pumpAvailability(t, driverState(vehicle: null));
    expect(find.widgetWithText(PrimaryAction, 'Choose a vehicle'), findsOneWidget);
  });

  testWidgets('permission permanently denied → honest state, settings action', (t) async {
    await pumpAvailability(t, driverState(), access: LocationAccess.deniedForever);
    expect(find.widgetWithText(PrimaryAction, 'Go online'), findsNothing);
    expect(find.widgetWithText(PrimaryAction, 'Open settings'), findsOneWidget);
  });

  testWidgets('server outside_zone is shown precisely', (t) async {
    final (f, _) = await pumpAvailability(t, driverState());
    f.driver.goOnlineFailure = const ApiFailure('outside_zone', 'You are outside the operating area');
    await t.tap(find.widgetWithText(PrimaryAction, 'Go online'));
    await t.pump();
    f.locationSource.fixesCtl.add(Fix(lat: 15.5, lng: 32.5, at: DateTime.now()));
    await t.pump();
    await t.pump();
    expect(f.sink.writes, isNotEmpty, reason: 'presence is written before goOnline');
    expect(f.driver.goOnlineCalls, 1);
    expect(find.textContaining('outside the operating area. Drive into the service area'), findsOneWidget);
    expect(f.location.running, isFalse, reason: 'GPS stops again when going online failed');
  });

  testWidgets('location_lost is explained', (t) async {
    await pumpAvailability(t, driverState(offlineReason: 'location_lost'));
    expect(find.textContaining('taken offline because your location stopped reaching us'), findsOneWidget);
  });

  testWidgets('online → requests section and Go offline', (t) async {
    final (f, _) = await pumpAvailability(t, driverState(online: true));
    f.requests.inbox.add(Live([requestCard()]));
    await t.pump();
    expect(find.widgetWithText(PrimaryAction, 'Go offline'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Nearby requests'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Nearby requests'), findsOneWidget);
  });

  testWidgets('activeTripId set → the active trip opens automatically', (t) async {
    final f = Fakes();
    f.trips.trip.add(Live(trip(state: TripState.driverEnRoute)));
    final host = ValueNotifier(Live(driverState(online: true)));
    await pumpHome(
      t,
      ValueListenableBuilder<Live<DriverState>>(valueListenable: host, builder: (_, l, _) => HomeShell(live: l)),
      services: f.services(lang: 'en'),
    );
    await t.pump();
    expect(find.byType(ActiveTripScreen), findsNothing);
    host.value = Live(driverState(online: true, trip: 't1'));
    await t.pump();
    await t.pump();
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(find.widgetWithText(PrimaryAction, 'Arrived'), findsOneWidget);
  });

  group('RTL 320×640 at 200 % text — no overflow', () {
    const size = Size(320, 640);
    for (final (name, d, access) in [
      ('offline approved', driverState(), LocationAccess.granted),
      ('online', driverState(online: true), LocationAccess.granted),
      ('onboarding', driverState(status: DriverStatus.onboarding), LocationAccess.granted),
      ('suspended', driverState(status: DriverStatus.suspended), LocationAccess.granted),
      ('permission denied', driverState(), LocationAccess.denied),
      ('location lost', driverState(offlineReason: 'location_lost'), LocationAccess.granted),
    ]) {
      testWidgets('availability: $name', (t) async {
        final (f, _) = await pumpAvailability(t, d, lang: 'ar', size: size, textScale: 2.0, access: access);
        f.requests.inbox.add(Live([requestCard()]));
        await t.pump();
        expect(t.takeException(), isNull);
        expect(Directionality.of(t.element(find.byType(AvailabilityScreen))), TextDirection.rtl);
        // Scroll through the whole screen so every part is laid out.
        await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }

    for (final state in [TripState.driverAssigned, TripState.driverEnRoute, TripState.driverArrived, TripState.inProgress, TripState.paymentPending, TripState.completed, TripState.cancelled]) {
      testWidgets('active trip: ${state.name}', (t) async {
        final f = Fakes();
        f.trips.trip.add(Live(trip(state: state, extra: {
          if (state == TripState.cancelled) 'cancellation': {'actor': 'rider', 'reason': 'change_of_plans', 'at': 1},
        })));
        await pumpHome(t, ActiveTripScreen(tripId: 't1', onDone: () {}), services: f.services(lang: 'ar'), size: size, textScale: 2.0);
        await t.pump();
        expect(t.takeException(), isNull);
        expect(Directionality.of(t.element(find.byType(ActiveTripScreen))), TextDirection.rtl);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }
  });
}
