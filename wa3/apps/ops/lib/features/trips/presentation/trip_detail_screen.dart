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
import '../domain/trips_repository.dart';
import 'trip_labels.dart';
import 'trip_sections.dart';
import 'trip_tile.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final repo = context.services.trips;
    return LiveView<TripRecord?>(
      key: ValueKey(tripId),
      open: () => repo.watch(tripId),
      isEmpty: (r) => r == null,
      empty: (context) => WStateView.empty(icon: Icons.search_off, title: context.s.t('الرحلة غير موجودة', 'Trip not found')),
      builder: (context, r) => NowBuilder(builder: (context, now) => TripDetailBody(record: r!, now: now)),
    );
  }
}

class TripDetailBody extends StatelessWidget {
  const TripDetailBody({super.key, required this.record, required this.now});
  final TripRecord record;
  final DateTime now;

  Future<void> _cancel(BuildContext context) async {
    final s = context.s;
    final t = record.trip;
    final revision = t.revision; // from the snapshot on screen
    final r = await confirmWithReason(
      context,
      title: s.t('إلغاء الرحلة ${ltr(shortId(t.id))}؟ سيُبلَّغ الراكب والسائق.', 'Cancel trip ${ltr(shortId(t.id))}? The rider and driver will be told.'),
      reasons: [for (final c in cancelReasons['ops']!) (c, s.cancelReason(c))],
      confirmLabel: s.t('إلغاء الرحلة', 'Cancel trip'),
      noteRequired: true,
    );
    if (r == null || !context.mounted) return;
    try {
      await context.services.trips.opsCancel(tripId: t.id, reason: r.reason, note: r.note!, expectedRevision: revision, key: IntentKey.generate());
      if (context.mounted) showSuccess(context, s.t('أُلغيت الرحلة', 'Trip cancelled'));
    } catch (e) {
      if (context.mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  Future<void> _resolve(BuildContext context) async {
    final s = context.s;
    final t = record.trip;
    final revision = t.revision;
    final resolution = await askReason(
      context,
      title: s.t('حل الاعتراض', 'Resolve dispute'),
      body: s.t('تعود الرحلة إلى «مكتملة» ويُغلق البلاغ. اكتب ما تقرر.', 'The trip returns to “completed” and the case closes. Write what was decided.'),
      label: s.t('القرار', 'Resolution'),
      confirmLabel: s.t('حل الاعتراض', 'Resolve dispute'),
      maxLength: 1000,
    );
    if (resolution == null || !context.mounted) return;
    try {
      await context.services.trips.resolveDispute(tripId: t.id, resolution: resolution, expectedRevision: revision, key: IntentKey.generate());
      if (context.mounted) showSuccess(context, s.t('حُلّ الاعتراض', 'Dispute resolved'));
    } catch (e) {
      if (context.mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = record.trip;
    final role = context.role;
    final canCancel = t.state.isPrePickup && Can.cancelTrip(role);
    final canResolve = t.state == TripState.disputed && Can.resolveDispute(role);
    return PageBody(children: [
      Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Semantics(header: true, child: Text('${s.t('رحلة', 'Trip')} ${ltr(shortId(t.id))}', style: Theme.of(context).textTheme.titleLarge)),
        StatusBadge(tone: stateTone(t.state), label: opsStateLabel(s, t.state)),
        ...flagBadges(s, t),
      ]),
      Field(s.t('المعرّف', 'ID'), ltr(t.id), selectable: true),
      Field(s.t('في هذه الحالة منذ', 'In this state for'), age(record.stateSince, now, ar: s.ar)),
      Field(s.t('المراجعة', 'Revision'), ltr('${t.revision}')),
      if (canCancel || canResolve) const SizedBox(height: WSpace.md),
      if (canCancel)
        PrimaryAction(label: s.t('إلغاء الرحلة (قبل الالتقاء)', 'Cancel trip (before pickup)'), icon: Icons.cancel_outlined, destructive: true, onPressed: () => _cancel(context)),
      if (canResolve) PrimaryAction(label: s.t('حل الاعتراض', 'Resolve dispute'), icon: Icons.gavel, onPressed: () => _resolve(context)),
      TripTimeline(trip: t),
      TripParties(trip: t),
      TripFare(trip: t),
      TripRoute(trip: t),
      if (t.cancellation != null) TripCancellation(c: t.cancellation!),
      if (t.disputeCaseId != null) ...[
        SectionTitle(s.t('الاعتراض', 'Dispute')),
        if (record.disputeResolution != null) Field(s.t('القرار', 'Resolution'), record.disputeResolution!),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(onPressed: () => openCase(context, t.disputeCaseId!), icon: const Icon(Icons.support_agent), label: Text(s.t('فتح البلاغ', 'Open the case'))),
        ),
      ],
    ]);
  }
}
