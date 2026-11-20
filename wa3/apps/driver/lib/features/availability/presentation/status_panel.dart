import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../account/domain/driver_repository.dart';
import '../../account/presentation/support_screen.dart';
import '../../documents/presentation/account_status_card.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../location/domain/location_port.dart';
import '../../vehicles/presentation/vehicles_screen.dart';
import '../application/availability_controller.dart';

/// Online state plus the one next step: the online/offline toggle when every
/// prerequisite is met, otherwise the action that unblocks it.
class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.driver, required this.controller});
  final DriverState driver;
  final AvailabilityController controller;

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = driver.profile;
    final uid = p.uid;
    if (!p.online && !driver.approved) {
      return AccountStatusCard(
        status: p.status,
        action: p.status == DriverStatus.suspended
            ? PrimaryAction(label: s.t('تواصل مع الدعم', 'Contact support'), onPressed: () async => _push(context, const SupportScreen()))
            : PrimaryAction(
                label: p.status == DriverStatus.onboarding ? s.t('افتح الوثائق', 'Open documents') : s.t('اعرض الوثائق', 'View documents'),
                onPressed: () async => _push(context, DocumentsScreen(uid: uid, status: p.status)),
              ),
      );
    }
    final access = controller.location.access;
    final Widget action;
    final String hint;
    if (p.online) {
      hint = s.t('أنت متصل. ستظهر الطلبات القريبة أدناه.', 'You’re online. Nearby requests appear below.');
      action = PrimaryAction(label: s.t('قطع الاتصال', 'Go offline'), icon: Icons.power_settings_new, large: true, onPressed: controller.busy ? null : controller.goOffline);
    } else if (p.activeVehicleId == null) {
      hint = s.t('اختر مركبة معتمدة لتتمكن من الاتصال بالعمل.', 'Choose an approved vehicle to go online.');
      action = PrimaryAction(label: s.t('اختر مركبة', 'Choose a vehicle'), icon: Icons.directions_car, large: true, onPressed: () async => _push(context, VehiclesScreen(uid: uid)));
    } else if (access == LocationAccess.deniedForever) {
      hint = s.t('إذن الموقع مرفوض. فعّله من إعدادات التطبيق — لا يمكنك الاتصال بالعمل بدونه.', 'Location permission is denied. Turn it on in app settings — you can’t go online without it.');
      action = PrimaryAction(label: s.t('افتح الإعدادات', 'Open settings'), icon: Icons.settings, large: true, onPressed: () async {
        await controller.location.source.openAppSettings();
        await controller.location.refreshAccess();
      });
    } else if (access == LocationAccess.serviceDisabled) {
      hint = s.t('خدمة الموقع في هاتفك مغلقة. شغّلها للاتصال بالعمل.', 'Location is turned off on your phone. Turn it on to go online.');
      action = PrimaryAction(label: s.t('شغّل الموقع', 'Turn on location'), icon: Icons.location_on, large: true, onPressed: () async {
        await controller.location.source.openLocationSettings();
        await controller.location.refreshAccess();
      });
    } else if (access == LocationAccess.denied) {
      hint = s.t('نحتاج إذن الموقع أثناء استخدام التطبيق لعرض الطلبات القريبة.', 'We need location permission while using the app to show nearby requests.');
      action = PrimaryAction(label: s.t('اسمح بالموقع', 'Allow location'), icon: Icons.my_location, large: true, onPressed: () async {
        await controller.allowLocation();
      });
    } else {
      hint = s.t('أنت غير متصل. لن تصلك طلبات.', 'You’re offline. You won’t get requests.');
      action = PrimaryAction(label: s.t('اتصل بالعمل', 'Go online'), icon: Icons.power_settings_new, large: true, onPressed: controller.busy ? null : controller.goOnline);
    }
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(
            liveRegion: true,
            child: Row(children: [
              Icon(p.online ? Icons.circle : Icons.circle_outlined, color: p.online ? WColors.success : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: WSpace.sm),
              Expanded(child: Text(p.online ? s.t('متصل', 'Online') : s.t('غير متصل', 'Offline'), style: t.headlineSmall)),
            ]),
          ),
          const SizedBox(height: WSpace.sm),
          Text(hint),
          if (p.activeVehicleId != null) _ActiveVehicle(uid: uid, vehicleId: p.activeVehicleId!, canChange: !p.online),
          const SizedBox(height: WSpace.lg),
          if (controller.busy && !p.online) ...[
            Text(s.t('نحدد موقعك ونتحقق من أهليتك…', 'Getting your location and checking eligibility…')),
            const SizedBox(height: WSpace.sm),
          ],
          action,
        ]),
      ),
    );
  }
}

class _ActiveVehicle extends StatefulWidget {
  const _ActiveVehicle({required this.uid, required this.vehicleId, required this.canChange});
  final String uid, vehicleId;
  final bool canChange;
  @override
  State<_ActiveVehicle> createState() => _ActiveVehicleState();
}

class _ActiveVehicleState extends State<_ActiveVehicle> {
  late final Stream<Live<List<Vehicle>>> _vehicles = context.services.vehicles.watchVehicles(widget.uid);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return StreamBuilder<Live<List<Vehicle>>>(
      stream: _vehicles,
      builder: (context, snap) {
        final v = snap.data?.data.where((v) => v.id == widget.vehicleId).firstOrNull;
        return Padding(
          padding: const EdgeInsets.only(top: WSpace.sm),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: WSpace.sm, children: [
            Text('${s.t('المركبة', 'Vehicle')}: ${v == null ? '…' : '${v.color} ${v.make} ${v.model} · ${ltr(v.plate)}'}'),
            if (widget.canChange)
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => VehiclesScreen(uid: widget.uid))),
                child: Text(s.t('تغيير', 'Change')),
              ),
          ]),
        );
      },
    );
  }
}
