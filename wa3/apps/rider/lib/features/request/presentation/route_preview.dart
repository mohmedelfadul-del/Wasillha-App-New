import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/presentation/map_surface.dart';
import '../../trips/domain/polyline.dart';

/// The server's route and reference price for the chosen category.
class RoutePreview extends StatelessWidget {
  const RoutePreview({super.key, required this.pickup, required this.dropoff, required this.route, required this.quote});
  final Place pickup;
  final Place dropoff;
  final RouteInfo route;
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final pts = routePoints(route);
    final estimated = route.estimated || pts == null;
    final dist = km(route.distanceMeters, ar: s.ar);
    final dur = minutes(route.durationSeconds, ar: s.ar);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          child: context.deps.map(
            context,
            MapSpec(
              center: pickup.point,
              interactive: false,
              fit: [pickup.point, dropoff.point, ...?pts],
              focusKey: '${pickup.point.lat},${pickup.point.lng}-${dropoff.point.lat},${dropoff.point.lng}',
              semanticLabel: '${s.t('خريطة المسار', 'Route map')}: ${pickup.label} → ${dropoff.label}',
              pins: [
                MapPin(id: 'pickup', point: pickup.point, kind: PinKind.pickup, label: s.t('نقطة الانطلاق', 'Pickup')),
                MapPin(id: 'dropoff', point: dropoff.point, kind: PinKind.dropoff, label: s.t('الوجهة', 'Destination')),
              ],
              lines: [MapLine(id: 'route', points: pts ?? [pickup.point, dropoff.point], dashed: pts == null)],
            ),
          ),
        ),
      ),
      const SizedBox(height: WSpace.md),
      Wrap(spacing: WSpace.lg, runSpacing: WSpace.xs, children: [
        Text(estimated ? '${s.t('مسافة تقديرية', 'Estimated distance')} $dist' : dist, style: theme.textTheme.titleMedium),
        Text('${s.t('حوالي', 'About')} $dur', style: theme.textTheme.titleMedium),
      ]),
      if (estimated)
        Text(s.t('المسار الفعلي قد يختلف.', 'The actual route may differ.'),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: WSpace.sm),
      Text('${s.t('السعر المقترح', 'Suggested price')}: ${money(quote.referenceFare, ar: s.ar)}', style: theme.textTheme.bodyLarge),
    ]);
  }
}
