import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../common/presentation/cache_banner.dart';
import 'dispute_sheet.dart';
import 'rating_form.dart';

/// Cash due (paymentPending), then receipt, rating and dispute path.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key, required this.trip, this.fromCache = false});
  final Trip trip;
  final bool fromCache;

  bool _canDispute(DateTime now) {
    final done = trip.stamp(TripState.completed);
    return trip.state == TripState.completed && done != null && now.difference(done) < const Duration(hours: Tunables.disputeWindowHours);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final pending = trip.state == TripState.paymentPending;
    final amount = pending ? (trip.fare ?? trip.amountDue) : (trip.cashAmount ?? trip.fare);
    final rated = trip.riderRating;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(pending ? s.t('الدفع نقداً', 'Cash payment') : s.t('إيصال الرحلة', 'Trip receipt'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CacheBanner(fromCache: fromCache),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                tone: switch (trip.state) { TripState.completed => Tone.success, TripState.disputed => Tone.warning, _ => Tone.warning },
                label: trip.state == TripState.disputed ? s.t('قيد المراجعة', 'Under review') : s.state(trip.state),
              ),
            ),
            const SizedBox(height: WSpace.md),
            Text(pending ? s.t('ادفع للسائق نقداً', 'Pay the driver in cash') : s.t('المبلغ المدفوع نقداً', 'Paid in cash'),
                style: theme.textTheme.titleMedium),
            Text(amount == null ? '—' : money(amount, ar: s.ar), style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
            if (pending)
              Padding(
                padding: const EdgeInsets.only(top: WSpace.sm),
                child: Text(s.t('تكتمل الرحلة عندما يسجل السائق استلام المبلغ.', 'The trip completes when the driver records the payment.')),
              ),
            if (trip.state == TripState.disputed)
              Padding(
                padding: const EdgeInsets.only(top: WSpace.sm),
                child: Text(s.t('أرسلت اعتراضاً على هذه الرحلة. سيراجعه فريق وصلها.', 'You reported a problem with this trip. The Wasilha team is reviewing it.')),
              ),
            const SizedBox(height: WSpace.lg),
            _Summary(trip: trip),
            const SizedBox(height: WSpace.xl),
            if (!pending && rated == null)
              RatingForm(trip: trip)
            else if (rated != null) ...[
              Text(s.t('تقييمك', 'Your rating'), style: theme.textTheme.titleMedium),
              Semantics(
                label: s.t('${rated.stars} من 5', '${rated.stars} of 5'),
                excludeSemantics: true,
                child: Row(children: [
                  for (var i = 1; i <= 5; i++) Icon(i <= rated.stars ? Icons.star_rounded : Icons.star_outline_rounded, color: WColors.warning),
                ]),
              ),
              if (rated.comment?.isNotEmpty ?? false) Text(rated.comment!),
            ],
            if (!pending) ...[
              const SizedBox(height: WSpace.lg),
              if (_canDispute(now))
                TextButton.icon(
                  onPressed: () => showDisputeSheet(context, trip),
                  icon: const Icon(Icons.report_outlined),
                  label: Text(s.t('الإبلاغ عن مشكلة في الرحلة', 'Report a problem with this trip')),
                )
              else if (trip.state == TripState.completed)
                Text(s.t('انتهت مهلة الـ48 ساعة للاعتراض على هذه الرحلة.', 'The 48-hour window to report a problem with this trip has passed.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final v = trip.vehicle;
    final when = trip.stamp(TripState.completed) ?? trip.createdAt;
    Widget line(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$a: ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            TextSpan(text: b),
          ])),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line(s.t('من', 'From'), trip.pickup.label),
          line(s.t('إلى', 'To'), trip.dropoff.label),
          if (trip.driver != null) line(s.t('السائق', 'Driver'), trip.driver!.name),
          if (v != null) line(s.t('المركبة', 'Vehicle'), '${v.title} · ${ltr(v.plate)}'),
          line(s.t('المسافة', 'Distance'), km(trip.route.distanceMeters, ar: s.ar)),
          line(s.t('التاريخ', 'Date'), '${ltr('${when.day}/${when.month}/${when.year}')} ${clock(when)}'),
        ]),
      ),
    );
  }
}
