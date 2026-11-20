import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Floating card for the rider's trip in progress.
class ActiveTripCard extends StatelessWidget {
  const ActiveTripCard({super.key, required this.trip, required this.onOpen});
  final Trip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final tone = trip.state == TripState.paymentPending ? Tone.warning : Tone.info;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('رحلتك الحالية', 'Your current trip'), style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: WSpace.xs),
                StatusBadge(tone: tone, label: s.state(trip.state)),
                const SizedBox(height: WSpace.sm),
                Text('${s.t('إلى', 'To')}: ${trip.dropoff.label}', style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (trip.driver != null && trip.vehicle != null)
                  Text('${trip.driver!.name} · ${ltr(trip.vehicle!.plate)}', style: theme.textTheme.bodyMedium),
              ]),
            ),
            const SizedBox(width: WSpace.sm),
            Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, semanticLabel: s.t('افتح', 'Open')),
          ]),
        ),
      ),
    );
  }
}
