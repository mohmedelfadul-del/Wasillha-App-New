import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../account/domain/driver_repository.dart';
import '../../location/application/location_service.dart';
import '../../location/domain/location_port.dart';

/// Why going online didn't work, as precisely as we know it.
enum OnlineBlock { permission, noFix, server }

/// Owns going online/offline and keeps the location service running exactly
/// while the driver is online or has an active trip.
class AvailabilityController extends ChangeNotifier {
  AvailabilityController({required this.uid, required this.driverRepo, required this.location, DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    location.addListener(_onLocation);
    unawaited(location.refreshAccess().catchError((_) => LocationAccess.denied));
  }
  final String uid;
  final DriverRepository driverRepo;
  final LocationService location;
  final DateTime Function() _clock;

  /// After goOnline succeeds, keep GPS running until the snapshot catches up.
  DateTime? _expectOnlineUntil;

  DriverState? driver;
  bool busy = false;
  OnlineBlock? block;
  ApiFailure? failure;

  bool get _wantsLocation =>
      (driver?.profile.online ?? false) || (driver?.hasTrip ?? false) || (_expectOnlineUntil?.isAfter(_clock()) ?? false);

  /// Permission granted from elsewhere (e.g. the trip screen) → start GPS.
  void _onLocation() {
    _reconcile();
    notifyListeners();
  }

  /// Called with every drivers/{uid} snapshot.
  void onDriver(DriverState? d) {
    driver = d;
    if (d?.profile.online ?? false) _expectOnlineUntil = null;
    _reconcile();
  }

  void _reconcile() {
    if (busy) return;
    if (_wantsLocation && !location.running && location.access == LocationAccess.granted) {
      location.start(uid);
    } else if (!_wantsLocation && location.running) {
      location.stop();
    }
  }

  Future<LocationAccess> allowLocation() async {
    final a = await location.requestAccess();
    if (a == LocationAccess.granted) {
      block = null;
      _reconcile();
    }
    notifyListeners();
    return a;
  }

  /// Permission → GPS running → first presence write → goOnline (server
  /// checks approval, vehicle, fresh GPS and zone).
  Future<void> goOnline() async {
    if (busy) return;
    busy = true;
    block = null;
    failure = null;
    notifyListeners();
    try {
      final access = location.access == LocationAccess.granted ? LocationAccess.granted : await location.requestAccess();
      if (access != LocationAccess.granted) {
        block = OnlineBlock.permission;
        return;
      }
      location.start(uid);
      if (!await location.waitForFirstWrite(const Duration(seconds: 20))) {
        block = OnlineBlock.noFix;
        return;
      }
      await driverRepo.goOnline();
      _expectOnlineUntil = _clock().add(const Duration(seconds: 15));
    } on ApiFailure catch (e) {
      block = OnlineBlock.server;
      failure = e;
    } finally {
      busy = false;
      _reconcile();
      notifyListeners();
    }
  }

  Future<void> goOffline() async {
    if (busy) return;
    busy = true;
    failure = null;
    block = null;
    notifyListeners();
    _expectOnlineUntil = null;
    try {
      await driverRepo.goOffline();
    } on ApiFailure catch (e) {
      failure = e;
      block = OnlineBlock.server;
    } finally {
      busy = false;
      _reconcile();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    location.removeListener(_onLocation);
    location.stop();
    super.dispose();
  }
}
