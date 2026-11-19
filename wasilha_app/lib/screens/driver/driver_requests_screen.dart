import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'driver_nav.dart';
import 'driver_widgets.dart';

const _cream = Color(0xFFFBFAF6);
const _dim = Color(0x73FFFFFF);
const _mint = Color(0xFF9DEACB);

/// Driver requests feed (screens-services.jsx → DriverRequestsScreen):
/// open rider requests with accept / counter-offer bidding.
class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<List<Trip>> _open = _backend.openRequests();
  late final Stream<UserProfile?> _profile = _backend.profile();
  late final Stream<List<Trip>> _trips = _backend.driverTrips();
  StreamSubscription<Trip?>? _activeSub;
  bool _left = false;

  final Set<String> _skipped = {};

  /// Counter-offer amount being edited, per trip.
  final Map<String, int> _counter = {};

  /// Amount of the bid sent, per trip.
  final Map<String, int> _sent = {};
  final Set<String> _sending = {};
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _activeSub = _backend.driverActiveTrip().listen((t) {
      if (t != null && mounted && !_left) {
        _left = true;
        context.swap('driverDelivery');
      }
    });
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    super.dispose();
  }

  Future<void> _bid(Trip t, int amount) async {
    setState(() => _sending.add(t.id));
    try {
      await _backend.placeBid(t.id, amount: amount, etaMin: pickupEtaMin(t));
      if (mounted) {
        setState(() {
          _sent[t.id] = amount;
          _counter.remove(t.id);
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending.remove(t.id));
    }
  }

  Future<void> _goOnline() async {
    setState(() => _toggling = true);
    try {
      await _backend.setOnline(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: W.text,
      body: Stack(children: [
        StreamBuilder<List<Trip>>(
          stream: _open,
          builder: (context, reqSnap) {
            final list = (reqSnap.data ?? const <Trip>[]).where((t) => !_skipped.contains(t.id)).toList();
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _Header(top: top, toggling: _toggling, onGoOnline: _goOnline, profile: _profile, trips: _trips)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: accent, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 10),
                    MonoLabel(s.t('Nearby requests', 'طلبات قريبة'), size: 11, color: _cream),
                    const Spacer(),
                    MonoLabel(
                      s.t('${list.length} open', '${list.length} طلب'),
                      size: 9.5,
                      spacing: 0.18,
                      color: _dim,
                    ),
                  ]),
                ),
              ),
              if (!reqSnap.hasData)
                const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(40), child: Center(child: MiniSpinner(color: _dim))),
                )
              else if (list.isEmpty)
                SliverToBoxAdapter(child: _Listening(s: s))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = list[i];
                      return _RequestCard(
                        key: ValueKey(t.id),
                        trip: t,
                        highlight: i == 0,
                        counter: _counter[t.id],
                        sent: _sent[t.id],
                        sending: _sending.contains(t.id),
                        onSkip: () => setState(() => _skipped.add(t.id)),
                        onAccept: () => _bid(t, t.offeredFare),
                        onCounterOpen: () => setState(() => _counter[t.id] = t.offeredFare),
                        onCounterChange: (v) => setState(() => _counter[t.id] = v),
                        onCounterCancel: () => setState(() => _counter.remove(t.id)),
                        onSend: (v) => _bid(t, v),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ]);
          },
        ),
        const DriverNav(active: 'driverRequests'),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.top,
    required this.toggling,
    required this.onGoOnline,
    required this.profile,
    required this.trips,
  });
  final Stream<UserProfile?> profile;
  final Stream<List<Trip>> trips;
  final double top;
  final bool toggling;
  final VoidCallback onGoOnline;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      padding: EdgeInsets.fromLTRB(18, top + 14, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF14110F), W.text], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF), width: 0.5)),
      ),
      child: StreamBuilder<UserProfile?>(
        stream: profile,
        builder: (context, pSnap) {
          final me = pSnap.data;
          final online = me?.online ?? false;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              SquareBtn(
                size: 38,
                color: const Color(0x0AFFFFFF),
                shadow: false,
                border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
                onTap: () => driverBack(context),
                child: const WIcon('back', size: 17, strokeWidth: 1.7, color: _cream),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: online || toggling ? null : onGoOnline,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: online ? const Color(0x291F8A5B) : const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: online ? const Color(0x661F8A5B) : const Color(0x26FFFFFF), width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (toggling)
                      const MiniSpinner(size: 8, color: _mint)
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: online ? W.success : W.text3,
                          shape: BoxShape.circle,
                          boxShadow: online ? const [BoxShadow(color: W.success, blurRadius: 8)] : null,
                        ),
                      ),
                    const SizedBox(width: 8),
                    MonoLabel(
                      online ? s.t('Online', 'متصل') : s.t('Offline · tap to go online', 'غير متصل · اضغط للاتصال'),
                      size: 10.5,
                      color: online ? _mint : const Color(0xB3FFFFFF),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('settings'),
                child: Avatar(size: 36, label: me?.initials ?? 'W', tone: 'cool'),
              ),
            ]),
            const SizedBox(height: 16),
            StreamBuilder<List<Trip>>(
              stream: trips,
              builder: (context, tSnap) {
                final today = tripsToday(tSnap.data ?? const []);
                return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MonoLabel(s.t("Today's earnings", 'الأرباح اليوم'), size: 9.5, spacing: 0.28, color: _dim),
                      const SizedBox(height: 6),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text(sdg(sumEarnings(today)), style: W.serif(size: 42, color: _cream, letterSpacing: -1.3)),
                        const SizedBox(width: 6),
                        Text(s.t('SDG', 'ج.س'), style: W.mono(size: 11, color: _dim, letterSpacing: 0.24)),
                      ]),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    MonoLabel(s.t('Trips', 'رحلات'), size: 9.5, color: _dim),
                    const SizedBox(height: 4),
                    Text('${today.length}', style: W.serif(size: 22, color: _cream)),
                  ]),
                ]);
              },
            ),
          ]);
        },
      ),
    );
  }
}

