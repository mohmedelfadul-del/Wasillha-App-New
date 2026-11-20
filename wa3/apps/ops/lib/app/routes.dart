import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/audit/presentation/audit_screen.dart';
import '../features/cases/presentation/case_detail_screen.dart';
import '../features/cases/presentation/cases_screen.dart';
import '../features/cockpit/presentation/cockpit_screen.dart';
import '../features/finance/presentation/settlement_screen.dart';
import '../features/kyc/presentation/kyc_detail_screen.dart';
import '../features/kyc/presentation/kyc_queue_screen.dart';
import '../features/people/presentation/driver_profile_screen.dart';
import '../features/people/presentation/rider_profile_screen.dart';
import '../features/people/presentation/search_screen.dart';
import '../features/pricing/presentation/pricing_screen.dart';
import '../features/trips/presentation/live_trips_screen.dart';
import '../features/trips/presentation/trip_detail_screen.dart';
import 'sections.dart';
import 'shell.dart';

/// Every staff role (trip details are readable by all staff).
const allStaff = {StaffRole.operations, StaffRole.kyc, StaffRole.support, StaffRole.finance};

/// URL routes. Direct navigation to a section the role can't use renders the
/// access-denied state (inside [OpsShell]).
Route<dynamic> generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');
  final seg = uri.pathSegments;
  return MaterialPageRoute<void>(settings: settings, builder: (_) => pageFor(seg, uri.queryParameters));
}

Widget pageFor(List<String> seg, Map<String, String> q) {
  if (seg.isEmpty) return const OpsShell(section: Section.cockpit, child: CockpitScreen());
  final id = seg.length > 1 ? Uri.decodeComponent(seg[1]) : null;
  switch (seg.first) {
    case 'kyc':
      if (seg.length > 1 && seg[1] == 'review' && q['path'] != null) {
        return OpsShell(section: Section.kyc, detail: true, child: KycDetailScreen(path: q['path']!));
      }
      return const OpsShell(section: Section.kyc, child: KycQueueScreen());
    case 'trips':
      if (id != null) return OpsShell(section: Section.trips, detail: true, allowed: allStaff, child: TripDetailScreen(tripId: id));
      return const OpsShell(section: Section.trips, child: LiveTripsScreen());
    case 'cases':
      if (id != null) return OpsShell(section: Section.cases, detail: true, child: CaseDetailScreen(caseId: id));
      return OpsShell(section: Section.cases, child: CasesScreen(urgentOnly: q['filter'] == 'urgent'));
    case 'search':
      return OpsShell(section: Section.search, child: SearchScreen(initialQuery: q['q']));
    case 'riders' when id != null:
      return OpsShell(section: Section.search, detail: true, child: RiderProfileScreen(riderId: id));
    case 'drivers' when id != null:
      return OpsShell(section: Section.search, detail: true, child: DriverProfileScreen(driverId: id));
    case 'settlement':
      return OpsShell(section: Section.settlement, child: SettlementScreen(initialDriverId: q['driver']));
    case 'pricing':
      return const OpsShell(section: Section.pricing, child: PricingScreen());
    case 'audit':
      return const OpsShell(section: Section.audit, child: AuditScreen());
  }
  return const OpsShell(section: Section.cockpit, detail: true, child: _NotFound());
}

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) =>
      WStateView.empty(icon: Icons.travel_explore, title: context.s.t('الصفحة غير موجودة', 'Page not found'));
}

/// Navigation helpers.
void openSection(BuildContext context, Section s) => Navigator.of(context).pushNamedAndRemoveUntil(s.path, (_) => false);
void openTrip(BuildContext context, String id) => Navigator.of(context).pushNamed('/trips/${Uri.encodeComponent(id)}');
void openRider(BuildContext context, String id) => Navigator.of(context).pushNamed('/riders/${Uri.encodeComponent(id)}');
void openDriver(BuildContext context, String id) => Navigator.of(context).pushNamed('/drivers/${Uri.encodeComponent(id)}');
void openCase(BuildContext context, String id) => Navigator.of(context).pushNamed('/cases/${Uri.encodeComponent(id)}');
void openReview(BuildContext context, String path) => Navigator.of(context).pushNamed('/kyc/review?path=${Uri.encodeQueryComponent(path)}');
void openSettlement(BuildContext context, String driverId) =>
    Navigator.of(context).pushNamed('/settlement?driver=${Uri.encodeQueryComponent(driverId)}');
