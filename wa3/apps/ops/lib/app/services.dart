import 'package:flutter/widgets.dart';

import '../features/audit/domain/audit_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/cases/domain/cases_repository.dart';
import '../features/cockpit/domain/cockpit_repository.dart';
import '../features/finance/domain/finance_repository.dart';
import '../features/kyc/domain/kyc_repository.dart';
import '../features/people/domain/people_repository.dart';
import '../features/pricing/domain/pricing_repository.dart';
import '../features/trips/domain/trips_repository.dart';

/// Repositories behind interfaces so every screen runs without Firebase in tests.
class OpsServices {
  const OpsServices({
    required this.auth,
    required this.cockpit,
    required this.kyc,
    required this.trips,
    required this.cases,
    required this.people,
    required this.pricing,
    required this.finance,
    required this.audit,
    this.now = DateTime.now,
  });
  final AuthRepository auth;
  final CockpitRepository cockpit;
  final KycRepository kyc;
  final TripsRepository trips;
  final CasesRepository cases;
  final PeopleRepository people;
  final PricingRepository pricing;
  final FinanceRepository finance;
  final AuditRepository audit;
  final DateTime Function() now;

  static OpsServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OpsServicesScope>()!.services;
}

class OpsServicesScope extends InheritedWidget {
  const OpsServicesScope({super.key, required this.services, required super.child});
  final OpsServices services;
  @override
  bool updateShouldNotify(OpsServicesScope old) => old.services != services;
}

extension ServicesX on BuildContext {
  OpsServices get services => OpsServices.of(this);
}
