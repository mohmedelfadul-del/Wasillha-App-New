import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha/data/catalog.dart';
import 'package:wasilha/data/demo_backend.dart';
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
}