class _Listening extends StatelessWidget {
  const _Listening({required this.s});
  final AppState s;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
      ),
      child: Column(children: [
        MonoLabel(s.t('· Listening ·', '· بانتظار الطلبات ·'), size: 10.5, color: const Color(0x66FFFFFF)),
        const SizedBox(height: 8),
        Text(
          s.t('Waiting for nearby riders to send offers.', 'بانتظار عروض من ركاب قريبين.'),
          textAlign: TextAlign.center,
          style: W.sans(size: 12, color: const Color(0x8CFFFFFF)),
        ),
      ]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    super.key,
    required this.trip,
    required this.highlight,
    required this.counter,
    required this.sent,
    required this.sending,
    required this.onSkip,
    required this.onAccept,
    required this.onCounterOpen,
    required this.onCounterChange,
    required this.onCounterCancel,
    required this.onSend,
  });

  final Trip trip;
  final bool highlight;
  final int? counter;
  final int? sent;
  final bool sending;
  final VoidCallback onSkip;
  final VoidCallback onAccept;
  final VoidCallback onCounterOpen;
  final ValueChanged<int> onCounterChange;
  final VoidCallback onCounterCancel;
  final ValueChanged<int> onSend;

  static const _step = 100;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final minFare = trip.service.base;
    final maxFare = trip.offeredFare * 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: const Cubic(0.2, 0.85, 0.2, 1),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          if (highlight) AccentGlow(color: accent, size: 140, top: -54, end: -54, alpha: 0.25),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Avatar(size: 36, label: initialsOf(trip.riderName), tone: highlight ? 'purple' : 'olive'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(trip.riderName.isEmpty ? s.t('Rider', 'راكب') : trip.riderName,
                          overflow: TextOverflow.ellipsis,
                          style: W.sans(size: 13.5, weight: FontWeight.w500, color: _cream)),
                    ),
                    const SizedBox(width: 6),
                    WIcon(trip.service.icon, size: 12, color: const Color(0x8CFFFFFF)),
                    const SizedBox(width: 3),
                    Text(trip.service.title(s.ar), style: W.sans(size: 11, color: const Color(0x8CFFFFFF))),
                  ]),
                  const SizedBox(height: 2),
                  MonoLabel(
                    s.t('${pickupEtaMin(trip)} min away · ${trip.distanceKm.toStringAsFixed(1)} km · ${timeAgo(trip.createdAt)}',
                        'على بعد ${pickupEtaMin(trip)} د · ${trip.distanceKm.toStringAsFixed(1)} كم · ${timeAgo(trip.createdAt, ar: true)}'),
                    size: 9.5,
                    spacing: 0.14,
                    color: _dim,
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(sdg(trip.offeredFare), style: W.serif(size: 26, color: _cream)),
                const SizedBox(height: 3),
                MonoLabel(s.t('SDG', 'ج.س'), size: 9, color: _dim),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                RouteDots(accent: accent, dark: true, dot: 6, gap: 14, from: _mint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trip.pickup.label(s.ar),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: _cream, height: 1.5)),
                    Text(trip.dropoff.label(s.ar),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 11.5, color: const Color(0xB3FBFAF6), height: 1.5)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            if (sent != null)
              _SentRow(amount: sent!, accent: accent)
            else if (counter != null)
              _CounterRow(
                value: counter!,
                canDec: counter! - _step >= minFare,
                canInc: counter! + _step <= maxFare,
                sending: sending,
                onDec: () => onCounterChange(counter! - _step),
                onInc: () => onCounterChange(counter! + _step),
                onCancel: onCounterCancel,
                onSend: () => onSend(counter!),
              )
            else
              Row(children: [
                _DarkBtn(width: 44, onTap: onSkip, child: const WIcon('close', size: 15, strokeWidth: 1.8, color: _cream)),
                const SizedBox(width: 6),
                Expanded(
                  flex: 10,
                  child: _DarkBtn(
                    onTap: onCounterOpen,
                    child: Text(s.t('Counter', 'عرض مضاد'), style: W.sans(size: 12.5, color: _cream)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 14,
                  child: _AccentBtn(
                    loading: sending,
                    onTap: onAccept,
                    label: s.t('Accept · ${sdg(trip.offeredFare)}', 'قبول · ${sdg(trip.offeredFare)}'),
                  ),
                ),
              ]),
          ]),
        ]),
      ),
    );
  }
}

