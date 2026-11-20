import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Who is coming: driver, vehicle, plate (LTR) and the trip state.
class DriverHeader extends StatelessWidget {
  const DriverHeader({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final d = trip.driver;
    final v = trip.vehicle;
    final tone = trip.state == TripState.driverArrived ? Tone.success : Tone.info;
    return Padding(
      padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.sm, WSpace.lg, WSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(tone: tone, label: s.state(trip.state)),
          const SizedBox(height: WSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: WSpace.sm,
            runSpacing: WSpace.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d?.name ?? '—', style: theme.textTheme.titleLarge),
                  if (d?.ratingAvg != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: WColors.warning),
                        const SizedBox(width: WSpace.xs),
                        Text(ltr(d!.ratingAvg!.toStringAsFixed(1))),
                      ],
                    ),
                  if (v != null) Text('${v.title} · ${s.category(v.category)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              if (v != null)
                Semantics(
                  label: '${s.t('رقم اللوحة', 'Plate number')} ${v.plate}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: WSpace.md, vertical: WSpace.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.onSurface, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ltr(v.plate), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
