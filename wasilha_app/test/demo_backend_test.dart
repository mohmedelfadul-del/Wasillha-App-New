import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha/data/catalog.dart';
import 'package:wasilha/data/demo_backend.dart';
import 'package:wasilha/data/geo_api.dart';
import 'package:wasilha/data/models.dart';

/// Exercises the rider ↔ driver loop against the in-memory backend
/// (the same contract FirebaseBackend implements).
void main() {
  test('rider requests, drivers bid, rider accepts, trip completes and wallet is charged', () async {
    final b = DemoBackend();
    await b.sendCode('+249912345678');
    await b.verifyCode('123456');
    final before = (await b.profile().first)!.balance;

    final dropoff = Catalog.places.firstWhere((p) => p.id == 'afra');
    final fare = ServiceType.raksha.fareFor(Catalog.defaultPickup.kmTo(dropoff));
    final id = await b.requestTrip(
      service: ServiceType.raksha,
      pickup: Catalog.defaultPickup,
      dropoff: dropoff,
      offeredFare: fare,
    );

    final bids = await b.watchBids(id).firstWhere((l) => l.isNotEmpty).timeout(const Duration(seconds: 10));
    await b.acceptBid(id, bids.first);
    final accepted = await b.watchTrip(id).first;
    expect(accepted!.status, TripStatus.accepted);
    expect(accepted.driverName, bids.first.driverName);

    await b.completeAndRate(id, stars: 5, tip: 500);
    final done = await b.watchTrip(id).first;
    expect(done!.status, TripStatus.completed);
    expect(done.rating, 5);
    final after = (await b.profile().first)!.balance;
    expect(before - after, bids.first.amount + 500);
  });

  test('fares scale with distance and round to 50 SDG', () {
    expect(ServiceType.car.fareFor(0), ServiceType.car.base);
    expect(ServiceType.car.fareFor(5) % 50, 0);
    expect(ServiceType.car.fareFor(10), greaterThan(ServiceType.raksha.fareFor(10)));
  });

  test('food order is rejected without enough balance', () async {
    final b = DemoBackend();
    await b.sendCode('+249912345678');
    await b.verifyCode('123456');
    final r = Catalog.restaurants.first;
    expect(
      () => b.placeFoodOrder(restaurant: r, lines: const [], total: 10000000),
      throwsA(anything),
    );
  });

  test('decodes Google encoded polylines', () {
    // Example from Google's polyline docs.
    final pts = GeoApi.decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.length, 3);
    expect(pts[0].$1, closeTo(38.5, 1e-5));
    expect(pts[0].$2, closeTo(-120.2, 1e-5));
    expect(pts[2].$1, closeTo(43.252, 1e-5));
  });

  test('chat: demo driver replies to the rider', () async {
    final b = DemoBackend();
    await b.sendCode('+249912345678');
    await b.verifyCode('123456');
    final id = await b.requestTrip(
      service: ServiceType.car,
      pickup: Catalog.defaultPickup,
      dropoff: Catalog.places[1],
      offeredFare: 2000,
    );
    final bids = await b.watchBids(id).firstWhere((l) => l.isNotEmpty).timeout(const Duration(seconds: 10));
    await b.acceptBid(id, bids.first);
    await b.sendMessage(id, 'Where are you?');
    final msgs = await b.chat(id).firstWhere((m) => m.length >= 2).timeout(const Duration(seconds: 6));
    expect(msgs.first.senderId, 'demo-user');
    expect(msgs[1].senderId, bids.first.driverId);
    await b.cancelTrip(id);
  });
}
