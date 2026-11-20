import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/format.dart';
import '../../../app/services.dart';

Tone tripTone(TripState s) => switch (s) {
      TripState.completed => Tone.success,
      TripState.cancelled => Tone.warning,
      TripState.disputed => Tone.error,
      _ => Tone.info,
    };

/// Own trips, newest first, 20 per page.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.uid});
  final String uid;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _trips = <Trip>[];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _trips.clear();
        _cursor = null;
        _hasMore = true;
      }
    });
    try {
      final p = await context.services.history.page(widget.uid, after: _cursor);
      if (!mounted) return;
      setState(() {
        _trips.addAll(p.trips);
        _cursor = p.cursor;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget body;
    if (_trips.isEmpty && _loading) {
      body = WStateView.loading();
    } else if (_trips.isEmpty && _error != null) {
      body = WStateView.error(context, _error!, onRetry: () => _load(reset: true));
    } else if (_trips.isEmpty) {
      body = WStateView.empty(icon: Icons.history, title: s.t('لا توجد رحلات بعد', 'No trips yet'), body: s.t('تظهر رحلاتك هنا بعد أول رحلة.', 'Your trips appear here after your first one.'));
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView.separated(
          padding: const EdgeInsets.all(WSpace.lg),
          itemCount: _trips.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: WSpace.md),
          itemBuilder: (context, i) {
            if (i == _trips.length) {
              if (_error != null) {
                return Column(children: [
                  Text(s.error(_error is ApiFailure ? (_error as ApiFailure).code : 'network')),
                  TextButton(onPressed: _load, child: Text(s.retry)),
                ]);
              }
              if (_loading) return const Center(child: CircularProgressIndicator());
              return _hasMore ? OutlinedButton(onPressed: _load, child: Text(s.t('عرض المزيد', 'Show more'))) : const SizedBox.shrink();
            }
            return HistoryTile(trip: _trips[i]);
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: Text(s.t('رحلاتي', 'My trips'))), body: body);
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = trip;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: WSpace.sm, runSpacing: WSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            StatusBadge(tone: tripTone(t.state), label: s.state(t.state)),
            Text(dateTime(t.createdAt)),
          ]),
          const SizedBox(height: WSpace.sm),
          Text('${s.t('من', 'From')}: ${t.pickup.label}'),
          Text('${s.t('إلى', 'To')}: ${t.dropoff.label}'),
          if (t.fare != null) Text('${s.t('الأجرة', 'Fare')}: ${money(t.fare!, ar: s.ar)}'),
          if (t.cashAmount != null && t.cashAmount != t.fare) Text('${s.t('سجّلت نقداً', 'Cash recorded')}: ${money(t.cashAmount!, ar: s.ar)}'),
          if (t.cancellation != null) Text('${s.t('سبب الإلغاء', 'Cancel reason')}: ${s.cancelReason(t.cancellation!.reason)}'),
          if (t.riderRating != null) Text('${s.t('تقييم الراكب لك', 'Rider rated you')}: ${ltr('${t.riderRating!.stars}')} / ${ltr('5')}'),
        ]),
      ),
    );
  }
}
