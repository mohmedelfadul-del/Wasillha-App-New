import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/common/domain/live.dart';
import 'package:wasilha_rider/features/home/presentation/home_screen.dart';
import 'package:wasilha_rider/features/live_trip/presentation/live_trip_view.dart';
import 'package:wasilha_rider/features/location/domain/location_service.dart';
import 'package:wasilha_rider/features/offers/presentation/offers_view.dart';
import 'package:wasilha_rider/features/receipt/presentation/receipt_view.dart';
import 'package:wasilha_rider/features/request/presentation/request_screen.dart';

import 'support/fakes.dart';

/// Arabic (RTL), 320×640, 200 % text: no overflow or other exceptions.
void main() {
  testWidgets('home with location denied', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps()..location.result = const LocationResult(LocationStatus.denied);
    await pumpRider(tester, const HomeScreen(), deps: d, lang: 'ar');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(Directionality.of(tester.element(find.byType(HomeScreen))), TextDirection.rtl);
    expect(find.text('إلى أين؟'), findsOneWidget);
    expect(find.textContaining('لم تسمح بالوصول إلى موقعك'), findsOneWidget);
  });

  testWidgets('home with an active trip card', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps();
    d.trips.active.add(Live([makeTrip(state: TripState.driverEnRoute, driverId: 'drv-1')]));
    await pumpRider(tester, const HomeScreen(), deps: d, lang: 'ar');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('رحلتك الحالية'), findsOneWidget);
    expect(find.text('إلى أين؟'), findsNothing);
  });

  testWidgets('offers waiting state', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(const Live(<Offer>[]));
    await pumpRider(tester, OffersView(trip: makeTrip()), deps: d, lang: 'ar');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('نبحث عن سائقين قريبين'), findsOneWidget);
  });

  testWidgets('offers list', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(Live([
      makeOffer('a', price: 1900, name: 'عثمان عبد الرحمن محمد'),
      makeOffer('b', price: 2450, name: 'بدر'),
    ]));
    await pumpRider(tester, OffersView(trip: makeTrip()), deps: d, lang: 'ar');
    await tester.pump();

    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.text('عثمان عبد الرحمن محمد'));
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.text('بدر'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('live trip with stale location', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps();
    d.trips.presenceOf('drv-1').add(DriverPosition(point: const GeoPoint(15.6, 32.54), updatedAt: DateTime.now().subtract(const Duration(minutes: 2))));
    await pumpRider(tester, LiveTripView(trip: makeTrip(state: TripState.driverEnRoute, driverId: 'drv-1')), deps: d, lang: 'ar');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('موقع السائق قديم'), findsOneWidget);
  });

  testWidgets('request flow with server price', (tester) async {
    smallScreenLargeText(tester);
    final d = FakeDeps();
    await pumpRider(
      tester,
      const RequestScreen(pickup: Place(point: GeoPoint(15.59, 32.53), label: 'الرياض'), dropoff: Place(point: GeoPoint(15.61, 32.55), label: 'شارع المطار')),
      deps: d,
      lang: 'ar',
    );
    await scrollTo(tester, find.text('عائلي'));
    await tester.tap(find.text('عائلي'));
    await tester.pump();
    await tester.pump();
    await scrollTo(tester, find.byKey(const Key('fare-field')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('receipt: cash due and completed with rating', (tester) async {
    smallScreenLargeText(tester);
    await pumpRider(tester, ReceiptView(trip: makeTrip(state: TripState.paymentPending, driverId: 'drv-1', fare: 2350)), lang: 'ar');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('ادفع للسائق نقداً'), findsOneWidget);

    await pumpRider(tester, ReceiptView(trip: makeTrip(state: TripState.completed, driverId: 'drv-1', fare: 2350)), lang: 'ar');
    await tester.pump();
    await scrollTo(tester, find.text('أرسل التقييم'));
    expect(tester.takeException(), isNull);
  });
}
