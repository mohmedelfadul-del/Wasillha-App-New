import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';

enum _Filter { all, rides, delivery, food }

bool _matches(_Filter f, ServiceType s) => switch (f) {
      _Filter.all => true,
      _Filter.rides => s == ServiceType.car || s == ServiceType.raksha || s == ServiceType.moto,
      _Filter.delivery => s == ServiceType.delivery || s == ServiceType.parcel,
      _Filter.food => s == ServiceType.food,
    };

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<List<Trip>> _trips = _backend.myTrips();
  late final Stream<UserProfile?> _profile = _backend.profile();
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: StreamBuilder<List<Trip>>(
            stream: _trips,
            builder: (context, snap) {
              final trips = snap.data;
              final shown = (trips ?? const <Trip>[]).where((t) => _matches(_filter, t.service)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              // Group by calendar day.
              final groups = <(DateTime, List<Trip>)>[];
              for (final t in shown) {
                if (groups.isNotEmpty && sameDay(groups.last.$1, t.createdAt)) {
                  groups.last.$2.add(t);
                } else {
                  groups.add((t.createdAt, [t]));
                }
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  AccountHeader(
                    title: s.t('HISTORY · السجل', 'السجل · HISTORY'),
                    onBack: () => context.tab('home'),
                    trailing: SquareBtn(icon: 'search', onTap: () => context.go('search')),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SerifHeadline(s.t("Where you've ", 'أين '), s.t('been.', 'كنت.')),
                      const SizedBox(height: 14),
                      StreamBuilder<UserProfile?>(
                        stream: _profile,
                        builder: (context, p) => _Stats(trips: trips ?? const [], profile: p.data),
                      ),
                    ]),
                  ),
                  _filters(s),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
                    child: trips == null
                        ? const Loading()
                        : groups.isEmpty
                            ? EmptyNote(
                                icon: 'history',
                                text: s.t('No trips yet. Your rides and deliveries will show up here.',
                                    'لا توجد رحلات بعد. ستظهر رحلاتك وطلباتك هنا.'))
                            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                for (final g in groups) ...[
                                  SectionLabel(dayLabel(g.$1, s.ar)),
                                  for (final t in g.$2) ...[
                                    _TripCard(trip: t),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 10),
                                ],
                              ]),
                  ),
                ],
              );
            },
          ),
        ),
        const BottomNav(active: 'history'),
      ]),
    );
  }

  Widget _filters(AppState s) {
    final labels = {
      _Filter.all: s.t('All', 'الكل'),
      _Filter.rides: s.t('Rides', 'المشاوير'),
      _Filter.delivery: s.t('Delivery', 'التوصيل'),
      _Filter.food: s.t('Food', 'الأكل'),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
      child: Row(children: [
        for (final f in _Filter.values) ...[
          GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _filter == f ? W.text : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: _filter == f ? null : Border.all(color: W.border, width: 0.5),
              ),
              child: Text(labels[f]!,
                  style: W.sans(size: 12.5, weight: FontWeight.w500, color: _filter == f ? Colors.white : W.text)),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ]),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.trips, required this.profile});
  final List<Trip> trips;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final done = trips.where((t) => t.status == TripStatus.completed);
    final km = done.fold<double>(0, (a, t) => a + t.distanceKm);
    Widget stat(String value, String label, {String? unit}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: value, style: W.serif(size: 28)),
            if (unit != null) TextSpan(text: ' $unit', style: W.mono(size: 13, color: W.text3, letterSpacing: 0)),
          ])),
          const SizedBox(height: 2),
          MonoLabel(label, size: 9, spacing: 0.22),
        ]);
    Widget sep() => Container(width: 0.5, height: 40, margin: const EdgeInsets.symmetric(horizontal: 18), color: W.border2);
    return Row(children: [
      stat('${done.length}', s.t('TRIPS', 'رحلات')),
      sep(),
      stat(km.toStringAsFixed(km >= 100 ? 0 : 1), s.t('DISTANCE', 'المسافة'), unit: s.t('km', 'كم')),
      sep(),
      stat((profile?.rating ?? 5).toStringAsFixed(2), s.t('YOUR RATING', 'تقييمك')),
    ]);
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = trip;
    final completed = t.status == TripStatus.completed;
    final meta = [
      DateFormat('HH:mm').format(t.createdAt),
      '${t.distanceKm.toStringAsFixed(1)} ${s.t('km', 'كم')} · ${t.etaMin} ${s.t('min', 'د')}',
      if (t.driverName != null && t.driverName!.isNotEmpty) t.driverName!,
    ].join(' · ');

    Widget pill(String label, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: W.border, width: 0.5),
            ),
            child: Text(label, style: W.sans(size: 11.5)),
          ),
        );

    return GestureDetector(
      onTap: completed ? () => showReceipt(context, t) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(12)),
              child: WIcon(t.service.icon, size: 18, strokeWidth: 1.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(t.pickup.label(s.ar),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: WIcon('arrow', size: 12, color: W.text3),
                  ),
                  Flexible(
                    child: Text(t.dropoff.label(s.ar),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(meta.toUpperCase(),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: W.mono(size: 10, color: W.text3, letterSpacing: 0.14)),
              ]),
            ),
            if (!completed) ...[
              const SizedBox(width: 8),
              _StatusBadge(status: t.status),
            ],
          ]),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: W.border2, width: 0.5))),
            child: Row(children: [
              pill(s.t('Re-book', 'إعادة الحجز'), () {
                final st = context.read<AppState>();
                st.chooseService(t.service);
                st.setPickup(t.pickup);
                st.setDropoff(t.dropoff);
                context.go('booking');
              }),
              if (completed) ...[
                const SizedBox(width: 8),
                pill(s.t('Receipt', 'الإيصال'), () => showReceipt(context, t)),
              ],
              const Spacer(),
              if (completed || t.isActive)
                Text.rich(TextSpan(children: [
                  TextSpan(text: sdg(t.fare), style: W.serif(size: 18, letterSpacing: -0.18)),
                  TextSpan(text: ' ${s.t('SDG', 'ج.س')}', style: W.mono(size: 10, color: W.text3, letterSpacing: 0)),
                ]))
              else
                MonoLabel(s.t('NO CHARGE', 'بدون رسوم'), size: 11),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cancelled = status == TripStatus.cancelled;
    final label = switch (status) {
      TripStatus.cancelled => s.t('CANCELLED', 'ملغاة'),
      TripStatus.requested => s.t('REQUESTED', 'قيد الطلب'),
      TripStatus.accepted || TripStatus.arriving => s.t('ARRIVING', 'في الطريق'),
      TripStatus.inProgress => s.t('ON TRIP', 'جارية'),
      TripStatus.completed => s.t('COMPLETED', 'مكتملة'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cancelled ? const Color(0xFFF3D7D2) : s.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: MonoLabel(label, size: 9, spacing: 0.2, color: cancelled ? const Color(0xFFA23B25) : s.accent),
    );
  }
}

/// Receipt bottom sheet for a completed trip.
void showReceipt(BuildContext context, Trip t) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      final s = ctx.watch<AppState>();
      final base = t.fare;
      Widget line(String k, String v, {bool strong = false}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Expanded(child: Text(k, style: W.sans(size: 13.5, color: strong ? W.text : W.text2, weight: strong ? FontWeight.w600 : FontWeight.w400))),
              Text(v, style: W.mono(size: strong ? 15 : 13, weight: strong ? FontWeight.w600 : FontWeight.w400, color: W.text, letterSpacing: 0)),
            ]),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: MonoLabel(s.t('RECEIPT · ${t.service.label.toUpperCase()}', 'إيصال · ${t.service.labelAr}'), spacing: 0.3)),
              MonoLabel('#${t.id.length > 6 ? t.id.substring(0, 6).toUpperCase() : t.id.toUpperCase()}'),
            ]),
            const SizedBox(height: 10),
            Text.rich(TextSpan(children: [
              TextSpan(text: sdg(base + t.tip), style: W.serif(size: 52)),
              TextSpan(text: ' ${s.t('SDG', 'ج.س')}', style: W.mono(size: 13, color: W.text2)),
            ])),
            const SizedBox(height: 4),
            Text(DateFormat('EEE d MMM yyyy · HH:mm', s.ar ? 'ar' : 'en').format(t.createdAt), style: W.sans(size: 12.5, color: W.text2)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _Stop(icon: 'pindot', label: t.pickup.label(s.ar)),
                const SizedBox(height: 10),
                _Stop(icon: 'pin', label: t.dropoff.label(s.ar)),
              ]),
            ),
            const SizedBox(height: 14),
            line(s.t('Trip fare', 'أجرة الرحلة'), '${sdg(base)} ${s.t('SDG', 'ج.س')}'),
            if (t.tip > 0) line(s.t('Tip', 'إكرامية'), '${sdg(t.tip)} ${s.t('SDG', 'ج.س')}'),
            line(s.t('Distance', 'المسافة'), '${t.distanceKm.toStringAsFixed(1)} ${s.t('km', 'كم')}'),
            line(s.t('Paid with', 'الدفع'), t.payment == 'cash' ? s.t('Cash', 'نقدًا') : s.t('Wasilha Wallet', 'محفظة وصلها')),
            if (t.driverName != null && t.driverName!.isNotEmpty)
              line(s.t('Driver', 'السائق'), [t.driverName!, if (t.driverPlate != null && t.driverPlate!.isNotEmpty) t.driverPlate!].join(' · ')),
            if (t.rating != null) line(s.t('Your rating', 'تقييمك'), '${'★' * t.rating!}${'☆' * (5 - t.rating!).clamp(0, 5)}'),
            const Divider(height: 22, color: W.border),
            line(s.t('Total', 'الإجمالي'), '${sdg(base + t.tip)} ${s.t('SDG', 'ج.س')}', strong: true),
            const SizedBox(height: 18),
            Btn(s.t('Done', 'تم'), full: true, variant: BtnVariant.dark, onTap: () => Navigator.of(ctx).pop()),
          ]),
        ),
      );
    },
  );
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.label});
  final String icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        WIcon(icon, size: 16, color: icon == 'pin' ? context.watch<AppState>().accent : W.text),
        const SizedBox(width: 10),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500))),
      ]);
}
