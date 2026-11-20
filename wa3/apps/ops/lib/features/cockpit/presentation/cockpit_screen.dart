import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/sections.dart';
import '../../auth/application/session_controller.dart';
import '../domain/cockpit_repository.dart';
import 'queue_row.dart';

/// What needs action now, how long it has waited and who owns it.
class CockpitScreen extends StatelessWidget {
  const CockpitScreen({super.key});

  static List<QueueKind> queuesFor(StaffRole? role) => [
        if (Can.workCases(role)) QueueKind.urgentSafety,
        if (Can.reviewKyc(role)) QueueKind.kycPending,
        if (Section.trips.allows(role)) QueueKind.flaggedTrips,
        if (Can.workCases(role)) QueueKind.openCases,
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final role = context.role;
    final queues = queuesFor(role);
    if (queues.isEmpty) {
      final money = Can.viewMoney(role);
      return WStateView.empty(
        icon: Icons.inbox_outlined,
        title: s.t('لا توجد قوائم عمل لدورك هنا', 'No work queues for your role here'),
        body: money ? s.t('التسويات النقدية تتم لكل سائق من شاشة التسوية.', 'Cash settlements are recorded per driver on the settlement screen.') : null,
        actionLabel: money ? Section.settlement.label(s) : null,
        onAction: money ? () => openSection(context, Section.settlement) : null,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(WSpace.lg),
      children: [
        Text(s.t('ما يحتاج إجراءً الآن، الأقدم أولاً.', 'What needs action now, oldest first.'), style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: WSpace.md),
        for (final q in queues) ...[QueueRow(kind: q), const SizedBox(height: WSpace.md)],
      ],
    );
  }
}
