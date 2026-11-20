import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/info_row.dart';
import '../../documents/presentation/account_status_card.dart';
import '../domain/driver_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.driver});
  final DriverState driver;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = driver.profile;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('ملفي', 'My profile'))),
      body: ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
        Section(children: [
          InfoRow(label: s.t('الاسم', 'Name'), value: p.name),
          InfoRow(label: s.t('الهاتف', 'Phone'), value: ltr(p.phone)),
          InfoRow(label: s.t('رحلات مكتملة', 'Completed trips'), value: ltr('${p.completedTrips}')),
          InfoRow(
            label: s.t('تقييمك', 'Your rating'),
            value: p.ratingAvg == null
                ? s.t('لا تقييمات بعد', 'No ratings yet')
                : '${ltr(p.ratingAvg!.toStringAsFixed(1))} / ${ltr('5')} · ${ltr('${driver.ratingCount}')} ${s.t('تقييم', 'ratings')}',
            emphasis: true,
          ),
        ]),
        const SizedBox(height: WSpace.lg),
        AccountStatusCard(status: p.status),
        const SizedBox(height: WSpace.lg),
        Text(s.t('لتغيير الاسم أو الهاتف تواصل مع الدعم.', 'To change your name or phone, contact support.')),
      ]),
    );
  }
}
