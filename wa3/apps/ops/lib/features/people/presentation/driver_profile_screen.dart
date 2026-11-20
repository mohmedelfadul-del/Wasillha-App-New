import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/sections.dart';
import '../../../app/services.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../../auth/application/session_controller.dart';
import '../../kyc/presentation/kyc_labels.dart';
import 'recent_trips.dart';

Tone driverStatusTone(DriverStatus d) => switch (d) {
      DriverStatus.approved => Tone.success,
      DriverStatus.underReview => Tone.info,
      DriverStatus.onboarding => Tone.neutral,
      DriverStatus.suspended => Tone.error,
    };

String driverStatusLabel(S s, DriverStatus d) => switch (d) {
      DriverStatus.approved => s.t('معتمد', 'Approved'),
      DriverStatus.underReview => s.t('قيد المراجعة', 'Under review'),
      DriverStatus.onboarding => s.t('في التسجيل', 'Onboarding'),
      DriverStatus.suspended => s.t('موقوف', 'Suspended'),
    };

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key, required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;
    final role = context.role;
    return LiveView<DriverProfile?>(
      key: ValueKey(driverId),
      open: () => services.people.watchDriver(driverId),
      isEmpty: (d) => d == null,
      empty: (_) => WStateView.empty(icon: Icons.person_off_outlined, title: s.t('السائق غير موجود', 'Driver not found')),
      builder: (context, d) => NowBuilder(
        builder: (context, now) => PageBody(children: [
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Semantics(header: true, child: Text(d!.name.isEmpty ? s.t('سائق', 'Driver') : d.name, style: Theme.of(context).textTheme.titleLarge)),
            StatusBadge(tone: driverStatusTone(d.status), label: driverStatusLabel(s, d.status)),
            StatusBadge(tone: d.online ? Tone.success : Tone.neutral, label: d.online ? s.t('متصل', 'Online') : s.t('غير متصل', 'Offline')),
          ]),
          const SizedBox(height: WSpace.sm),
          Field(s.t('الهاتف', 'Phone'), d.phone.isEmpty ? '—' : ltr(d.phone), selectable: true),
          Field(s.t('المعرّف', 'ID'), ltr(d.uid), selectable: true),
          Field(s.t('التقييم', 'Rating'), d.ratingAvg == null ? '—' : ltr(d.ratingAvg!.toStringAsFixed(2))),
          Field(s.t('رحلات مكتملة', 'Completed trips'), ltr('${d.completedTrips}')),
          if (d.zoneId != null) Field(s.t('المنطقة', 'Zone'), d.zoneId!),
          if (d.activeCategory != null) Field(s.t('الفئة النشطة', 'Active category'), s.category(d.activeCategory!)),
          if (d.offlineReason != null) Field(s.t('سبب عدم الاتصال', 'Offline reason'), d.offlineReason == 'location_lost' ? s.t('انقطع الموقع', 'Location lost') : d.offlineReason!),
          Wrap(spacing: WSpace.sm, children: [
            if (d.activeTripId != null)
              TextButton.icon(onPressed: () => openTrip(context, d.activeTripId!), icon: const Icon(Icons.route_outlined), label: Text(s.t('الرحلة الحالية', 'Current trip'))),
            if (Can.viewMoney(role))
              TextButton.icon(onPressed: () => openSettlement(context, d.uid), icon: const Icon(Icons.payments_outlined), label: Text(s.t('النقد والعمولة', 'Cash & commission'))),
          ]),
          SectionTitle(s.t('الوثائق', 'Documents')),
          LiveSection<List<ReviewDocument>>(
            open: () => services.people.driverDocuments(driverId),
            isEmpty: (l) => l.isEmpty,
            emptyText: s.t('لم تُرسل وثائق.', 'No documents submitted.'),
            builder: (context, docs) => Column(children: [
              for (final doc in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(docTypeLabel(s, doc.type)),
                  subtitle: doc.reason == null ? null : Text(doc.reason!),
                  trailing: StatusBadge(tone: reviewTone(doc.status), label: s.review(doc.status)),
                  onTap: () => openReview(context, doc.path),
                ),
            ]),
          ),
          SectionTitle(s.t('المركبات', 'Vehicles')),
          LiveSection<List<Vehicle>>(
            open: () => services.people.vehicles(driverId),
            isEmpty: (l) => l.isEmpty,
            emptyText: s.t('لا توجد مركبات.', 'No vehicles.'),
            builder: (context, vs) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final v in vs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: WSpace.xs),
                  child: Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('${v.color} ${v.make} ${v.model} ${ltr('${v.year}')} · ${ltr(v.plate)} · ${s.category(v.category)}'),
                    if (v.id == d.activeVehicleId) StatusBadge(tone: Tone.info, label: s.t('نشطة', 'Active')),
                    StatusBadge(
                      tone: v.approved ? Tone.success : v.status == 'changesRequested' ? Tone.warning : Tone.info,
                      label: v.approved ? s.t('معتمدة', 'Approved') : v.status == 'changesRequested' ? s.t('مطلوب تعديل', 'Changes requested') : s.t('قيد المراجعة', 'Under review'),
                    ),
                  ]),
                ),
            ]),
          ),
          RecentTrips(open: () => services.trips.recentForDriver(driverId), now: now),
        ]),
      ),
    );
  }
}
