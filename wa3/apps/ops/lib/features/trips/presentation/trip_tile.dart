import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/widgets/fields.dart';
import '../domain/trips_repository.dart';
import 'trip_labels.dart';

/// Flag badges: always text + icon, never color alone.
List<Widget> flagBadges(S s, Trip t) => [
      if (t.stuck) StatusBadge(key: const Key('badge-stuck'), tone: Tone.error, label: s.t('متعثرة: لا تقدّم منذ مدة', 'Stuck: no progress')),
      if (t.locationStale) StatusBadge(key: const Key('badge-stale'), tone: Tone.warning, label: s.t('موقع السائق قديم', 'Driver location stale')),
    ];

class TripTile extends StatelessWidget {
  const TripTile({super.key, required this.record, required this.now, this.showAgeInState = true});
  final TripRecord record;
  final DateTime now;
  final bool showAgeInState;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = record.trip;
    final theme = Theme.of(context);
    final flagColor = t.stuck ? WColors.error : t.locationStale ? WColors.warning : null;
    final driver = t.driver == null
        ? s.t('لا يوجد سائق بعد', 'No driver yet')
        : [t.driver!.name, if (t.vehicle != null) ltr(t.vehicle!.plate)].join(' · ');
    return Semantics(
      container: true,
      label: record.flagged ? s.t('رحلة تحتاج انتباهاً', 'Trip needs attention') : null,
      child: InkWell(
        onTap: () => openTrip(context, t.id),
        child: Container(
          decoration: BoxDecoration(
            color: flagColor?.withValues(alpha: 0.06),
            border: BorderDirectional(start: BorderSide(color: flagColor ?? Colors.transparent, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
              StatusBadge(tone: stateTone(t.state), label: opsStateLabel(s, t.state)),
              ...flagBadges(s, t),
            ]),
            const SizedBox(height: WSpace.xs),
            if (showAgeInState) Text('${s.t('في هذه الحالة منذ', 'In this state for')}: ${age(record.stateSince, now, ar: s.ar)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (!showAgeInState) Text(dateTime(t.createdAt), style: theme.textTheme.bodySmall),
            Text('${s.t('الراكب', 'Rider')}: ${t.riderName.isEmpty ? ltr(shortId(t.riderId)) : t.riderName}${t.riderPhone.isEmpty ? '' : ' · ${ltr(t.riderPhone)}'}'),
            Text('${s.t('السائق', 'Driver')}: $driver'),
            Text('${s.t('الرحلة', 'Trip')} ${ltr(shortId(t.id))} · ${s.category(t.category)}', style: theme.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}
