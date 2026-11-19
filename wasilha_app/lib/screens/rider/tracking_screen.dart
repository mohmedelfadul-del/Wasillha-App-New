import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'ride_common.dart';

/// 07 — Live tracking of the accepted trip.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late final AppState _s = context.read<AppState>();
  late final WasilhaBackend _b = context.read<WasilhaBackend>();
  StreamSubscription<Trip?>? _sub;
  Trip? _trip;
  bool _left = false;
  bool _cancelling = false;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  /// Demo dispatch line; a production build would use the driver's number
  /// from their profile.
  static const _driverPhone = '+249912000000';

  @override
  void initState() {
    super.initState();
    final id = _s.activeTripId;
    if (id == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
      return;
    }
    _sub = _b.watchTrip(id).listen(_onTrip, onError: (Object e) {
      if (mounted) showError(context, e);
    });
  }

  void _onTrip(Trip? t) {
    if (!mounted || _left) return;
    if (t == null || t.status == TripStatus.cancelled) {
      _s.setActiveTrip(null);
      if (t != null && !_cancelling) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: W.text,
          content: Text(_s.t('Your trip was cancelled.', 'تم إلغاء رحلتك.')),
        ));
      }
      return _leave();
    }
    if (t.status == TripStatus.completed) {
      _left = true;
      context.swap('complete');
      return;
    }
    if (t.status == TripStatus.requested) {
      _left = true;
      context.swap('offer');
      return;
    }
    setState(() => _trip = t);
  }

  void _leave() {
    if (!mounted || _left) return;
    _left = true;
    context.root('home');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final ok = await launchUrl(Uri.parse('tel:$_driverPhone'));
    if (!ok && mounted) showError(context, _s.t('Could not start a call on this device.', 'تعذر إجراء المكالمة على هذا الجهاز.'));
  }

  Future<void> _cancel(Trip t) async {
    final s = _s;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: W.screenBg,
        title: Text(s.t('Cancel this ride?', 'إلغاء هذه الرحلة؟'), style: W.sans(size: 17, weight: FontWeight.w600)),
        content: Text(
          s.t('${t.driverName ?? 'Your driver'} is already on the way.', '${t.driverName ?? 'السائق'} في الطريق إليك.'),
          style: W.sans(size: 14, color: W.text2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.t('Keep ride', 'متابعة الرحلة'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.t('Cancel ride', 'إلغاء الرحلة'), style: const TextStyle(color: W.danger)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await _b.cancelTrip(t.id);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _cancelling = false);
      }
    }
  }

  /// Minutes left to the current target (pickup before the ride, drop-off during it).
  int _minutesLeft(Trip t) {
    final target = t.status == TripStatus.inProgress ? t.dropoff : t.pickup;
    final lat = t.driverLat, lng = t.driverLng;
    if (lat == null || lng == null) return t.status == TripStatus.inProgress ? t.etaMin : 3;
    final km = haversineKm(lat, lng, target.lat, target.lng);
    return (km / 0.45).ceil().clamp(1, 120);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = _trip;
    if (t == null) {
      return const Scaffold(
        backgroundColor: W.screenBg,
        body: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final h = MediaQuery.sizeOf(context).height;
    final driverPos = t.driverLat != null && t.driverLng != null ? (t.driverLat!, t.driverLng!) : null;
    final mins = _minutesLeft(t);
    final riding = t.status == TripStatus.inProgress;
    final headline = switch (t.status) {
      TripStatus.accepted => s.t('Driver is on the way', 'السائق في الطريق'),
      TripStatus.arriving => mins <= 1 ? s.t('Driver has arrived', 'وصل السائق') : s.t('Driver is arriving', 'السائق يقترب'),
      _ => s.t('En route to ${t.dropoff.label(false)}', 'في الطريق إلى ${t.dropoff.label(true)}'),
    };

    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        Positioned.fill(
          child: WMap(
            pickup: t.pickup,
            dropoff: t.dropoff,
            showRoute: true,
            pulse: true,
            drivers: 2,
            driverPos: driverPos,
            padding: EdgeInsets.only(top: 120, bottom: h * 0.55),
          ),
        ),
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                SquareIconBtn(icon: 'back', onTap: () => _leave()),
                const SizedBox(width: 10),
                Expanded(
                  child: Glass(
                    radius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: s.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: s.accent.withValues(alpha: 0.19 + 0.2 * _pulse.value),
                                spreadRadius: 2 + 2 * _pulse.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          MonoLabel(s.t('TRIP', 'الرحلة'), size: 9),
                          Text(headline,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Text(s.t('$mins MIN', '$mins د'),
                          style: W.mono(size: 12, color: W.text, weight: FontWeight.w600, letterSpacing: 0.04)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
        // Sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SheetIn(
            child: RideSheet(
              maxHeightFactor: 0.62,
              bottomPad: 36,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SheetHandle(),
                _DriverCard(trip: t),
                const SizedBox(height: 16),
                _actions(s, t),
                const SizedBox(height: 18),
                _Timeline(trip: t, minutes: mins),
                const SizedBox(height: 12),
                _fareRow(s, t),
                if (!riding) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cancelling ? null : () => _cancel(t),
                    child: _cancelling
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.t('Cancel ride', 'إلغاء الرحلة'), style: W.sans(size: 13.5, color: W.danger)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _actions(AppState s, Trip trip) {
    Widget btn({required String icon, String? label, required bool dark, required VoidCallback onTap}) {
      final fg = dark ? Colors.white : W.text;
      final box = Container(
        height: 50,
        width: label == null ? 50 : null,
        decoration: BoxDecoration(
          color: dark ? W.text : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: dark ? null : Border.all(color: W.border, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          WIcon(icon, size: label == null ? 18 : 16, strokeWidth: 1.7, color: fg),
          if (label != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500, color: fg)),
            ),
          ],
        ]),
      );
      return GestureDetector(onTap: onTap, child: box);
    }

    return Row(children: [
      Expanded(child: btn(icon: 'phone', label: s.t('Call', 'اتصال'), dark: true, onTap: _call)),
      const SizedBox(width: 8),
      Expanded(
        child: btn(
          icon: 'chat',
          label: s.t('Message', 'رسالة'),
          dark: false,
          onTap: () => context.go('chat', args: trip.id),
        ),
      ),
      const SizedBox(width: 8),
      btn(icon: 'shield', dark: false, onTap: () => context.go('sos')),
    ]);
  }

  Widget _fareRow(AppState s, Trip t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          WIcon(t.payment == 'cash' ? 'receipt' : 'wallet', size: 16, strokeWidth: 1.7, color: W.text2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.payment == 'cash' ? s.t('Cash · agreed fare', 'نقدًا · الأجرة المتفق عليها') : s.t('Wallet · agreed fare', 'المحفظة · الأجرة المتفق عليها'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: W.sans(size: 13, color: W.text2),
            ),
          ),
          Text(sdg(t.fare), style: W.serif(size: 20)),
          const SizedBox(width: 6),
          Text(s.t('SDG', 'ج.س'), style: W.mono(size: 10, letterSpacing: 0.18)),
        ]),
      );
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final vehicle = (trip.driverVehicle ?? '').split('·').map((e) => e.trim()).toList();
    final model = vehicle.isNotEmpty && vehicle.first.isNotEmpty ? vehicle.first : trip.service.title(s.ar);
    final color = vehicle.length > 1 ? vehicle[1] : null;
    return Row(children: [
      Avatar(size: 56, label: initialsOf(trip.driverName), tone: toneFor(trip.driverId ?? '')),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MonoLabel(s.t('YOUR DRIVER', 'سائقك'), size: 9),
          const SizedBox(height: 2),
          Text(trip.driverName ?? s.t('Driver', 'السائق'),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: W.serif(size: 22)),
          const SizedBox(height: 4),
          Row(children: [
            const WIcon('star', size: 12, color: W.gold),
            const SizedBox(width: 3),
            Text((trip.driverRating ?? 5).toStringAsFixed(2), style: W.sans(size: 11.5, color: W.text2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: W.sans(size: 11.5, color: W.text2)),
            ),
            Flexible(
              child: Text(trip.service.title(s.ar),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: W.mono(size: 11, color: W.text2, letterSpacing: 0)),
            ),
          ]),
        ]),
      ),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(model, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500)),
        ),
        const SizedBox(height: 2),
        Text(trip.driverPlate ?? '—', style: W.mono(size: 13, color: W.text, weight: FontWeight.w600, letterSpacing: 0.16)),
        if (color != null) ...[
          const SizedBox(height: 4),
          Text(color, style: W.sans(size: 11, color: W.text2)),
        ],
      ]),
    ]);
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.trip, required this.minutes});
  final Trip trip;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final riding = trip.status == TripStatus.inProgress;
    final steps = [
      (
        'check',
        s.t('Request accepted', 'تم قبول الطلب'),
        DateFormat.Hm().format(trip.createdAt),
        _Step.done,
      ),
      riding
          ? ('check', s.t('Picked up', 'تم الركوب'), trip.pickup.label(s.ar), _Step.done)
          : (
              trip.service.icon,
              s.t('Driver heading your way', 'السائق في طريقه إليك'),
              s.t('$minutes MIN AWAY', 'على بعد $minutes د'),
              _Step.active,
            ),
      (
        riding ? trip.service.icon : 'pin',
        riding ? s.t("You're on the way", 'أنت في الطريق') : s.t('Arrive at destination', 'الوصول إلى الوجهة'),
        riding ? s.t('$minutes MIN REMAINING · ${trip.dropoff.label(false)}', 'متبقي $minutes د · ${trip.dropoff.label(true)}') : trip.dropoff.label(s.ar),
        riding ? _Step.active : _Step.pending,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: Column(children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 28,
                child: Column(children: [
                  _StepIcon(icon: steps[i].$1, step: steps[i].$4),
                  if (i < steps.length - 1) Expanded(child: Container(width: 1.5, color: W.border2)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 14 : 0, top: 2),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      steps[i].$2,
                      style: W.sans(
                        size: 13.5,
                        weight: steps[i].$4 == _Step.active ? FontWeight.w600 : FontWeight.w500,
                        color: steps[i].$4 == _Step.pending ? W.text2 : W.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(steps[i].$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: s.ar ? W.ar(size: 11, color: W.text3) : W.mono(size: 10, letterSpacing: 0.14)),
                  ]),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

enum _Step { done, active, pending }

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, required this.step});
  final String icon;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppState>().accent;
    final bg = switch (step) {
      _Step.active => a,
      _Step.done => W.text,
      _Step.pending => W.surface2,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: step == _Step.active ? [BoxShadow(color: a.withValues(alpha: 0.12), spreadRadius: 4)] : null,
      ),
      child: WIcon(icon, size: 13, strokeWidth: 2, color: step == _Step.pending ? W.text2 : Colors.white),
    );
  }
}
