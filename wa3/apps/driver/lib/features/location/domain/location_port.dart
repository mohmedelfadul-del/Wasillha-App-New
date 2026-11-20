/// One GPS reading.
class Fix {
  const Fix({required this.lat, required this.lng, required this.at, this.heading, this.speed, this.accuracy});
  final double lat, lng;
  final DateTime at;
  final double? heading;

  /// Meters per second.
  final double? speed;

  /// Meters.
  final double? accuracy;
}

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

abstract class LocationSource {
  /// Current state without prompting.
  Future<LocationAccess> check();

  /// Prompts for when-in-use permission if it can still be asked.
  Future<LocationAccess> request();
  Stream<Fix> fixes();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

/// Writes presence/{uid}. The only client-side Firestore write in the system.
abstract class PresenceSink {
  Future<void> write(String uid, Fix fix);
}
