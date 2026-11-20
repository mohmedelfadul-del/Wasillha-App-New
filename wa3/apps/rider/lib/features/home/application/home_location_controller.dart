import 'package:flutter/foundation.dart';

import '../../location/domain/location_service.dart';

/// The rider's position for the home map and the default pickup.
class HomeLocationController extends ChangeNotifier {
  HomeLocationController(this._location);
  final LocationService _location;

  LocationResult? result;
  bool locating = false;

  /// Increments on every successful fix so the map re-centres.
  int fixes = 0;
  bool _disposed = false;

  Future<void> locate({bool request = true}) async {
    if (locating) return;
    locating = true;
    _notify();
    final r = await _location.locate(request: request);
    locating = false;
    // Keep a known position if a later attempt fails.
    if (r.ok) {
      result = r;
      fixes++;
    } else if (!(result?.ok ?? false)) {
      result = r;
    }
    _notify();
  }

  Future<void> openSettings() =>
      result?.status == LocationStatus.serviceOff ? _location.openLocationSettings() : _location.openAppSettings();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
