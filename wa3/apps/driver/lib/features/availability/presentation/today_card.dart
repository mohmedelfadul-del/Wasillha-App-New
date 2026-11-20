import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/services.dart';
import '../../../app/widgets/info_row.dart';
import '../../earnings/domain/earnings_repository.dart';

/// Today's completed trips and money, from the driver's own trips and ledger.
class TodayCard extends StatefulWidget {
  const TodayCard({super.key, required this.uid});
  final String uid;
  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard> {
  late Stream<Live<TodaySummary>> _today = _open();
  Stream<Live<TodaySummary>> _open() => context.services.earnings.watchToday(widget.uid, startOfDay(context.services.clock()));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Section(
      title: s.t('اليوم', 'Today'),
      children: [
        StreamBuilder<Live<TodaySummary>>(
          stream: _today,
          builder: (context, snap) {
            if (snap.hasError) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('تعذّر تحميل ملخص اليوم.', 'We couldn’t load today’s summary.')),
                TextButton(onPressed: () => setState(() => _today = _open()), child: Text(s.retry)),
              ]);
            }
            if (!snap.hasData) return const LinearProgressIndicator();
            final d = snap.data!.data;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              InfoRow(label: s.t('رحلات مكتملة', 'Completed trips'), value: ltr('${d.completedTrips}')),
              InfoRow(label: s.t('استلمت نقداً', 'You collected'), value: moneyMinor(d.collectedMinor, ar: s.ar)),
              InfoRow(label: s.t('صافي ربحك بعد العمولة', 'Your net after commission'), value: moneyMinor(d.netMinor, ar: s.ar)),
              if (snap.data!.fromCache) Text(s.staleData, style: const TextStyle(color: WColors.warning)),
            ]);
          },
        ),
      ],
    );
  }
}
