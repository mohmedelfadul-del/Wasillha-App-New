import 'dart:math';

import 'package:wa3_core/wa3_core.dart';

import 'location_port.dart';

/// When to write presence: about every 5 s while moving, and a heartbeat
/// every 15 s while stationary (brief rule 4). Pure, so it is unit-tested.
class CadencePolicy {
  const CadencePolicy({
    this.movingInterval = const Duration(seconds: Tunables.locationMovingSeconds),
    this.heartbeatInterval = const Duration(seconds: Tunables.locationHeartbeatSeconds),
    this.movingSpeed = 1.0,
    this.movingDistanceMeters = 10,
  });
  final Duration movingInterval;
  final Duration heartbeatInterval;

  /// m/s above which the driver counts as moving.
  final double movingSpeed;

  /// Displacement since the last write that counts as moving.
  final double movingDistanceMeters;

  /// Moving needs a reading newer than the last write; re-sending an old
  /// reading is a heartbeat whatever speed it reported.
  bool isMoving(Fix fix, {Fix? lastSent}) {
    if (lastSent != null && !fix.at.isAfter(lastSent.at)) return false;
    if ((fix.speed ?? 0) >= movingSpeed) return true;
    return lastSent != null && distanceMeters(lastSent, fix) >= movingDistanceMeters;
  }

  Duration intervalFor(Fix fix, {Fix? lastSent}) => isMoving(fix, lastSent: lastSent) ? movingInterval : heartbeatInterval;

  /// [lastSentAt] is when the previous write happened (null = never).
  bool shouldSend({required DateTime now, required Fix fix, Fix? lastSent, DateTime? lastSentAt}) {
    if (lastSentAt == null) return true;
    return now.difference(lastSentAt) >= intervalFor(fix, lastSent: lastSent);
  }
}

/// Great-circle distance in meters.
double distanceMeters(Fix a, Fix b) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  final h = sin(dLat / 2) * sin(dLat / 2) + cos(rad(a.lat)) * cos(rad(b.lat)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * r * asin(min(1, sqrt(h)));
}
