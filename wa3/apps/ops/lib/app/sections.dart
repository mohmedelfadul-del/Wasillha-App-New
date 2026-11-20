import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Top-level work areas. Each lists the roles that can act there
/// (admin can use everything). Mirrors the server's command roles.
enum Section {
  cockpit('/', {StaffRole.operations, StaffRole.kyc, StaffRole.support, StaffRole.finance}),
  kyc('/kyc', {StaffRole.kyc}),
  trips('/trips', {StaffRole.operations, StaffRole.support}),
  cases('/cases', {StaffRole.support, StaffRole.operations}),
  search('/search', {StaffRole.operations, StaffRole.support, StaffRole.kyc, StaffRole.finance}),
  settlement('/settlement', {StaffRole.finance, StaffRole.operations}),
  pricing('/pricing', <StaffRole>{}),
  audit('/audit', <StaffRole>{});

  const Section(this.path, this.roles);
  final String path;
  final Set<StaffRole> roles;

  bool allows(StaffRole? role) => role == StaffRole.admin || (role != null && roles.contains(role));

  IconData get icon => switch (this) {
        cockpit => Icons.inbox_outlined,
        kyc => Icons.badge_outlined,
        trips => Icons.route_outlined,
        cases => Icons.support_agent_outlined,
        search => Icons.search,
        settlement => Icons.payments_outlined,
        pricing => Icons.tune,
        audit => Icons.history_edu_outlined,
      };

  String label(S s) => switch (this) {
        cockpit => s.t('قوائم العمل', 'Work queues'),
        kyc => s.t('مراجعة الوثائق', 'KYC review'),
        trips => s.t('الرحلات الجارية', 'Live trips'),
        cases => s.t('البلاغات والدعم', 'Support & safety'),
        search => s.t('بحث', 'Search'),
        settlement => s.t('التسوية النقدية', 'Cash settlement'),
        pricing => s.t('التسعير', 'Pricing'),
        audit => s.t('سجل التدقيق', 'Audit log'),
      };

  static List<Section> visibleFor(StaffRole? role) => values.where((s) => s.allows(role)).toList();
}

/// Who may do what (server-enforced; the UI only hides what would be refused).
class Can {
  const Can._();
  static bool _r(StaffRole? role, Set<StaffRole> roles) => role == StaffRole.admin || roles.contains(role);
  static bool reviewKyc(StaffRole? r) => _r(r, {StaffRole.kyc});
  static bool cancelTrip(StaffRole? r) => _r(r, {StaffRole.operations, StaffRole.support});
  static bool resolveDispute(StaffRole? r) => _r(r, {StaffRole.support});
  static bool workCases(StaffRole? r) => _r(r, {StaffRole.support, StaffRole.operations});
  static bool viewMoney(StaffRole? r) => _r(r, {StaffRole.finance, StaffRole.operations});
  static bool recordSettlement(StaffRole? r) => _r(r, {StaffRole.finance});
  static bool editPricing(StaffRole? r) => r == StaffRole.admin;
  static bool readAudit(StaffRole? r) => r == StaffRole.admin;
}

String roleLabel(S s, StaffRole r) => switch (r) {
      StaffRole.admin => s.t('مدير النظام', 'Admin'),
      StaffRole.operations => s.t('العمليات', 'Operations'),
      StaffRole.kyc => s.t('مراجعة الوثائق', 'KYC'),
      StaffRole.support => s.t('الدعم', 'Support'),
      StaffRole.finance => s.t('المالية', 'Finance'),
    };
