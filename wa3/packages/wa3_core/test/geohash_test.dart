import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';

/// Expected values produced by geofire-common (the server's library).
void main() {
  test('matches the server geohash', () {
    expect(geohashEncode(15.5776, 32.5634), 'sdz0sgzfn5');
    expect(geohashEncode(-33.8688, 151.2093), 'r3gx2f77bn');
    expect(geohashEncode(51.5074, -0.1278), 'gcpvj0duq5');
  });
}
