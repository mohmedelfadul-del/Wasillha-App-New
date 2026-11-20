import 'package:flutter/widgets.dart';

import '../features/account/domain/driver_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/documents/domain/document_repository.dart';
import '../features/earnings/domain/earnings_repository.dart';
import '../features/history/domain/history_repository.dart';
import '../features/location/application/location_service.dart';
import '../features/requests/domain/request_repository.dart';
import '../features/trip/domain/trip_repository.dart';
import '../features/vehicles/domain/vehicle_repository.dart';
import 'launcher.dart';
import 'settings_controller.dart';

/// Everything screens depend on, behind interfaces (tests pass fakes).
class AppServices {
  AppServices({
    required this.auth,
    required this.driver,
    required this.documents,
    required this.picker,
    required this.vehicles,
    required this.requests,
    required this.trips,
    required this.earnings,
    required this.history,
    required this.location,
    required this.launcher,
    required this.settings,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final AuthRepository auth;
  final DriverRepository driver;
  final DocumentRepository documents;
  final ImagePickerPort picker;
  final VehicleRepository vehicles;
  final RequestRepository requests;
  final TripRepository trips;
  final EarningsRepository earnings;
  final HistoryRepository history;
  final LocationService location;
  final Launcher launcher;
  final SettingsController settings;
  final DateTime Function() clock;
}

class Services extends InheritedWidget {
  const Services({super.key, required this.services, required super.child});
  final AppServices services;
  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Services>()!.services;
  @override
  bool updateShouldNotify(Services old) => old.services != services;
}

extension ServicesX on BuildContext {
  AppServices get services => Services.of(this);
}
