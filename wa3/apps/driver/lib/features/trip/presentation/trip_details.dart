import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/config.dart';
import '../../../app/services.dart';
import '../../../app/widgets/info_row.dart';
import '../domain/stage_action.dart';

/// Where to go now (with the Maps handoff), who the rider is (with a call
/// button), and the agreed fare.
class TripDetails extends StatelessWidget {
  const TripDetails({super.key, required this.trip});
  final Trip trip;

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await context.services.launcher.open(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.t('لا يوجد تطبيق لفتح هذا.', 'No app on this phone can open this.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final toPickup = navigatesToPickup(trip.state);
    final target = toPickup ? trip.pickup : trip.dropoff;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Section(title: toPickup ? s.t('نقطة الالتقاء', 'Pickup') : s.t('الوجهة', 'Destination'), children: [
        Text(target.label, style: Theme.of(context).textTheme.titleMedium),
        if (!toPickup) Text('${s.t('طول الرحلة', 'Trip distance')}: ${km(trip.route.distanceMeters, ar: s.ar)}'),
        if (trip.state != TripState.paymentPending && trip.state != TripState.arrived) ...[
          const SizedBox(height: WSpace.md),
          OutlinedButton.icon(
            onPressed: () => _open(context, directionsUri(target.point)),
            icon: const Icon(Icons.navigation_outlined),
            label: Text(toPickup ? s.t('الاتجاهات إلى الراكب', 'Directions to pickup') : s.t('الاتجاهات إلى الوجهة', 'Directions to destination')),
          ),
        ],
      ]),
      const SizedBox(height: WSpace.md),
      Section(title: s.t('الراكب', 'Rider'), children: [
        Text(trip.riderName.isEmpty ? s.t('راكب', 'Rider') : trip.riderName, style: Theme.of(context).textTheme.titleMedium),
        if (trip.riderPhone.isNotEmpty) ...[
          const SizedBox(height: WSpace.sm),
          OutlinedButton.icon(
            onPressed: () => _open(context, telUri(trip.riderPhone)),
            icon: Icon(Icons.call_outlined, semanticLabel: s.t('اتصل بالراكب', 'Call the rider')),
            label: Text('${s.t('اتصل', 'Call')} ${ltr(trip.riderPhone)}'),
          ),
        ],
      ]),
      const SizedBox(height: WSpace.md),
      Section(children: [
        InfoRow(label: s.t('الأجرة المتفق عليها (نقداً)', 'Agreed fare (cash)'), value: money(trip.fare ?? 0, ar: s.ar), emphasis: true),
        if (toPickup) InfoRow(label: s.t('الوجهة', 'Destination'), value: trip.dropoff.label),
      ]),
    ]);
  }
}
