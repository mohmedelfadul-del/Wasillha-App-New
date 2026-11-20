import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/location_port.dart';

class GeolocatorSource implements LocationSource {
  LocationAccess _map(LocationPermission p) => switch (p) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };

  @override
  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    final now = await Geolocator.checkPermission();
    if (now == LocationPermission.deniedForever) return LocationAccess.deniedForever;
    if (_map(now) == LocationAccess.granted) return LocationAccess.granted;
    return _map(await Geolocator.requestPermission());
  }

  @override
  Stream<Fix> fixes() {
    final LocationSettings settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 5, intervalDuration: const Duration(seconds: 3))
        : defaultTargetPlatform == TargetPlatform.iOS
            ? AppleSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5, pauseLocationUpdatesAutomatically: false, activityType: ActivityType.automotiveNavigation)
            : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
    return Geolocator.getPositionStream(locationSettings: settings).map((p) => Fix(
          lat: p.latitude,
          lng: p.longitude,
          at: p.timestamp,
          heading: p.heading >= 0 ? p.heading : null,
          speed: p.speed >= 0 ? p.speed : null,
          accuracy: p.accuracy,
        ));
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
