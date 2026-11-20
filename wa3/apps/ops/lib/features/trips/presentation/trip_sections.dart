import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/widgets/fields.dart';
import 'trip_labels.dart';

/// State timeline from the server's timestamps, in time order.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final entries = trip.timestamps.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('التسلسل الزمني', 'Timeline')),
      if (entries.isEmpty) Text(s.t('لا توجد أوقات مسجلة.', 'No times recorded.')),
      for (var i = 0; i < entries.length; i++)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(entries[i].key == trip.state ? Icons.radio_button_checked : Icons.check_circle_outline, size: 20,
              color: entries[i].key == trip.state ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: WSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: WSpace.sm),
              child: Wrap(spacing: WSpace.sm, children: [
                Text(opsStateLabel(s, entries[i].key), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(dateTime(entries[i].value)),
                if (i > 0) Text('(+${_gap(entries[i].value.difference(entries[i - 1].value), s)})', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
        ]),
    ]);
  }

  static String _gap(Duration d, S s) {
    if (d.inMinutes < 1) return ltr('${d.inSeconds}') + s.t(' ث', ' s');
    if (d.inHours < 1) return ltr('${d.inMinutes}') + s.t(' د', ' min');
    return ltr('${d.inHours}') + s.t(' س', ' h');
  }
}

class TripParties extends StatelessWidget {
  const TripParties({super.key, required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = trip;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('الأطراف', 'Parties')),
      Field(s.t('الراكب', 'Rider'), '${t.riderName.isEmpty ? '—' : t.riderName}${t.riderPhone.isEmpty ? '' : ' · ${ltr(t.riderPhone)}'}'),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(onPressed: () => openRider(context, t.riderId), child: Text(s.t('ملف الراكب', 'Rider profile'))),
      ),
      if (t.driver == null)
        Field(s.t('السائق', 'Driver'), s.t('لم يُعيَّن', 'Not assigned'))
      else ...[
        Field(s.t('السائق', 'Driver'), '${t.driver!.name}${t.driver!.phone?.isNotEmpty == true ? ' · ${ltr(t.driver!.phone!)}' : ''}'),
        if (t.vehicle != null) Field(s.t('المركبة', 'Vehicle'), '${t.vehicle!.title} · ${ltr(t.vehicle!.plate)} · ${s.category(t.vehicle!.category)}'),
        if (t.driverId != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => openDriver(context, t.driverId!), child: Text(s.t('ملف السائق', 'Driver profile'))),
          ),
      ],
    ]);
  }
}

class TripFare extends StatelessWidget {
  const TripFare({super.key, required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = trip;
    String m(int v) => money(v, ar: s.ar);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('الأجرة', 'Fare')),
      Field(s.t('السعر المرجعي', 'Reference fare'), m(t.quote.referenceFare)),
      Field(s.t('النطاق المسموح', 'Allowed range'), '${m(t.quote.minFare)} – ${m(t.quote.maxFare)}'),
      if (t.proposedFare != null) Field(s.t('عرض الراكب', 'Rider proposed'), m(t.proposedFare!)),
      if (t.fare != null) Field(s.t('الأجرة المتفق عليها', 'Agreed fare'), m(t.fare!)),
      if (t.amountDue != null) Field(s.t('المبلغ المستحق', 'Amount due'), m(t.amountDue!)),
      if (t.cashAmount != null) Field(s.t('النقد المستلم', 'Cash received'), m(t.cashAmount!)),
      Field(s.t('العروض', 'Offers'), ltr('${t.offerCount}')),
    ]);
  }
}

class TripRoute extends StatelessWidget {
  const TripRoute({super.key, required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = trip.route;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('المسار', 'Route')),
      Field(s.t('من', 'From'), trip.pickup.label),
      Field(s.t('إلى', 'To'), trip.dropoff.label),
      Field(s.t('المسافة والمدة', 'Distance & time'), '${km(r.distanceMeters, ar: s.ar)} · ${minutes(r.durationSeconds, ar: s.ar)}'),
      if (r.estimated) Text(s.t('تقدير بخط مستقيم (لم تتوفر خدمة المسارات).', 'Straight-line estimate (routing was unavailable).'), style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class TripCancellation extends StatelessWidget {
  const TripCancellation({super.key, required this.c});
  final Cancellation c;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final actor = switch (c.actor) {
      'rider' => s.t('الراكب', 'Rider'),
      'driver' => s.t('السائق', 'Driver'),
      'ops' => s.t('فريق التشغيل', 'Operations'),
      _ => s.t('النظام', 'System'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('الإلغاء', 'Cancellation')),
      Field(s.t('بواسطة', 'By'), actor),
      Field(s.t('السبب', 'Reason'), s.cancelReason(c.reason)),
      if (c.note?.isNotEmpty == true) Field(s.t('ملاحظة', 'Note'), c.note!),
      Field(s.t('الوقت', 'At'), dateTime(c.at)),
    ]);
  }
}
