import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/trips/domain/polyline.dart';

void main() {
  test('decodes the reference Google polyline', () {
    final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.length, 3);
    expect(pts[0].lat, closeTo(38.5, 1e-6));
    expect(pts[0].lng, closeTo(-120.2, 1e-6));
    expect(pts[2].lat, closeTo(43.252, 1e-6));
    expect(pts[2].lng, closeTo(-126.453, 1e-6));
  });

  test('broken polyline falls back to null (straight estimate)', () {
    expect(routePoints(const RouteInfo(distanceMeters: 1, durationSeconds: 1, polyline: '_p~', estimated: false)), isNull);
  });

  test('remaining route starts at the driver', () {
    const route = [GeoPoint(0, 0), GeoPoint(0, 1), GeoPoint(0, 2)];
    final rest = remainingRoute(route, const GeoPoint(0, 1.1));
    expect(rest.first.lng, 1.1);
    expect(rest.length, 3);
  });
}
