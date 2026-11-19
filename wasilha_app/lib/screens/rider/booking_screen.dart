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
import 'ride_common.dart';

/// 06 — Booking: route on the map, service options with real fares,
/// payment method, then on to the fare offer.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final Stream<UserProfile?> _profile;
  bool _redirected = false;

  static const _services = [ServiceType.raksha, ServiceType.moto, ServiceType.car];

  @override
  void initState() {
    super.initState();
    _profile = context.read<WasilhaBackend>().profile();
    final s = context.read<AppState>();
    if (!_services.contains(s.service)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) s.chooseService(ServiceType.car);
      });
    }
  }

  (String, String, String, String) _copy(ServiceType svc) => switch (svc) {
        ServiceType.raksha => ('1 seat', 'مقعد واحد', 'Most affordable', 'الأوفر سعرًا'),
        ServiceType.moto => ('1 seat', 'مقعد واحد', 'Beat the traffic', 'تخطَّ الزحمة'),
        _ => ('4 seats', '٤ مقاعد', 'Comfort & A/C', 'راحة وتكييف'),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dropoff = s.dropoff;
    if (dropoff == null) {
      if (!_redirected) {
        _redirected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.swap('search');
        });
      }
      return const Scaffold(backgroundColor: W.screenBg);
    }
    final km = s.pickup.kmTo(dropoff);
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        Positioned.fill(
          child: WMap(
            pickup: s.pickup,
            dropoff: dropoff,
            showRoute: true,
            pulse: true,
            drivers: 4,
            padding: EdgeInsets.only(top: 190, bottom: h * 0.5),
          ),
        ),
        // Top: back + addresses + route chip
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SquareIconBtn(icon: 'back', onTap: () => context.back()),
                const SizedBox(height: 12),
                _AddressCard(pickup: s.pickup, dropoff: dropoff),
                const SizedBox(height: 12),
                Center(child: _RouteChip(km: km, dropoff: dropoff)),
              ]),
            ),
          ),
        ),
        // Booking sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SheetIn(
            child: RideSheet(
              maxHeightFactor: 0.62,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SheetHandle(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: s.t('Choose a ', 'اختر ')),
                        TextSpan(text: s.t('ride', 'رحلتك'), style: TextStyle(color: s.accent)),
                      ]),
                      style: s.ar ? W.arSerif(size: 22) : W.serif(size: 22),
                    ),
                  ),
                  MonoLabel(s.t('${_services.length} OPTIONS', '${_services.length} خيارات'), spacing: 0.22),
                ]),
                const SizedBox(height: 10),
                for (final svc in _services) ...[
                  _ServiceOption(
                    svc: svc,
                    copy: _copy(svc),
                    minutes: serviceMinutes(svc, km),
                    fare: s.suggestedFare(svc),
                    active: s.service == svc,
                    onTap: () => s.chooseService(svc),
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 8),
                StreamBuilder<UserProfile?>(
                  stream: _profile,
                  builder: (context, snap) => _PaymentRow(
                    balance: snap.data?.balance,
                    fare: s.suggestedFare(),
                  ),
                ),
                const SizedBox(height: 14),
                Btn(
                  s.t('Send offer · ${sdg(s.suggestedFare())} SDG', 'أرسل عرضًا · ${sdg(s.suggestedFare())} ج.س'),
                  full: true,
                  icon: 'arrow',
                  onTap: () => context.go('offer'),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.pickup, required this.dropoff});
  final Place pickup;
  final Place dropoff;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget line(String label, Place p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MonoLabel(label, size: 8.5),
          const SizedBox(height: 1),
          Text(
            [p.label(s.ar), if (p.area.isNotEmpty && p.area != p.name) p.area].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: W.sans(size: 13.5, weight: FontWeight.w500),
          ),
        ]);
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Column(children: [
          Container(width: 9, height: 9, decoration: const BoxDecoration(color: W.success, shape: BoxShape.circle)),
          Container(width: 1.5, height: 22, margin: const EdgeInsets.symmetric(vertical: 4), color: W.border2),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: s.accent, borderRadius: BorderRadius.circular(2)),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.swap('search'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: W.border, width: 0.5))),
                child: line(s.t('PICKUP', 'الانطلاق'), pickup),
              ),
              Padding(padding: const EdgeInsets.only(top: 8), child: line(s.t('DESTINATION', 'الوجهة'), dropoff)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => comingSoon(context, s, s.t('Multi-stop trips', 'الرحلات متعددة المحطات')),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: WIcon('plus', size: 16, strokeWidth: 1.8, color: W.text2),
          ),
        ),
      ]),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.km, required this.dropoff});
  final double km;
  final Place dropoff;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget dot() => Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(color: W.text3, shape: BoxShape.circle),
        );
    final area = (dropoff.area.isEmpty ? dropoff.name : dropoff.area).toUpperCase();
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(s.t('${kmText(km)} KM', '${kmText(km)} كم'), style: W.mono(size: 11, color: W.text3, letterSpacing: 0.06)),
        dot(),
        Text(s.t('${rideMinutes(km)} MIN', '${rideMinutes(km)} د'),
            style: W.mono(size: 11, color: W.text, weight: FontWeight.w600, letterSpacing: 0.06)),
        dot(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            s.ar ? 'إلى ${dropoff.label(true)}' : 'TO $area',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s.ar ? W.ar(size: 11, color: s.accent) : W.mono(size: 11, color: s.accent, letterSpacing: 0.06),
          ),
        ),
      ]),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  const _ServiceOption({
    required this.svc,
    required this.copy,
    required this.minutes,
    required this.fare,
    required this.active,
    required this.onTap,
  });
  final ServiceType svc;
  final (String, String, String, String) copy;
  final int minutes;
  final int fare;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? a : W.border, width: active ? 1.5 : 0.5),
          boxShadow: active ? [BoxShadow(color: a.withValues(alpha: 0.1), blurRadius: 22, offset: const Offset(0, 8))] : null,
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? a.withValues(alpha: 0.08) : W.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: WIcon(svc.icon, size: 20, strokeWidth: 1.6, color: active ? a : W.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Flexible(
                  child: Text(svc.title(s.ar),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 14.5, weight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Text('· ${s.t(copy.$1, copy.$2)}',
                    style: s.ar ? W.ar(size: 10.5, color: W.text3) : W.mono(size: 10, color: W.text3, letterSpacing: 0)),
              ]),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: s.t(copy.$3, copy.$4)),
                  TextSpan(
                    text: s.t(' · $minutes min', ' · $minutes د'),
                    style: W.mono(size: 10.5, color: W.text3, letterSpacing: 0),
                  ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: W.sans(size: 11.5, color: W.text2),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(sdg(fare), style: W.serif(size: 20)),
            const SizedBox(height: 2),
            Text(s.t('SDG', 'ج.س'), style: W.mono(size: 9, color: W.text3, letterSpacing: 0.18)),
          ]),
        ]),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.balance, required this.fare});
  final int? balance;
  final int fare;

  void _choose(BuildContext context, AppState s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: W.screenBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHandle(),
            MonoLabel(s.t('PAY WITH', 'الدفع عبر')),
            const SizedBox(height: 4),
            WRow(
              icon: 'wallet',
              title: s.t('Wallet', 'المحفظة'),
              detail: balance == null ? null : s.t('Balance ${sdg(balance!)} SDG', 'الرصيد ${sdg(balance!)} ج.س'),
              trailing: s.payment == 'wallet' ? WIcon('check', size: 18, color: s.accent) : null,
              onTap: () {
                s.setPayment('wallet');
                Navigator.pop(ctx);
              },
            ),
            WRow(
              icon: 'receipt',
              title: s.t('Cash', 'نقدًا'),
              detail: s.t('Pay the driver directly', 'ادفع للسائق مباشرة'),
              trailing: s.payment == 'cash' ? WIcon('check', size: 18, color: s.accent) : null,
              divider: false,
              onTap: () {
                s.setPayment('cash');
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final wallet = s.payment == 'wallet';
    final low = wallet && balance != null && balance! < fare;
    BoxDecoration box() => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: low ? W.danger : W.border, width: 0.5),
        );
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _choose(context, s),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: box(),
            child: Row(children: [
              WIcon(wallet ? 'wallet' : 'receipt', size: 16, strokeWidth: 1.7, color: W.text),
              const SizedBox(width: 10),
              Expanded(
                child: Text(wallet ? s.t('Wallet', 'المحفظة') : s.t('Cash', 'نقدًا'), style: W.sans(size: 13)),
              ),
              if (wallet)
                Text(
                  balance == null ? '…' : sdg(balance!),
                  style: W.mono(size: 10, color: low ? W.danger : W.text3, letterSpacing: 0.06),
                ),
              const SizedBox(width: 6),
              const WIcon('chevDown', size: 12, color: W.text3),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => comingSoon(context, s, s.t('Promo codes', 'أكواد الخصم')),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: box().copyWith(border: Border.all(color: W.border, width: 0.5)),
          child: Row(children: [
            const WIcon('gift', size: 16, strokeWidth: 1.7, color: W.text),
            const SizedBox(width: 8),
            Text(s.t('Promo', 'خصم'), style: W.sans(size: 13)),
          ]),
        ),
      ),
    ]);
  }
}