class _SentRow extends StatelessWidget {
  const _SentRow({required this.amount, required this.accent});
  final int amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(children: [
        MiniSpinner(color: accent, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            s.t('Bid sent · ${sdg(amount)} SDG · waiting for rider', 'تم إرسال العرض · ${sdg(amount)} ج.س · بانتظار الراكب'),
            overflow: TextOverflow.ellipsis,
            style: W.sans(size: 12, color: _cream),
          ),
        ),
      ]),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.value,
    required this.canDec,
    required this.canInc,
    required this.sending,
    required this.onDec,
    required this.onInc,
    required this.onCancel,
    required this.onSend,
  });

  final int value;
  final bool canDec;
  final bool canInc;
  final bool sending;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Row(children: [
      _DarkBtn(width: 38, onTap: onCancel, child: const WIcon('close', size: 14, strokeWidth: 1.8, color: _cream)),
      const SizedBox(width: 6),
      Expanded(
        flex: 12,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
          ),
          child: Row(children: [
            _StepBtn(icon: 'minus', onTap: canDec ? onDec : null),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(sdg(value), style: W.serif(size: 22, color: _cream)),
              ),
            ),
            _StepBtn(icon: 'plus', onTap: canInc ? onInc : null),
          ]),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        flex: 10,
        child: _AccentBtn(loading: sending, onTap: onSend, label: s.t('Send bid', 'إرسال العرض')),
      ),
    ]);
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 42,
        child: Center(
          child: WIcon(icon, size: 14, strokeWidth: 1.9, color: onTap == null ? const Color(0x40FFFFFF) : _cream),
        ),
      ),
    );
  }
}

class _DarkBtn extends StatelessWidget {
  const _DarkBtn({required this.child, this.onTap, this.width});
  final Widget child;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

class _AccentBtn extends StatelessWidget {
  const _AccentBtn({required this.label, required this.onTap, this.loading = false});
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.33), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const MiniSpinner(color: Colors.white, size: 14)
          else ...[
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500, color: _cream)),
            ),
            const SizedBox(width: 8),
            const WIcon('arrow', size: 14, strokeWidth: 2, color: _cream),
          ],
        ]),
      ),
    );
  }
}
