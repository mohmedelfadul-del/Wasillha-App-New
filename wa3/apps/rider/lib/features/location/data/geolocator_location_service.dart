import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/location_service.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> locate({bool request = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationResult(LocationStatus.serviceOff);
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied && request) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever) return const LocationResult(LocationStatus.deniedForever);
      if (p == LocationPermission.denied || p == LocationPermission.unableToDetermine) {
        return const LocationResult(LocationStatus.denied);
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
        );
        return LocationResult(LocationStatus.granted, GeoPoint(pos.latitude, pos.longitude));
      } on TimeoutException {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return const LocationResult(LocationStatus.unavailable);
        return LocationResult(LocationStatus.granted, GeoPoint(last.latitude, last.longitude));
      }
    } on PermissionDeniedException {
      return const LocationResult(LocationStatus.denied);
    } on LocationServiceDisabledException {
      return const LocationResult(LocationStatus.serviceOff);
    } catch (_) {
      return const LocationResult(LocationStatus.unavailable);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
