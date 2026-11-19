import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../data/catalog.dart';
import '../data/models.dart';

/// Device location helpers (permission-aware; every call fails soft).
class LocationService {
  LocationService._();

  /// Asks for permission if needed. Returns false when location is unavailable.
  static Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      return p == LocationPermission.always || p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// The user's position as a pickup [Place], labelled with the nearest
  /// known area ("Current location · near Riyadh District").
  static Future<Place?> currentPlace() async {
    if (!await ensurePermission()) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      final near = nearestKnown(pos.latitude, pos.longitude);
      return Place(
        id: 'gps',
        name: 'Current location',
        nameAr: 'موقعك الحالي',
        area: near?.name ?? '',
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  /// Closest catalog place within 5 km, used as a human-readable area name.
  static Place? nearestKnown(double lat, double lng) {
    Place? best;
    var bestKm = 5.0;
    for (final p in Catalog.places) {
      final d = haversineKm(lat, lng, p.lat, p.lng);
      if (d < bestKm) {
        bestKm = d;
        best = p;
      }
    }
    return best;
  }

  /// Position updates every ~20 m while a trip is active (driver app).
  static Stream<Position> track() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20),
      );
}
