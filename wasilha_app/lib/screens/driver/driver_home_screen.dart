import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// 18 — Driver home: online toggle, incoming request sheet, today's stats.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const _requestSeconds = 18;
  static const dailyGoal = 30000;

  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  StreamSubscription<List<Trip>>? _tripsSub;
  List<Trip>? _driverTrips;
  StreamSubscription<List<Trip>>? _reqSub;
  StreamSubscription<Trip?>? _activeSub;
  Timer? _ticker;

  List<Trip> _requests = const [];
  final Set<String> _skipped = {};
  String? _shownId;
  int _timer = _requestSeconds;
  String? _bidSentFor;
  bool _bidding = false;
  bool? _pendingOnline;

  Trip? _active;
  final Set<String> _autoOpened = {};

  @override
  void initState() {
    super.initState();
    _reqSub = _backend.openRequests().listen((l) {
      if (!mounted) return;
      setState(() => _requests = l);
      _syncShown();
    });
    _activeSub = _backend.driverActiveTrip().listen((t) {
      if (!mounted) return;
      setState(() => _active = t);
      if (t != null && !_autoOpened.contains(t.id)) {
        _autoOpened.add(t.id);
        // Only the visible screen navigates (requests screen handles itself).
        if (ModalRoute.of(context)?.isCurrent ?? false) context.go('driverDelivery');
      }
    });
    _tripsSub = _backend.driverTrips().listen((l) {
      if (mounted) setState(() => _driverTrips = l);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _activeSub?.cancel();
    _tripsSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Trip? get _current {
    for (final t in _requests) {
      if (!_skipped.contains(t.id)) return t;
    }
    return null;
  }

  void _syncShown() {
    final c = _current;
    if (c?.id != _shownId) {
      setState(() {
        _shownId = c?.id;
        _timer = _requestSeconds;
        _bidding = false;
      });
    }
  }

  void _tick() {
    if (!mounted || _shownId == null || _bidSentFor == _shownId) return;
    if (_timer <= 1) {
      _skip();
    } else {
      setState(() => _timer--);
    }
  }

  void _skip() {
    final id = _shownId;
    if (id == null) return;
    setState(() => _skipped.add(id));
    _syncShown();
  }

  Future<void> _toggle(bool v) async {
    setState(() => _pendingOnline = v);
    try {
      await _backend.setOnline(v);
      if (v) {
        setState(() => _skipped.clear());
        _syncShown();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _pendingOnline = null);
    }
  }

  Future<void> _accept(Trip t) async {
    setState(() => _bidding = true);
    try {
      await _backend.placeBid(t.id, amount: t.offeredFare, etaMin: pickupEtaMin(t));
      if (mounted) setState(() => _bidSentFor = t.id);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _bidding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return StreamBuilder<UserProfile?>(
      stream: _profile,
      builder: (context, snap) {
        final me = snap.data;
        final online = _pendingOnline ?? me?.online ?? false;
        final req = online && _active == null ? _current : null;
        final top = MediaQuery.paddingOf(context).top;
        return Scaffold(
          backgroundColor: W.screenBg,
          body: Stack(children: [
            Positioned.fill(child: WMap(drivers: online ? 0 : 4)),

            // Top status bar
            PositionedDirectional(
              top: top + 12,
              start: 16,
              end: 16,
              child: Column(children: [
                Row(children: [
                  SquareBtn(
                    size: 44,
                    onTap: () => context.go('settings'),
                    child: Avatar(size: 28, label: me?.initials ?? 'W', tone: 'warm'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Glass(
                      radius: 14,
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                      child: Row(children: [
                        PulseDot(color: online ? W.success : W.text3, ring: online, animate: online),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            MonoLabel(s.t('Status · Driver', 'الحالة · كابتن'), size: 8.5),
                            const SizedBox(height: 1),
                            Text(
                              online
                                  ? s.t('Online · accepting trips', 'متصل · جاهز للطلبات')
                                  : s.t('Offline', 'غير متصل'),
                              overflow: TextOverflow.ellipsis,
                              style: W.sans(size: 13, weight: FontWeight.w600, color: online ? W.success : W.text),
                            ),
                          ]),
                        ),
                        DriverSwitch(value: online, onChanged: me == null || _pendingOnline != null ? null : _toggle),
                      ]),
                    ),
                  ),
                ]),
                if (_active != null) ...[
                  const SizedBox(height: 10),
                  _ActiveBanner(trip: _active!),
                ],
              ]),
            ),

            // Bottom sheet: incoming request or today's stats
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: const Cubic(0.2, 0.8, 0.2, 1),
                transitionBuilder: (child, a) => SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a),
                  child: child,
                ),
                child: req != null
                    ? _RequestSheet(
                        key: ValueKey(req.id),
                        trip: req,
                        timer: _timer,
                        moreCount: _requests.where((t) => !_skipped.contains(t.id)).length - 1,
                        sent: _bidSentFor == req.id,
                        bidding: _bidding,
                        onSkip: _skip,
                        onAccept: () => _accept(req),
                      )
                    : _StatsSheet(key: const ValueKey('stats'), online: online, me: me, trips: _driverTrips),
              ),
            ),

            if (req == null) const DriverNav(active: 'driverHome'),
          ]),
        );
      },
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return GestureDetector(
      onTap: () => context.go('driverDelivery'),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: W.text,
          borderRadius: BorderRadius.circular(14),
          boxShadow: W.softShadow,
        ),
        child: Row(children: [
          PulseDot(color: s.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('Active trip', 'رحلة نشطة'), size: 8.5, color: const Color(0x8CFFFFFF)),
              Text(
                '${trip.riderName.isEmpty ? s.t('Rider', 'الراكب') : trip.riderName} · ${trip.dropoff.label(s.ar)}',
                overflow: TextOverflow.ellipsis,
                style: W.sans(size: 13, weight: FontWeight.w500, color: Colors.white),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: s.accent, borderRadius: BorderRadius.circular(999)),
            child: Text(s.t('Open', 'فتح'), style: W.sans(size: 12, weight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

class _RequestSheet extends StatelessWidget {
  const _RequestSheet({
    super.key,
    required this.trip,
    required this.timer,
    required this.moreCount,
    required this.sent,
    required this.bidding,
    required this.onSkip,
    required this.onAccept,
  });

  final Trip trip;
  final int timer;
  final int moreCount;
  final bool sent;
  final bool bidding;
  final VoidCallback onSkip;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final km = trip.distanceKm;
    final eta = pickupEtaMin(trip);
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(18, 14, 18, 28 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: W.text,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x4D0A0908), blurRadius: 40, offset: Offset(0, -16))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        AccentGlow(color: accent, size: 240, top: -74, end: -58, alpha: 0.38),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(children: [
            Text('● ', style: W.sans(size: 10, color: accent)),
            MonoLabel(s.t('New request', 'طلب جديد'), color: accent, spacing: 0.32),
            const Spacer(),
            if (moreCount > 0)
              GestureDetector(
                onTap: () => context.go('driverRequests'),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: Text(s.t('See all · ${moreCount + 1}', 'عرض الكل · ${moreCount + 1}'),
                      style: W.sans(size: 12, weight: FontWeight.w500, color: const Color(0xB3FFFFFF))),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                WIcon('clock', size: 12, strokeWidth: 2, color: accent),
                const SizedBox(width: 6),
                Text(sent ? '—' : mmss(timer),
                    style: W.mono(size: 11, color: Colors.white, weight: FontWeight.w600, letterSpacing: 0.04)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sdg(trip.offeredFare), style: W.serif(size: 56, color: Colors.white, height: 0.92, letterSpacing: -2)),
                const SizedBox(height: 4),
                Text(
                  'SDG · ${km.toStringAsFixed(1)} KM · ${trip.etaMin} MIN · ${trip.service.label.toUpperCase()}',
                  style: W.mono(size: 10, color: const Color(0x8CFFFFFF), letterSpacing: 0.18),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Avatar(size: 44, label: initialsOf(trip.riderName), tone: 'purple'),
              const SizedBox(height: 6),
              Text(trip.riderName.isEmpty ? s.t('Rider', 'راكب') : trip.riderName,
                  style: W.sans(size: 12, color: Colors.white)),
              const SizedBox(height: 1),
              Row(mainAxisSize: MainAxisSize.min, children: [
                WIcon(trip.service.icon, size: 11, color: const Color(0xA6FFFFFF)),
                const SizedBox(width: 3),
                Text(trip.service.title(s.ar), style: W.sans(size: 11, color: const Color(0xA6FFFFFF))),
              ]),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 6), child: RouteDots(accent: accent, dark: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel(s.t('Pickup · $eta min', 'الاستلام · $eta د'), size: 8.5, color: const Color(0x80FFFFFF)),
                    const SizedBox(height: 2),
                    Text(trip.pickup.label(s.ar),
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 13.5, weight: FontWeight.w500, color: Colors.white)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel(s.t('Drop-off', 'الوجهة'), size: 8.5, color: const Color(0x80FFFFFF)),
                    const SizedBox(height: 2),
                    Text(trip.dropoff.label(s.ar),
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 13.5, weight: FontWeight.w500, color: Colors.white)),
                  ]),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            GestureDetector(
              onTap: onSkip,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x24FFFFFF), width: 0.5),
                ),
                child: const WIcon('close', size: 20, strokeWidth: 2, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: sent || bidding ? null : onAccept,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    color: sent ? const Color(0x1FFFFFFF) : accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: sent
                        ? null
                        : [BoxShadow(color: accent.withValues(alpha: 0.31), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (bidding || sent) ...[
                      const MiniSpinner(color: Colors.white, size: 16),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        sent
                            ? s.t('Offer sent · waiting for rider', 'تم إرسال العرض · بانتظار الراكب')
                            : s.t('Accept trip', 'قبول الرحلة'),
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 15, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    if (!sent && !bidding) ...[
                      const SizedBox(width: 8),
                      const WIcon('arrow', size: 18, strokeWidth: 1.8, color: Colors.white),
                    ],
                  ]),
                ),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _StatsSheet extends StatelessWidget {
  const _StatsSheet({super.key, required this.online, required this.me, required this.trips});
  final bool online;
  final UserProfile? me;
  /// `driverTrips()`; null while loading.
  final List<Trip>? trips;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final now = DateTime.now();
    final dateLabel = s.ar
        ? '${now.day}/${now.month}'
        : '${const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][now.weekday - 1]} ${now.day} '
            '${const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][now.month - 1]}';
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
      decoration: const BoxDecoration(
        color: W.screenBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x1A140F1E), blurRadius: 32, offset: Offset(0, -10))],
      ),
      child: Builder(
        builder: (context) {
          final today = tripsToday(trips ?? const []);
          final earned = sumEarnings(today);
          final hours = today.fold<int>(0, (a, t) => a + t.etaMin) / 60;
          final pct = (earned / _DriverHomeScreenState.dailyGoal).clamp(0.0, 1.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              if (!online)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: W.border, width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(11)),
                      child: const WIcon('moon', size: 16, strokeWidth: 1.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.t("You're offline", 'أنت غير متصل'), style: W.sans(size: 13, weight: FontWeight.w500)),
                        Text(s.t('Toggle online to receive requests', 'فعّل الاتصال لبدء استلام الطلبات'),
                            style: W.sans(size: 11.5, color: W.text2)),
                      ]),
                    ),
                  ]),
                ),
              if (online && trips != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: W.border, width: 0.5),
                  ),
                  child: Row(children: [
                    const MiniSpinner(size: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.t('Listening for nearby riders…', 'بانتظار طلبات قريبة…'),
                          style: W.sans(size: 12.5, color: W.text2)),
                    ),
                  ]),
                ),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel(s.t('Today · $dateLabel', 'اليوم · $dateLabel'), size: 9.5, spacing: 0.3),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(sdg(earned), style: W.serif(size: 44, letterSpacing: -1.1)),
                      const SizedBox(width: 6),
                      Text('SDG', style: W.mono(size: 11, color: W.text2)),
                    ]),
                  ]),
                ),
                GestureDetector(
                  onTap: () => driverTab(context, 'driverEarnings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(999)),
                    child: Text(s.t('Earnings', 'الأرباح'),
                        style: W.sans(size: 12, weight: FontWeight.w500, color: accent)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _Mini(label: s.t('Trips', 'رحلات'), value: '${today.length}'),
                const SizedBox(width: 8),
                _Mini(label: s.t('Hours', 'ساعات'), value: hours.toStringAsFixed(1)),
                const SizedBox(width: 8),
                _Mini(label: s.t('Rating', 'تقييم'), value: (me?.rating ?? 5).toStringAsFixed(2), star: true),
              ]),
              const SizedBox(height: 14),
              Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(16)),
                child: Stack(clipBehavior: Clip.none, children: [
                  AccentGlow(color: accent),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      MonoLabel(s.t('Daily goal', 'هدف اليوم'), size: 9.5, spacing: 0.28, color: const Color(0x8CFFFFFF)),
                      const Spacer(),
                      Text('${(pct * 100).round()}%',
                          style: W.mono(size: 11, color: Colors.white, weight: FontWeight.w600, letterSpacing: 0.04)),
                    ]),
                    const SizedBox(height: 6),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: sdg(earned), style: W.sans(size: 13, weight: FontWeight.w600, color: Colors.white)),
                      TextSpan(
                          text: ' / ${sdg(_DriverHomeScreenState.dailyGoal)} SDG',
                          style: W.sans(size: 13, color: const Color(0x8CFFFFFF))),
                    ])),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        color: const Color(0x1AFFFFFF),
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [BoxShadow(color: accent, blurRadius: 14)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => driverTab(context, 'driverRequests'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: W.border, width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: WIcon('flame', size: 18, strokeWidth: 1.7, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.t('High demand · Khartoum 2', 'منطقة طلبات نشطة'),
                            style: W.sans(size: 13.5, weight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(s.t('+40% surge for this hour · see requests', 'متوسط +٤٠٪ هذا الوقت · عرض الطلبات'),
                            style: W.sans(size: 11.5, color: W.text2)),
                      ]),
                    ),
                    const WIcon('chevron', size: 14, color: W.text3),
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, this.star = false});
  final String label;
  final String value;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MonoLabel(label, size: 9),
          const SizedBox(height: 4),
          Row(children: [
            Flexible(child: Text(value, style: W.serif(size: 24, height: 1))),
            if (star) ...[
              const SizedBox(width: 4),
              const WIcon('star', size: 12, color: W.gold),
            ],
          ]),
        ]),
      ),
    );
  }
}
