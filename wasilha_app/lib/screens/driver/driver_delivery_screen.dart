import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/map_view.dart';
import '../../widgets/w_icon.dart';
import 'driver_nav.dart';
import 'driver_widgets.dart';

/// 20 — Active trip, driver side: accepted → arriving → in progress → completed.
class DriverDeliveryScreen extends StatefulWidget {
  const DriverDeliveryScreen({super.key});

  @override
  State<DriverDeliveryScreen> createState() => _DriverDeliveryScreenState();
}

class _DriverDeliveryScreenState extends State<DriverDeliveryScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<Trip?> _stream = _backend.driverActiveTrip();
  Timer? _clock;

  /// Kept once the trip is completed (the active-trip stream then goes empty).
  Trip? _completed;
  TripStatus? _lastStatus;
  DateTime _phaseStart = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _advance(Trip t) async {
    if (t.status == TripStatus.completed) {
      context.root('driverHome');
      return;
    }
    final next = switch (t.status) {
      TripStatus.requested || TripStatus.accepted => TripStatus.arriving,
      TripStatus.arriving => TripStatus.inProgress,
      _ => TripStatus.completed,
    };
    setState(() => _busy = true);
    try {
      await _backend.setTripStatus(t.id, next);
      if (next == TripStatus.completed && mounted) {
        setState(() => _completed = t.copyWith(status: TripStatus.completed));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaps(Trip t) async {
    final dest = t.status == TripStatus.inProgress ? t.dropoff : t.pickup;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${dest.lat},${dest.lng}&travelmode=driving');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open Google Maps');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _call() async {
    try {
      await launchUrl(Uri.parse('tel:'));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: StreamBuilder<Trip?>(
        stream: _stream,
        builder: (context, snap) {
          final trip = _completed ?? snap.data;
          if (trip == null) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: MiniSpinner());
            }
            return _NoTrip(s: s);
          }
          if (trip.status != _lastStatus) {
            _lastStatus = trip.status;
            _phaseStart = DateTime.now();
          }
          return _body(s, trip);
        },
      ),
    );
  }

  Widget _body(AppState s, Trip t) {
    final accent = s.accent;
    final phase = switch (t.status) {
      TripStatus.requested || TripStatus.accepted => 0,
      TripStatus.arriving => 1,
      TripStatus.inProgress => 2,
      _ => 3,
    };
    final rider = t.riderName.isEmpty ? s.t('Rider', 'الراكب') : t.riderName;
    final pickupEta = pickupEtaMin(t);
    final phases = [
      (
        s.t('Trip accepted', 'تم قبول الرحلة'),
        s.t('$rider · $pickupEta min · ${t.pickup.label(false)}', '$rider · $pickupEta د · ${t.pickup.label(true)}'),
        s.t('Start driving to pickup', 'ابدأ التوجه للاستلام'),
        'car',
      ),
      (
        s.t('Heading to pickup', 'متجه للاستلام'),
        s.t('${t.pickup.label(false)} · ~$pickupEta min', '${t.pickup.label(true)} · ~$pickupEta د'),
        s.t('Arrived · start trip', 'وصلت · بدء الرحلة'),
        'pin',
      ),
      (
        s.t('On trip', 'في الرحلة'),
        s.t('To ${t.dropoff.label(false)} · ${t.etaMin} min', 'إلى ${t.dropoff.label(true)} · ${t.etaMin} د'),
        s.t('Complete trip', 'إنهاء الرحلة'),
        'nav',
      ),
      (
        s.t('Complete', 'اكتملت'),
        t.payment == 'cash'
            ? s.t('Collect ${sdg(t.fare)} SDG in cash', 'استلم ${sdg(t.fare)} ج.س نقداً')
            : s.t('${sdg(t.fare)} SDG paid to wallet', 'تم استلام ${sdg(t.fare)} ج.س في المحفظة'),
        s.t('Back to drive', 'العودة للوحة'),
        'check',
      ),
    ];
    final p = phases[phase];
    final elapsed = DateTime.now().difference(_phaseStart).inSeconds;
    final clock = '${elapsed ~/ 3600}:${((elapsed ~/ 60) % 60).toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}';
    final top = MediaQuery.paddingOf(context).top;

    return Stack(children: [
      Positioned.fill(
        child: WMap(pickup: t.pickup, dropoff: t.dropoff, showRoute: true, pulse: true, padding: const EdgeInsets.only(bottom: 360)),
      ),
      PositionedDirectional(
        top: top + 12,
        start: 16,
        end: 16,
        child: Column(children: [
          Row(children: [
            SquareBtn(
              onTap: () => driverBack(context),
              child: const WIcon('back', size: 18, strokeWidth: 1.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Glass(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(children: [
                  PulseDot(color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MonoLabel(s.t('Active trip', 'رحلة نشطة'), size: 9),
                      Text(p.$1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500)),
                    ]),
                  ),
                  Text(phase == 3 ? '−' : clock,
                      style: W.mono(size: 11, color: W.text, weight: FontWeight.w600, letterSpacing: 0.04)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= phase ? accent : const Color(0x1F000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ]),
        ]),
      ),

      // Trip sheet
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
          decoration: const BoxDecoration(
            color: W.screenBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Color(0x1A140F1E), blurRadius: 32, offset: Offset(0, -10))],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 28 + MediaQuery.paddingOf(context).bottom),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Avatar(size: 52, label: initialsOf(t.riderName), tone: 'purple'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel(s.t('Your rider', 'الراكب'), size: 9),
                    const SizedBox(height: 2),
                    Text(rider, overflow: TextOverflow.ellipsis, style: W.serif(size: 22)),
                    const SizedBox(height: 4),
                    Row(children: [
                      WIcon(t.service.icon, size: 12, color: W.text2),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${t.service.title(s.ar)} · ${t.payment == 'cash' ? s.t('Cash', 'نقداً') : s.t('Wallet', 'محفظة')} · ${sdg(t.fare)} ${s.t('SDG', 'ج.س')}',
                          overflow: TextOverflow.ellipsis,
                          style: W.sans(size: 11.5, color: W.text2),
                        ),
                      ),
                    ]),
                  ]),
                ),
                SquareBtn(
                  size: 44,
                  color: W.text,
                  shadow: false,
                  onTap: _call,
                  child: const WIcon('phone', size: 16, strokeWidth: 1.7, color: Colors.white),
                ),
                const SizedBox(width: 6),
                SquareBtn(
                  size: 44,
                  shadow: false,
                  border: Border.all(color: W.border, width: 0.5),
                  onTap: () => comingSoon(context, s.t('In-app chat is coming soon', 'المحادثة داخل التطبيق قريباً')),
                  child: const WIcon('chat', size: 16, strokeWidth: 1.7),
                ),
              ]),
              const SizedBox(height: 16),

              // Route summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: W.border, width: 0.5),
                ),
                child: Row(children: [
                  RouteDots(accent: accent, gap: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.pickup.label(s.ar),
                          overflow: TextOverflow.ellipsis,
                          style: W.sans(size: 13, weight: FontWeight.w500, color: phase >= 2 ? W.text3 : W.text)),
                      const SizedBox(height: 14),
                      Text(t.dropoff.label(s.ar), overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500)),
                    ]),
                  ),
                  Text('${t.distanceKm.toStringAsFixed(1)} km', style: W.mono(size: 10.5, color: W.text2)),
                ]),
              ),
              if (t.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('“${t.note}”', style: W.sans(size: 12, color: W.text2)),
              ],

              // Phase status block
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: phase == 3 ? accent.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: phase == 3 ? accent.withValues(alpha: 0.25) : W.border,
                    width: phase == 3 ? 1 : 0.5,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: phase == 3 ? accent : (phase >= 2 ? W.success : W.surface2),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: WIcon(p.$4, size: 20, strokeWidth: 1.7, color: phase >= 2 ? Colors.white : W.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.$1, style: W.sans(size: 14, weight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(p.$2, style: W.sans(size: 12, color: W.text2)),
                    ]),
                  ),
                  if (phase == 3) Text('+${sdg(t.fare)}', style: W.serif(size: 22, color: accent)),
                ]),
              ),

              if (phase < 3)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openMaps(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      WIcon('nav', size: 14, strokeWidth: 1.8, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phase == 2
                              ? s.t('Navigate to drop-off in Google Maps', 'الملاحة إلى الوجهة في خرائط جوجل')
                              : s.t('Navigate to pickup in Google Maps', 'الملاحة إلى نقطة الاستلام في خرائط جوجل'),
                          style: W.sans(size: 12, color: W.text2),
                        ),
                      ),
                      const WIcon('chevron', size: 12, color: W.text2),
                    ]),
                  ),
                ),

              const SizedBox(height: 14),
              _Cta(
                label: p.$3,
                icon: phase == 3 ? 'home' : 'arrow',
                dark: phase == 3,
                loading: _busy,
                onTap: () => _advance(t),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.icon, required this.dark, required this.loading, required this.onTap});
  final String label;
  final String icon;
  final bool dark;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final bg = dark ? W.text : accent;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.27), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const MiniSpinner(color: Colors.white)
          else ...[
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: W.sans(size: 15, weight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            WIcon(icon, size: 18, strokeWidth: 1.8, color: Colors.white),
          ],
        ]),
      ),
    );
  }
}

class _NoTrip extends StatelessWidget {
  const _NoTrip({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(20)),
              child: const WIcon('car', size: 26, strokeWidth: 1.6),
            ),
            const SizedBox(height: 18),
            Text(s.t('No active trip', 'لا توجد رحلة نشطة'), style: W.serif(size: 30), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              s.t('Accept a request from the Drive tab to start a trip.', 'اقبل طلباً من شاشة القيادة لبدء رحلة.'),
              textAlign: TextAlign.center,
              style: W.sans(size: 13, color: W.text2),
            ),
            const SizedBox(height: 22),
            Btn(s.t('Back to drive', 'العودة للوحة'), icon: 'home', variant: BtnVariant.dark, onTap: () => context.root('driverHome')),
          ]),
        ),
      ),
    );
  }
}
