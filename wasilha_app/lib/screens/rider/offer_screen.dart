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
import 'offer_widgets.dart';
import 'ride_common.dart';

/// 08b — Offer: the rider sets a fare, posts the request, and nearby
/// drivers counter-offer in real time.
class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> with TickerProviderStateMixin {
  late final WasilhaBackend _b = context.read<WasilhaBackend>();
  late final AppState _s = context.read<AppState>();

  late int _offer;
  late ServiceType _svc;
  late int _suggested;

  String? _tripId;
  int _requestedFare = 0;
  List<Bid> _bids = const [];
  final Set<String> _declined = {};
  StreamSubscription<List<Bid>>? _bidSub;
  Timer? _searchWindow;
  bool _searchOver = false;
  bool _busy = false;
  bool _resuming = false;
  String? _accepting;

  late final AnimationController _ping =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _svc = _s.service;
    _suggested = _s.suggestedFare();
    _offer = _suggested;
    final existing = _s.activeTripId;
    if (existing != null) _resume(existing);
  }

  Future<void> _resume(String id) async {
    _resuming = true;
    try {
      final t = await _b.watchTrip(id).first;
      if (!mounted) return;
      if (t == null || !t.isActive) {
        _s.setActiveTrip(null);
      } else if (t.status == TripStatus.requested) {
        _svc = t.service;
        _suggested = t.service.fareFor(t.distanceKm);
        _offer = t.offeredFare;
        _watch(id, t.offeredFare);
      } else {
        context.swap('tracking');
        return;
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (mounted) setState(() => _resuming = false);
  }

  void _watch(String id, int fare) {
    _bidSub?.cancel();
    _searchWindow?.cancel();
    setState(() {
      _tripId = id;
      _requestedFare = fare;
      _bids = const [];
      _declined.clear();
      _searchOver = false;
    });
    _bidSub = _b.watchBids(id).listen(
      (bids) {
        if (mounted) setState(() => _bids = bids);
      },
      onError: (Object e) {
        if (mounted) showError(context, e);
      },
    );
    _searchWindow = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _searchOver = true);
    });
  }

  @override
  void dispose() {
    _bidSub?.cancel();
    _searchWindow?.cancel();
    _ping.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Fare maths ──────────────────────────────────────────────
  int get _min => _svc.base;
  int get _max => (_suggested * 3).clamp(_svc.base + 500, 1 << 30);
  int get _fairLo => round50(_suggested * 0.9).clamp(_svc.base, 1 << 30);
  int get _fairHi => round50(_suggested * 1.1).clamp(_fairLo + 50, 1 << 30);
  int get _trackLo => (_fairLo - (_fairHi - _fairLo)).clamp(_min, 1 << 30);
  int get _trackHi => _fairHi + (_fairHi - _fairLo);

  void _adjust(int d) => setState(() => _offer = (_offer + d).clamp(_min, _max));

  // ── Actions ─────────────────────────────────────────────────
  Future<void> _request() async {
    final dropoff = _s.dropoff;
    if (dropoff == null) {
      context.swap('search');
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await _b.requestTrip(
        service: _svc,
        pickup: _s.pickup,
        dropoff: dropoff,
        offeredFare: _offer,
        payment: _s.payment,
      );
      if (!mounted) return;
      _s.setActiveTrip(id);
      _watch(id, _offer);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// No backend call can change a posted fare, so raising re-posts the
  /// request at the higher amount.
  Future<void> _raise() async {
    final id = _tripId;
    if (id == null) return _adjust(100);
    setState(() => _busy = true);
    try {
      await _b.cancelTrip(id);
      _bidSub?.cancel();
      _offer = (_offer + 100).clamp(_min, _max);
      _s.setActiveTrip(null);
      setState(() => _tripId = null);
    } catch (e) {
      if (mounted) showError(context, e);
      if (mounted) setState(() => _busy = false);
      return;
    }
    await _request();
  }

  Future<void> _cancel() async {
    final id = _tripId;
    if (id != null) {
      setState(() => _busy = true);
      try {
        await _b.cancelTrip(id);
      } catch (e) {
        if (mounted) showError(context, e);
        if (mounted) setState(() => _busy = false);
        return;
      }
      _bidSub?.cancel();
      _s.setActiveTrip(null);
      _tripId = null;
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.root('home');
    }
  }

  Future<void> _accept(Bid bid) async {
    final id = _tripId;
    if (id == null || _accepting != null) return;
    setState(() => _accepting = bid.driverId);
    try {
      await _b.acceptBid(id, bid);
      _bidSub?.cancel();
      if (mounted) context.swap('tracking');
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _accepting = null);
      }
    }
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dropoff = s.dropoff;
    final km = dropoff == null ? 0.0 : s.pickup.kmTo(dropoff);
    final requested = _tripId != null;
    final visible = _bids.where((b) => !_declined.contains(b.driverId)).toList();
    final searching = requested && visible.length < 3 && !_searchOver;

    return PopScope(
      canPop: !requested,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _cancel();
      },
      child: Scaffold(
        backgroundColor: W.screenBg,
        body: Stack(children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: WMap(pickup: s.pickup, dropoff: dropoff, showRoute: true, drivers: 6),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.38, 0.6],
                    colors: [Color(0x66FBFAF6), Color(0xEBFBFAF6), W.screenBg],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
              children: [
                _topNav(s, km),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: FareCard(
                    offer: _offer,
                    fairLo: _fairLo,
                    fairHi: _fairHi,
                    trackLo: _trackLo,
                    trackHi: _trackHi,
                    locked: requested || _busy,
                    onAdjust: _adjust,
                    onFair: () => setState(() => _offer = _suggested.clamp(_min, _max)),
                  ),
                ),
                if (_resuming)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (!requested)
                  _beforeRequest(s)
                else ...[
                  _statusLine(s, searching, visible.length),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(children: [
                      for (final b in visible) ...[
                        BidIn(
                          key: ValueKey('bid-${b.driverId}'),
                          child: BidCard(
                            bid: b,
                            requestedFare: _requestedFare,
                            accepting: _accepting == b.driverId,
                            disabled: _accepting != null,
                            onAccept: () => _accept(b),
                            onDecline: () => setState(() => _declined.add(b.driverId)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (searching)
                        for (var i = 0; i < 3 - visible.length; i++) ...[
                          BidSkeleton(pulse: _pulse, opacity: 0.65 - i * 0.18),
                          const SizedBox(height: 8),
                        ],
                      if (!searching && visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            s.t('No offers yet. Raising your fare usually helps.',
                                'لا توجد عروض بعد. رفع الأجرة يساعد عادةً.'),
                            textAlign: TextAlign.center,
                            style: W.sans(size: 12.5, color: W.text2),
                          ),
                        ),
                    ]),
                  ),
                  _bottomActions(s),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topNav(AppState s, double km) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
        child: Row(children: [
          SquareIconBtn(
            icon: 'back',
            size: 38,
            bordered: true,
            onTap: () => _tripId == null ? context.back() : _cancel(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t('Set your fare', 'حدّد أجرتك'),
                  style: s.ar ? W.arSerif(size: 20) : W.serif(size: 20, height: 1.05)),
              const SizedBox(height: 2),
              Text(s.t('Your offer is sent to drivers nearby', 'سيُرسل عرضك إلى السائقين القريبين'),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: W.text2)),
            ]),
          ),
          Container(
            padding: const EdgeInsetsDirectional.only(start: 10),
            decoration: const BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: W.border2, width: 0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(s.t('${rideMinutes(km)} MIN', '${rideMinutes(km)} د'), style: W.mono(size: 9.5, letterSpacing: 0.22)),
              Text(s.t('${kmText(km)} KM', '${kmText(km)} كم'), style: W.mono(size: 9.5, letterSpacing: 0.22)),
            ]),
          ),
        ]),
      );

  Widget _beforeRequest(AppState s) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            WIcon(_svc.icon, size: 16, strokeWidth: 1.7, color: W.text2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.t('${_svc.label} · pay by ${s.payment == 'cash' ? 'cash' : 'wallet'}',
                    '${_svc.labelAr} · الدفع ${s.payment == 'cash' ? 'نقدًا' : 'بالمحفظة'}'),
                style: W.sans(size: 12.5, color: W.text2),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            s.t('Drivers nearby will accept or counter your fare. You choose who to ride with.',
                'سيقبل السائقون القريبون أجرتك أو يقدمون عرضًا مضادًا. أنت تختار.'),
            style: W.sans(size: 12.5, color: W.text3),
          ),
          const SizedBox(height: 16),
          Btn(
            s.t('Find drivers · ${sdg(_offer)} SDG', 'ابحث عن سائق · ${sdg(_offer)} ج.س'),
            full: true,
            icon: 'search',
            loading: _busy,
            onTap: _request,
          ),
        ]),
      );

  Widget _statusLine(AppState s, bool searching, int count) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
        child: Row(children: [
          PingDot(ping: _ping, searching: searching),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: searching
                      ? s.t('Searching', 'جاري البحث')
                      : s.t('$count counter${count == 1 ? '' : 's'}', '$count عروض'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: searching
                      ? s.t('  · DRIVERS NEARBY', '  · سائقون قريبون')
                      : (count > 0 ? s.t('  · TAP TO ACCEPT', '  · اضغط للقبول') : ''),
                  style: s.ar ? W.ar(size: 11, color: W.text3) : W.mono(size: 10.5, color: W.text3, letterSpacing: 0.16),
                ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: W.sans(size: 12.5),
            ),
          ),
          const Spacer(),
          MonoLabel(s.t('COUNTER OFFERS', 'العروض الواردة'), size: 9.5),
        ]),
      );

  Widget _bottomActions(AppState s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [
          Expanded(
            child: _ActionBtn(
              dark: false,
              onTap: _busy ? null : _cancel,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const WIcon('close', size: 14, strokeWidth: 1.8, color: W.text),
                const SizedBox(width: 8),
                Flexible(child: Text(s.t('Cancel request', 'إلغاء الطلب'), overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5))),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              dark: true,
              onTap: _busy || _accepting != null ? null : _raise,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                        child: Text(s.t('Raise offer', 'رفع العرض'),
                            overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text('+100', style: W.mono(size: 11, color: const Color(0xB3FFFFFF), letterSpacing: 0.1)),
                    ]),
            ),
          ),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.dark, required this.onTap, required this.child});
  final bool dark;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: dark ? W.text : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: dark ? null : Border.all(color: W.border, width: 0.5),
            ),
            child: child,
          ),
        ),
      );
}
