import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';

void main() {
  test('money is bidi-isolated whole units', () {
    expect(money(1850, ar: true), '\u20661,850\u2069 ج.س');
    expect(money(1234567, ar: false), '\u20661,234,567\u2069 SDG');
    expect(moneyMinor(185000, ar: false), '\u20661,850\u2069 SDG');
  });
  test('distance and time', () {
    expect(km(5200, ar: false), '\u20665.2\u2069 km');
    expect(km(12400, ar: true), '\u206612\u2069 كم');
    expect(minutes(30, ar: false), '\u20661\u2069 min');
  });
  test('location staleness uses the 30 s threshold', () {
    final now = DateTime(2026, 1, 1, 12);
    final p = DriverPosition(point: const GeoPoint(15.5, 32.5), updatedAt: now.subtract(const Duration(seconds: 31)));
    expect(p.isStale(now), isTrue);
    expect(DriverPosition(point: const GeoPoint(15.5, 32.5), updatedAt: now.subtract(const Duration(seconds: 29))).isStale(now), isFalse);
  });
  test('trip state helpers', () {
    expect(TripState.offering.isOpenRequest, isTrue);
    expect(TripState.driverArrived.isPrePickup, isTrue);
    expect(TripState.inProgress.isPrePickup, isFalse);
    expect(TripState.paymentPending.hasDriver, isTrue);
  });
  test('coalescer: one read in flight, at most one pending', () async {
    var reads = 0;
    final c = RefreshCoalescer(() async {
      reads++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    for (var i = 0; i < 10; i++) {
      c.signal();
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(reads, 2);
  });
}
