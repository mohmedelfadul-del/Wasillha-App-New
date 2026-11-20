import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../account/domain/driver_repository.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

String vehicleStatusLabel(S s, String status) => switch (status) {
      'approved' => s.review(ReviewStatus.approved),
      'changesRequested' => s.review(ReviewStatus.changesRequested),
      'rejected' => s.review(ReviewStatus.rejected),
      _ => s.review(ReviewStatus.pending),
    };

Tone vehicleTone(String status) => switch (status) {
      'approved' => Tone.success,
      'changesRequested' => Tone.warning,
      'rejected' => Tone.error,
      _ => Tone.info,
    };

/// The driver's vehicles; pick the active one for this session among approved ones.
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key, required this.uid});
  final String uid;
  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  late Stream<Live<List<Vehicle>>> _vehicles = context.services.vehicles.watchVehicles(widget.uid);
  late final Stream<Live<DriverState?>> _driver = context.services.driver.watchDriver(widget.uid);

  Future<void> _activate(Vehicle v) async {
    await context.services.driver.setActiveVehicle(vehicleId: v.id, key: IntentKey.generate());
    if (mounted) showSuccess(context, context.s.t('ستعمل بهذه المركبة.', 'You’ll drive this vehicle.'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('مركباتي', 'My vehicles'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => AddVehicleScreen(uid: widget.uid))),
        icon: const Icon(Icons.add),
        label: Text(s.t('أضف مركبة', 'Add vehicle')),
      ),
      body: StreamBuilder<Live<DriverState?>>(
        stream: _driver,
        builder: (context, dsnap) => StreamBuilder<Live<List<Vehicle>>>(
          stream: _vehicles,
          builder: (context, snap) {
            if (snap.hasError) {
              return WStateView.error(context, snap.error!, onRetry: () => setState(() => _vehicles = context.services.vehicles.watchVehicles(widget.uid)));
            }
            if (!snap.hasData) return WStateView.loading();
            final list = snap.data!.data;
            final driver = dsnap.data?.data;
            if (list.isEmpty) {
              return WStateView.empty(
                icon: Icons.directions_car_outlined,
                title: s.t('لا توجد مركبات بعد', 'No vehicles yet'),
                body: s.t('أضف مركبتك ثم ارفع ترخيصها وتأمينها وصورتها للمراجعة.', 'Add your vehicle, then upload its registration, insurance and photo for review.'),
              );
            }
            return ListView(padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.lg, WSpace.lg, 96), children: [
              StaleNotice(fromCache: snap.data!.fromCache),
              if (driver?.hasTrip ?? false)
                Padding(
                  padding: const EdgeInsets.only(bottom: WSpace.md),
                  child: WBanner(tone: Tone.warning, text: s.t('لا يمكن تغيير المركبة أثناء رحلة.', 'You can’t change vehicle during a trip.')),
                ),
              for (final v in list) ...[_tile(s, v, driver), const SizedBox(height: WSpace.md)],
            ]);
          },
        ),
      ),
    );
  }

  Widget _tile(S s, Vehicle v, DriverState? d) {
    final active = d?.profile.activeVehicleId == v.id;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => VehicleDetailScreen(uid: widget.uid, vehicle: v))),
        child: Padding(
          padding: const EdgeInsets.all(WSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v.color} ${v.make} ${v.model}', style: Theme.of(context).textTheme.titleMedium),
            Text('${s.category(v.category)} · ${ltr(v.plate)} · ${ltr('${v.year}')}'),
            const SizedBox(height: WSpace.sm),
            Wrap(spacing: WSpace.sm, runSpacing: WSpace.sm, children: [
              StatusBadge(tone: vehicleTone(v.status), label: vehicleStatusLabel(s, v.status)),
              if (active) StatusBadge(tone: Tone.success, label: s.t('المركبة الحالية', 'Active vehicle')),
            ]),
            if (!v.approved) ...[
              const SizedBox(height: WSpace.sm),
              Text(s.t('افتح المركبة لرفع وثائقها ومتابعة المراجعة.', 'Open the vehicle to upload its documents and follow the review.')),
            ],
            if (v.approved && !active && !(d?.hasTrip ?? false)) ...[
              const SizedBox(height: WSpace.md),
              PrimaryAction(label: s.t('استخدمها لهذه الجلسة', 'Use for this session'), onPressed: () => _activate(v)),
            ],
          ]),
        ),
      ),
    );
  }
}
