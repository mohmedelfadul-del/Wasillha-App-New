import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../trip/presentation/trip_screen.dart';
import '../application/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _c = HistoryController(context.deps.trips);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.loadMore();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Tone _tone(TripState st) => switch (st) {
        TripState.completed => Tone.success,
        TripState.cancelled => Tone.neutral,
        TripState.disputed || TripState.paymentPending => Tone.warning,
        _ => Tone.info,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('رحلاتي', 'My trips'))),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (!_c.loadedOnce) {
            if (_c.error != null) return WStateView.error(context, _c.error!, onRetry: _c.loadMore);
            return WStateView.loading(label: s.loading);
          }
          if (_c.trips.isEmpty && !_c.hasMore) {
            return WStateView.empty(icon: Icons.route_outlined, title: s.t('لا توجد رحلات بعد', 'No trips yet'), body: s.t('ستظهر رحلاتك هنا.', 'Your trips will appear here.'));
          }
          return RefreshIndicator(
            onRefresh: _c.refresh,
            child: ListView.separated(
              itemCount: _c.trips.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == _c.trips.length) return _footer(context);
                final t = _c.trips[i];
                final amount = t.cashAmount ?? t.fare ?? t.proposedFare;
                return ListTile(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: t.id))),
                  title: Text(t.dropoff.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: WSpace.xs),
                    child: Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      StatusBadge(tone: _tone(t.state), label: s.state(t.state)),
                      Text('${ltr('${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}')} ${clock(t.createdAt)}'),
                    ]),
                  ),
                  trailing: amount == null ? null : Text(money(amount, ar: s.ar)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final s = context.s;
    if (_c.loading) return const Padding(padding: EdgeInsets.all(WSpace.lg), child: Center(child: CircularProgressIndicator()));
    if (_c.error != null) {
      return Padding(
        padding: const EdgeInsets.all(WSpace.md),
        child: WBanner(tone: Tone.error, text: s.error(_c.error is ApiFailure ? (_c.error as ApiFailure).code : 'internal'), actionLabel: s.retry, onAction: _c.loadMore),
      );
    }
    if (!_c.hasMore) return const SizedBox(height: WSpace.xl);
    return Padding(
      padding: const EdgeInsets.all(WSpace.md),
      child: OutlinedButton(onPressed: _c.loadMore, child: Text(s.t('عرض المزيد', 'Show more'))),
    );
  }
}
