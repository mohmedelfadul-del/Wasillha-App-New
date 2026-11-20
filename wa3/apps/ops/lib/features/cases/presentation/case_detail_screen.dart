import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/sections.dart';
import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../../../app/widgets/reason_dialog.dart';
import '../../auth/application/session_controller.dart';
import '../domain/cases_repository.dart';
import 'case_labels.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final repo = context.services.cases;
    return LiveView<CaseRecord?>(
      key: ValueKey(caseId),
      open: () => repo.watch(caseId),
      isEmpty: (c) => c == null,
      empty: (context) => WStateView.empty(icon: Icons.search_off, title: context.s.t('البلاغ غير موجود', 'Case not found')),
      builder: (context, c) => NowBuilder(builder: (context, now) => CaseDetailBody(record: c!, now: now)),
    );
  }
}

class CaseDetailBody extends StatelessWidget {
  const CaseDetailBody({super.key, required this.record, required this.now});
  final CaseRecord record;
  final DateTime now;

  Future<void> _claim(BuildContext context) async {
    try {
      await context.services.cases.claim(record.c.id, IntentKey.generate());
    } catch (e) {
      if (context.mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  Future<void> _close(BuildContext context) async {
    final s = context.s;
    final resolution = await askReason(
      context,
      title: s.t('إغلاق البلاغ', 'Close the case'),
      body: s.t('اكتب ما تم فعله. يُسجَّل في سجل التدقيق.', 'Write what was done. It is recorded in the audit log.'),
      label: s.t('الحل', 'Resolution'),
      confirmLabel: s.t('إغلاق البلاغ', 'Close case'),
      maxLength: 1000,
    );
    if (resolution == null || !context.mounted) return;
    try {
      await context.services.cases.close(record.c.id, resolution, IntentKey.generate());
      if (context.mounted) showSuccess(context, s.t('أُغلق البلاغ', 'Case closed'));
    } catch (e) {
      if (context.mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = record.c;
    final me = context.myUid;
    final role = context.role;
    final canWork = Can.workCases(role);
    final mine = c.ownerId == me;
    final resolved = c.status == 'resolved';

    final List<Widget> actions;
    if (resolved || !canWork) {
      actions = const [];
    } else if (c.ownerId == null) {
      actions = [PrimaryAction(label: s.t('تولَّ هذا البلاغ', 'Take ownership'), icon: Icons.assignment_ind_outlined, onPressed: () => _claim(context))];
    } else if (!mine) {
      actions = [WBanner(tone: Tone.warning, text: s.t('يتولاه: ${ltr(c.ownerId!)}', 'Owned by: ${ltr(c.ownerId!)}'))];
    } else if (c.type == CaseType.dispute && c.tripId != null) {
      actions = [
        Text(s.t('يُحل الاعتراض من صفحة الرحلة، فتعود الرحلة «مكتملة» ويُغلق البلاغ معاً.', 'Resolve the dispute from the trip: the trip returns to completed and this case closes together.')),
        const SizedBox(height: WSpace.sm),
        PrimaryAction(label: s.t('فتح الرحلة لحل الاعتراض', 'Open trip to resolve the dispute'), icon: Icons.gavel, onPressed: () async => openTrip(context, c.tripId!)),
      ];
    } else {
      actions = [PrimaryAction(label: s.t('إغلاق بحل', 'Close with resolution'), icon: Icons.task_alt, onPressed: () => _close(context))];
    }

    return PageBody(children: [
      Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Semantics(header: true, child: Text(caseTypeLabel(s, c.type), style: Theme.of(context).textTheme.titleLarge)),
        if (record.urgent) StatusBadge(tone: Tone.error, label: s.t('عاجل', 'Urgent')),
        StatusBadge(tone: caseStatusTone(c.status), label: caseStatusLabel(s, c.status)),
      ]),
      const SizedBox(height: WSpace.sm),
      Field(s.t('فُتح', 'Opened'), '${dateTime(c.createdAt)} · ${age(c.createdAt, now, ar: s.ar)}'),
      Field(s.t('المسؤول', 'Owner'), ownerLabel(s, c.ownerId, me)),
      if (c.reporterRole != null) Field(s.t('المُبلِّغ', 'Reported by'), c.reporterRole == 'rider' ? s.t('الراكب', 'Rider') : c.reporterRole == 'driver' ? s.t('السائق', 'Driver') : c.reporterRole!),
      Field(s.t('المعرّف', 'ID'), ltr(c.id), selectable: true),
      SectionTitle(s.t('الوصف', 'Description')),
      SelectableText(c.description),
      if (c.tripId != null || record.subjectDriverId != null) SectionTitle(s.t('مرتبط بـ', 'Related')),
      Wrap(spacing: WSpace.sm, children: [
        if (c.tripId != null) TextButton.icon(onPressed: () => openTrip(context, c.tripId!), icon: const Icon(Icons.route_outlined), label: Text('${s.t('الرحلة', 'Trip')} ${ltr(shortId(c.tripId!))}')),
        if (record.subjectDriverId != null)
          TextButton.icon(onPressed: () => openDriver(context, record.subjectDriverId!), icon: const Icon(Icons.person_outline), label: Text(s.t('ملف السائق', 'Driver profile'))),
      ]),
      if (resolved) ...[
        SectionTitle(s.t('الحل', 'Resolution')),
        if (record.resolution != null) SelectableText(record.resolution!),
        Field(s.t('أغلقه', 'Resolved by'), ownerLabel(s, record.resolvedBy, me)),
        if (record.updatedAt != null) Field(s.t('الوقت', 'At'), dateTime(record.updatedAt!)),
      ],
      if (actions.isNotEmpty) ...[const SizedBox(height: WSpace.lg), ...actions],
    ]);
  }
}
