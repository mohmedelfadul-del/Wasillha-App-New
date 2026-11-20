import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/live_view.dart';
import '../../trips/domain/trips_repository.dart';
import '../../trips/presentation/trip_tile.dart';

class RecentTrips extends StatelessWidget {
  const RecentTrips({super.key, required this.open, required this.now});
  final Stream<Live<List<TripRecord>>> Function() open;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(s.t('أحدث الرحلات', 'Recent trips')),
      LiveSection<List<TripRecord>>(
        open: open,
        isEmpty: (l) => l.isEmpty,
        emptyText: s.t('لا توجد رحلات.', 'No trips.'),
        builder: (context, list) => Column(children: [
          for (final r in list) ...[TripTile(record: r, now: now, showAgeInState: false), const Divider()],
        ]),
      ),
    ]);
  }
}
