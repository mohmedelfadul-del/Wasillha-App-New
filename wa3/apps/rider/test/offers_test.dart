import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/common/domain/live.dart';
import 'package:wasilha_rider/features/offers/presentation/offers_view.dart';
import 'package:wasilha_rider/features/trip/presentation/trip_screen.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('no offers yet: calm waiting state with request expiry and cancel', (tester) async {
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(const Live(<Offer>[]));
    await pumpRider(tester, OffersView(trip: makeTrip()), deps: d);
    await tester.pump();

    expect(find.text('Finding drivers near you'), findsOneWidget);
    expect(find.textContaining('Request stays open for'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
    expect(find.textContaining('Accept'), findsNothing);
  });

  testWidgets('live offers are listed cheapest first and accept sends the rendered revision', (tester) async {
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(Live([
      makeOffer('drv-b', price: 2400, name: 'Badr'),
      makeOffer('drv-a', price: 1900, name: 'Amir'),
    ]));
    await pumpRider(tester, OffersView(trip: makeTrip(revision: 5)), deps: d);
    await tester.pump();

    expect(find.text('Finding drivers near you'), findsNothing);
    expect(find.textContaining('offers'), findsOneWidget);
    expect(find.text('Amir'), findsOneWidget);
    expect(find.text('Badr'), findsOneWidget);
    expect(find.textContaining('Offer expires in'), findsNWidgets(2));
    // Cheapest first.
    expect(tester.getTopLeft(find.text('Amir')).dy, lessThan(tester.getTopLeft(find.text('Badr')).dy));

    await tester.tap(find.widgetWithText(FilledButton, 'Accept ${money(1900, ar: false)}'));
    await tester.pump();
    expect(d.trips.calls, ['acceptOffer']);
    expect(d.trips.args['acceptOffer'], {'tripId': 'trip-1', 'offerId': 'drv-a', 'revision': 5});
  });

  testWidgets('expired and inactive offers are not shown', (tester) async {
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(Live([
      makeOffer('old', price: 1800, name: 'Expired Driver', expiresIn: const Duration(seconds: -5)),
      makeOffer('gone', price: 1700, name: 'Withdrawn Driver', status: OfferStatus.withdrawn),
    ]));
    await pumpRider(tester, OffersView(trip: makeTrip()), deps: d);
    await tester.pump();

    expect(find.text('Expired Driver'), findsNothing);
    expect(find.text('Withdrawn Driver'), findsNothing);
    expect(find.text('Finding drivers near you'), findsOneWidget);
  });

  testWidgets('an offer disappears when its countdown runs out', (tester) async {
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(Live([makeOffer('soon', price: 2000, name: 'Soon Gone', expiresIn: const Duration(milliseconds: 1500))]));
    await pumpRider(tester, OffersView(trip: makeTrip()), deps: d);
    await tester.pump();
    expect(find.text('Soon Gone'), findsOneWidget);

    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1600)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Soon Gone'), findsNothing);
    expect(find.text('Finding drivers near you'), findsOneWidget);
  });

  testWidgets('cancel asks for a reason, then calls cancelTrip', (tester) async {
    final d = FakeDeps();
    d.trips.offersOf('trip-1').add(const Live(<Offer>[]));
    await pumpRider(tester, OffersView(trip: makeTrip(revision: 4)), deps: d);
    await tester.pump();

    await tester.tap(find.text('Cancel request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Cancel this request?'), findsOneWidget);
    await tester.tap(find.text('Driver is too far'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(d.trips.args['cancelTrip'], {'tripId': 'trip-1', 'reason': 'driver_too_far', 'revision': 4});
  });

  testWidgets('cancelled with no_offers says so and retries with the same details', (tester) async {
    final d = FakeDeps();
    d.trips.trip('trip-1').add(Live(makeTrip(state: TripState.cancelled, cancelReason: 'no_offers', proposedFare: 2100)));
    await pumpRider(tester, const TripScreen(tripId: 'trip-1'), deps: d);
    await tester.pump();

    expect(find.text('No driver accepted your request in time'), findsOneWidget);
    await tester.tap(find.text('Request again'));
    await tester.pump();
    await tester.pump();

    expect(d.trips.calls, ['createDraft', 'confirmRequest']);
    expect(d.trips.args['createDraft'], {'category': 'economy', 'pickup': 'Riyadh, Khartoum', 'dropoff': 'Airport Road'});
    expect(d.trips.args['confirmRequest'], {'tripId': 'trip-new', 'fare': 2100, 'revision': 1});
  });
}
