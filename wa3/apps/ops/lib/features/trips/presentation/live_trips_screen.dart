import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../../app/widgets/live_view.dart';
import '../../../app/widgets/now_builder.dart';
import '../domain/trips_repository.dart';
import 'trip_tile.dart';

/// Every non-terminal trip, least recently updated first. This list is the
/// primary view (and the fallback when no map is available).
class LiveTripsScreen extends StatefulWidget {
  const LiveTripsScreen({super.key});
  @override
  State<LiveTripsScreen> createState() => _LiveTripsScreenState();
}

class _LiveTripsScreenState extends State<LiveTripsScreen> {
  bool _flaggedOnly = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = context.services.trips;
    return LiveView<List<TripRecord>>(
      open: () => repo.live(),
      builder: (context, all) {
        final flagged = all.where((r) => r.flagged).length;
        final list = _flaggedOnly ? all.where((r) => r.flagged).toList() : all;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.md, WSpace.lg, WSpace.sm),
            child: Wrap(spacing: WSpace.md, runSpacing: WSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(s.t('${ltr('${all.length}')} رحلة جارية · ${ltr('$flagged')} تحتاج انتباهاً', '${ltr('${all.length}')} live trips · ${ltr('$flagged')} need attention')),
              FilterChip(
                label: Text(s.t('المتعثرة فقط', 'Flagged only')),
                selected: _flaggedOnly,
                onSelected: (v) => setState(() => _flaggedOnly = v),
              ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: list.isEmpty
                ? WStateView.empty(
                    icon: Icons.check_circle_outline,
                    title: _flaggedOnly ? s.t('لا رحلات متعثرة', 'No flagged trips') : s.t('لا توجد رحلات جارية', 'No live trips'),
                  )
                : NowBuilder(
                    builder: (context, now) => ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, i) => TripTile(record: list[i], now: now),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}
