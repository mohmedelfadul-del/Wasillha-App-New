import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'driver_nav.dart';
import 'driver_widgets.dart';

/// Wasilha's commission on trip fares (tips are not commissioned).
const _serviceFeeRate = 0.15;

/// 19 — Driver earnings, aggregated from completed `driverTrips()`.
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  /// today | week | month
  String _period = 'week';
  late final Stream<List<Trip>> _trips = context.read<WasilhaBackend>().driverTrips();

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// [start, end) of the selected period, and of the one before it.
  (DateTime, DateTime) _range({bool previous = false}) {
    final days = switch (_period) { 'today' => 1, 'week' => 7, _ => 30 };
    final end = _today.add(const Duration(days: 1));
    final start = end.subtract(Duration(days: days));
    if (!previous) return (start, end);
    return (start.subtract(Duration(days: days)), start);
  }

  List<Trip> _inRange(List<Trip> all, (DateTime, DateTime) r) =>
      all.where((t) => !t.createdAt.isBefore(r.$1) && t.createdAt.isBefore(r.$2)).toList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        StreamBuilder<List<Trip>>(
          stream: _trips,
          builder: (context, snap) {
            final all = completedTrips(snap.data ?? const []);
            final trips = _inRange(all, _range());
            final prev = _inRange(all, _range(previous: true));
            return ListView(
              padding: EdgeInsets.fromLTRB(18, top + 12, 18, 120),
              children: [
                _topBar(s),
                if (!snap.hasData)
                  const Padding(padding: EdgeInsets.all(60), child: Center(child: MiniSpinner()))
                else ...[
                  _hero(s, trips, prev),
                  const SizedBox(height: 20),
                  _periodToggle(s),
                  const SizedBox(height: 20),
                  _WeekChart(trips: all, today: _today),
                  const SizedBox(height: 20),
                  _breakdown(s, trips),
                  const SizedBox(height: 16),
                  _cashOut(s),
                  const SizedBox(height: 24),
                  _tripList(s, trips),
                ],
              ],
            );
          },
        ),
        const DriverNav(active: 'driverEarnings'),
      ]),
    );
  }

  Widget _topBar(AppState s) => Row(children: [
        SquareBtn(
          onTap: () => driverBack(context),
          child: const WIcon('back', size: 18, strokeWidth: 1.7),
        ),
        Expanded(child: Center(child: MonoLabel(s.t('Earnings · الأرباح', 'الأرباح'), spacing: 0.3))),
        SquareBtn(
          shadow: false,
          onTap: () => comingSoon(context, s.t('Statements are coming soon', 'كشوفات الحساب قريباً')),
          child: const WIcon('receipt', size: 16, strokeWidth: 1.7),
        ),
      ]);

  Widget _hero(AppState s, List<Trip> trips, List<Trip> prev) {
    final total = sumEarnings(trips);
    final prevTotal = sumEarnings(prev);
    final change = prevTotal == 0 ? null : (total - prevTotal) / prevTotal * 100;
    final up = (change ?? 0) >= 0;
    final km = trips.fold<double>(0, (a, t) => a + t.distanceKm);
    final label = switch (_period) {
      'today' => s.t('Today', 'اليوم'),
      'week' => s.t('This week', 'هذا الأسبوع'),
      _ => s.t('Last 30 days', 'آخر ٣٠ يوماً'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MonoLabel(label, spacing: 0.3),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(sdg(total), style: W.serif(size: 76, height: 0.95, letterSpacing: -2.6)),
            ),
          ),
          const SizedBox(width: 6),
          Text('SDG', style: W.mono(size: 13, color: W.text2)),
        ]),
        const SizedBox(height: 8),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
          if (change != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (up ? W.success : W.danger).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${up ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)}% ${s.t('vs prev', 'مقارنة بالسابق')}',
                style: W.sans(size: 12, color: up ? W.success : W.danger),
              ),
            ),
          Text(
            s.t('· ${trips.length} trips · ${km.toStringAsFixed(1)} km driven',
                '· ${trips.length} رحلة · ${km.toStringAsFixed(1)} كم'),
            style: W.sans(size: 11, color: W.text3),
          ),
        ]),
      ]),
    );
  }

  Widget _periodToggle(AppState s) {
    final items = [
      ('today', s.t('Today', 'اليوم')),
      ('week', s.t('Week', 'الأسبوع')),
      ('month', s.t('Month', 'الشهر')),
    ];
    return Row(children: [
      for (final (id, label) in items) ...[
        if (id != 'today') const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _period = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _period == id ? W.text : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: _period == id ? null : Border.all(color: W.border, width: 0.5),
              ),
              child: Text(label,
                  style: W.sans(size: 12.5, weight: FontWeight.w500, color: _period == id ? Colors.white : W.text)),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _breakdown(AppState s, List<Trip> trips) {
    final accent = s.accent;
    final byService = <ServiceType, List<Trip>>{};
    for (final t in trips) {
      byService.putIfAbsent(t.service, () => []).add(t);
    }
    final services = byService.entries.toList()
      ..sort((a, b) => sumEarnings(b.value).compareTo(sumEarnings(a.value)));
    final tipped = trips.where((t) => t.tip > 0).toList();
    final tips = tipped.fold<int>(0, (a, t) => a + t.tip);
    final fares = trips.fold<int>(0, (a, t) => a + t.fare);
    final fee = (fares * _serviceFeeRate).round();

    final rows = <(String, String, String, Color)>[
      for (final e in services)
        (
          e.key.title(s.ar),
          s.t('${e.value.length} trips', '${e.value.length} رحلة'),
          sdg(e.value.fold<int>(0, (a, t) => a + t.fare)),
          W.text,
        ),
      (s.t('Tips', 'بقشيش'), s.t('${tipped.length} riders', '${tipped.length} راكب'), '+ ${sdg(tips)}', accent),
      (s.t('Wasilha service fee', 'عمولة وصلها'), '${(_serviceFeeRate * 100).round()}%', '− ${sdg(fee)}', W.text2),
      (s.t('Net payout', 'صافي الأرباح'), s.t('After fees', 'بعد العمولة'), sdg(fares + tips - fee), W.text),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MonoLabel(s.t('Breakdown', 'تفاصيل'), size: 9.5, spacing: 0.3),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: W.border, width: 0.5)) : null,
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rows[i].$1,
                        style: W.sans(size: 13.5, weight: i == rows.length - 1 ? FontWeight.w600 : FontWeight.w500)),
                    const SizedBox(height: 2),
                    MonoLabel(rows[i].$2, size: 9.5, spacing: 0.18),
                  ]),
                ),
                Text(rows[i].$3, style: W.mono(size: 14, weight: FontWeight.w600, color: rows[i].$4, letterSpacing: 0.02)),
              ]),
            ),
        ]),
      ),
    ]);
  }

  Widget _cashOut(AppState s) {
    final accent = s.accent;
    return GestureDetector(
      onTap: () => comingSoon(context, s.t('Bank cash-out is coming soon', 'السحب إلى البنك قريباً')),
      child: Container(
        height: 56,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(16)),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          AccentGlow(color: accent, size: 130, top: -58, end: -38, alpha: 0.31),
          Row(children: [
            const WIcon('wallet', size: 18, strokeWidth: 1.7, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.t('Cash out to bank', 'سحب إلى البنك'),
                  style: W.sans(size: 14.5, weight: FontWeight.w500, color: Colors.white)),
            ),
            Text('BOK · 4471', style: W.mono(size: 11, color: const Color(0x99FFFFFF))),
            const SizedBox(width: 8),
            const WIcon('arrow', size: 16, strokeWidth: 1.7, color: Colors.white),
          ]),
        ]),
      ),
    );
  }

  Widget _tripList(AppState s, List<Trip> trips) {
    final accent = s.accent;
    final shown = trips.take(20).toList();
    final title = switch (_period) {
      'today' => s.t("Today's trips", 'رحلات اليوم'),
      'week' => s.t("This week's trips", 'رحلات الأسبوع'),
      _ => s.t('Recent trips', 'الرحلات الأخيرة'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: MonoLabel(title, size: 9.5, spacing: 0.3)),
        Text('${shown.length} / ${trips.length}', style: W.mono(size: 10)),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: shown.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Text(s.t('No completed trips in this period yet.', 'لا توجد رحلات مكتملة في هذه الفترة.'),
                      style: W.sans(size: 12.5, color: W.text2)),
                ),
              )
            : Column(children: [
                for (var i = 0; i < shown.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: i < shown.length - 1 ? const Border(bottom: BorderSide(color: W.border, width: 0.5)) : null,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          _period == 'today' ? hhmm(shown[i].createdAt) : '${shown[i].createdAt.day}/${shown[i].createdAt.month}',
                          style: W.mono(size: 10.5, letterSpacing: 0.08),
                        ),
                      ),
                      Expanded(
                        child: Row(children: [
                          Flexible(
                            child: Text(shown[i].pickup.label(s.ar),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: W.sans(size: 12.5, weight: FontWeight.w500)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: WIcon('arrow', size: 11, color: W.text3),
                          ),
                          Flexible(
                            child: Text(shown[i].dropoff.label(s.ar),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: W.sans(size: 12.5, weight: FontWeight.w500)),
                          ),
                        ]),
                      ),
                      if (shown[i].tip > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
                          child: MonoLabel(s.t('Tip', 'بقشيش'), size: 8.5, color: accent, spacing: 0.18),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(sdg(tripEarning(shown[i])), style: W.mono(size: 12.5, weight: FontWeight.w600, color: W.text, letterSpacing: 0.02)),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}

/// Last 7 days of earnings as simple bars; today in the accent colour.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.trips, required this.today});
  final List<Trip> trips;
  final DateTime today;

  static const _en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _ar = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final values = [for (final d in days) sumEarnings(trips.where((t) => sameDay(t.createdAt, d)))];
    final max = values.fold<int>(0, math.max);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: SizedBox(
        height: 140,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final frac = max == 0 ? 0.0 : values[i] / max;
                    final isToday = i == 6;
                    final h = math.max(4.0, (c.maxHeight - 16) * frac);
                    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (frac > 0.85)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              values[i] >= 1000 ? '${(values[i] / 1000).toStringAsFixed(1)}K' : '${values[i]}',
                              style: W.mono(size: 8.5, color: W.text, letterSpacing: 0.1),
                            ),
                          ),
                        ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 4, end: h),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Container(
                          height: v,
                          decoration: BoxDecoration(
                            color: isToday ? accent : W.text,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isToday
                                ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
                                : null,
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  (s.ar ? _ar : _en)[days[i].weekday - 1],
                  style: W.mono(
                    size: 9,
                    color: i == 6 ? accent : W.text3,
                    weight: i == 6 ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
