import 'dart:math' as math;

import 'package:wa3_core/wa3_core.dart';

/// Decodes a Google encoded polyline (precision 5).
List<GeoPoint> decodePolyline(String encoded) {
  final out = <GeoPoint>[];
  var index = 0, lat = 0, lng = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      if (index >= encoded.length) throw const FormatException('Truncated polyline');
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    out.add(GeoPoint(lat / 1e5, lng / 1e5));
  }
  return out;
}

/// Route points for a trip: the server polyline when present and valid,
/// otherwise null (callers draw a straight, dashed estimate).
List<GeoPoint>? routePoints(RouteInfo route) {
  final p = route.polyline;
  if (p == null || p.isEmpty) return null;
  try {
    final pts = decodePolyline(p);
    return pts.length >= 2 ? pts : null;
  } on FormatException {
    return null;
  }
}

double _d2(GeoPoint a, GeoPoint b) {
  final dx = (a.lng - b.lng) * math.cos(a.lat * math.pi / 180);
  final dy = a.lat - b.lat;
  return dx * dx + dy * dy;
}

/// The part of [route] still ahead of [position] (from the nearest vertex on).
List<GeoPoint> remainingRoute(List<GeoPoint> route, GeoPoint position) {
  if (route.length < 2) return route;
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < route.length; i++) {
    final d = _d2(route[i], position);
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return [position, ...route.sublist(best)];
}
