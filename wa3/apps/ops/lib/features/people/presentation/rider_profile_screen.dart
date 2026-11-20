import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../domain/people_repository.dart';
import 'recent_trips.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key, required this.riderId});
  final String riderId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;
    return LiveView<RiderRecord?>(
      key: ValueKey(riderId),
      open: () => services.people.watchRider(riderId),
      isEmpty: (r) => r == null,
      empty: (_) => WStateView.empty(icon: Icons.person_off_outlined, title: s.t('الراكب غير موجود', 'Rider not found')),
      builder: (context, r) => NowBuilder(
        builder: (context, now) => PageBody(children: [
          Semantics(header: true, child: Text(r!.name.isEmpty ? s.t('راكب', 'Rider') : r.name, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: WSpace.sm),
          Field(s.t('الهاتف', 'Phone'), r.phone.isEmpty ? '—' : ltr(r.phone), selectable: true),
          Field(s.t('المعرّف', 'ID'), ltr(r.uid), selectable: true),
          if (r.lang != null) Field(s.t('اللغة', 'Language'), r.lang == 'ar' ? 'العربية' : 'English'),
          if (r.createdAt != null) Field(s.t('مسجّل منذ', 'Registered'), dateTime(r.createdAt!)),
          RecentTrips(open: () => services.trips.recentForRider(riderId), now: now),
        ]),
      ),
    );
  }
}
