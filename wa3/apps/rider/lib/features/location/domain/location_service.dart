import 'package:wa3_core/wa3_core.dart';

enum LocationStatus { granted, denied, deniedForever, serviceOff, unavailable }

class LocationResult {
  const LocationResult(this.status, [this.point]);
  final LocationStatus status;
  final GeoPoint? point;
  bool get ok => status == LocationStatus.granted && point != null;
}

abstract class LocationService {
  /// Checks (and, when [request] is true, asks for) permission, then reads one fix.
  Future<LocationResult> locate({bool request = true});
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}
