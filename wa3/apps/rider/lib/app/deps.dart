import 'package:flutter/widgets.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/common/presentation/map_surface.dart';
import '../features/location/domain/location_service.dart';
import '../features/places/domain/places_repository.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/trips/domain/trip_repository.dart';

/// The app's data layer, injected once at the root. Tests pass fakes.
class RiderDeps extends InheritedWidget {
  const RiderDeps({
    super.key,
    required this.auth,
    required this.profile,
    required this.trips,
    required this.places,
    required this.location,
    required this.map,
    required this.settings,
    required super.child,
  });

  final AuthRepository auth;
  final ProfileRepository profile;
  final TripRepository trips;
  final PlacesRepository places;
  final LocationService location;
  final MapBuilder map;
  final SettingsController settings;

  static RiderDeps of(BuildContext context) {
    final d = context.getInheritedWidgetOfExactType<RiderDeps>();
    assert(d != null, 'RiderDeps missing above this context');
    return d!;
  }

  @override
  bool updateShouldNotify(RiderDeps old) => false;
}

extension RiderDepsX on BuildContext {
  RiderDeps get deps => RiderDeps.of(this);
}
