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
import 'ride_common.dart';

/// 14 — Trip complete: rate the driver, tip, receipt.
class CompleteScreen extends StatefulWidget {
  const CompleteScreen({super.key});

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  late final AppState _s = context.read<AppState>();
  late final WasilhaBackend _b = context.read<WasilhaBackend>();
  StreamSubscription<Trip?>? _sub;
  Trip? _trip;
  bool _loaded = false;
  int _stars = 5;
  int _tip = 0;
  final Set<int> _tags = {0, 1};
  bool _submitting = false;

  static const _tips = [0, 500, 1000, 2000];
  static const _compliments = [
    ('Smooth ride', 'قيادة هادئة'),
    ('Friendly', 'ودود'),
    ('Clean car', 'سيارة نظيفة'),
    ('Quick arrival', 'وصول سريع'),
    ('Great music', 'موسيقى لطيفة'),
    ('Helpful', 'مساعد'),
  ];

  @override
  void initState() {
    super.initState();
    final id = _s.activeTripId;
    if (id == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.root('home');
      });
      return;
    }
    _sub = _b.watchTrip(id).listen((t) {
      if (!mounted) return;
      setState(() {
        _trip = t;
        _loaded = true;
      });
    }, onError: (Object e) {
      if (mounted) showError(context, e);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _submit({bool skip = false}) async {
    final t = _trip;
    if (t == null) {
      _s.setActiveTrip(null);
      context.root('home');
      return;
    }
    setState(() => _submitting = true);
    try {
      // Skipping still settles the fare; the rating stays at the default.
      await _b.completeAndRate(t.id, stars: _stars, tip: skip ? 0 : _tip);
      if (!mounted) return;
      _s.setActiveTrip(null);
      context.root('home');
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = _trip;
    if (t == null) {
      return Scaffold(
        backgroundColor: W.screenBg,
        body: Center(
          child: _loaded
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.t('Trip not found', 'الرحلة غير موجودة'), style: W.sans(size: 15)),
                  const SizedBox(height: 14),
                  Btn(s.t('Back home', 'العودة للرئيسية'), onTap: () {
                    s.setActiveTrip(null);
                    context.root('home');
                  }),
                ])
              : const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    final driverFirst = (t.driverName ?? '').trim().split(RegExp(r'\s+')).first;
    final driver = driverFirst.isEmpty ? s.t('your driver', 'السائق') : driverFirst;
    final receiptNo = t.id.length > 6 ? t.id.substring(t.id.length - 6).toUpperCase() : t.id.toUpperCase();

    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            // Header
            Row(children: [
              TextButton(
                onPressed: _submitting ? null : () => _submit(skip: true),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 36)),
                child: Text(s.t('Skip', 'تخطي'), style: W.sans(size: 13, color: W.text2)),
              ),
              Expanded(
                child: Center(
                  child: Text('${s.t('RECEIPT', 'إيصال')} · $receiptNo',
                      style: s.ar ? W.ar(size: 11, color: W.text3) : W.mono(size: 10, letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: 24),
            Text('● ${s.t('TRIP COMPLETE', 'الرحلة مكتملة')}',
                style: s.ar ? W.ar(size: 12, color: s.accent) : W.mono(size: 10, color: s.accent, letterSpacing: 0.32)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: s.t("You've ", 'وصلت ')),
                TextSpan(text: s.t('arrived.', 'بسلام.'), style: TextStyle(color: s.accent)),
              ]),
              style: s.ar ? W.arSerif(size: 42) : W.serif(size: 46, letterSpacing: -1.4),
            ),
            const SizedBox(height: 8),
            Text(s.t('How was your ride with $driver?', 'كيف كانت رحلتك مع $driver؟'),
                style: W.sans(size: 14, color: W.text2)),
            const SizedBox(height: 20),
            _ratingCard(s, t),
            const SizedBox(height: 14),
            _tipCard(s, driver),
            const SizedBox(height: 14),
            _totalCard(s, t),
            const SizedBox(height: 14),
            _receiptLines(s, t),
            const SizedBox(height: 16),
            Btn(
              s.t('Submit rating', 'إرسال التقييم'),
              full: true,
              icon: 'check',
              loading: _submitting,
              onTap: () => _submit(),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => comingSoon(context, s, s.t('PDF receipts', 'إيصالات PDF')),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: W.border, width: 0.5),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const WIcon('receipt', size: 15, strokeWidth: 1.7, color: W.text),
                  const SizedBox(width: 8),
                  Text(s.t('Download receipt', 'تنزيل الإيصال'), style: W.sans(size: 13.5)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingCard(AppState s, Trip t) {
    final label = _stars == 5
        ? s.t('Outstanding!', 'ممتاز!')
        : _stars >= 3
            ? s.t('Good', 'جيد')
            : s.t('Could be better', 'يحتاج تحسين');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: W.border, width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x0F140F1E), blurRadius: 28, offset: Offset(0, 10))],
      ),
      child: Column(children: [
        Row(children: [
          Avatar(size: 56, label: initialsOf(t.driverName), tone: toneFor(t.driverId ?? '')),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.driverName ?? s.t('Driver', 'السائق'),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 16, weight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                [if (t.driverPlate != null) t.driverPlate!, t.service.label.toUpperCase()].join(' · '),
                style: W.mono(size: 11, color: W.text2, letterSpacing: 0.08),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var n = 1; n <= 5; n++)
            GestureDetector(
              onTap: () => setState(() => _stars = n),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedScale(
                  scale: n <= _stars ? 1.05 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: n <= _stars ? W.gold : W.border2),
                    duration: const Duration(milliseconds: 200),
                    builder: (_, c, _) => WIcon('star', size: 38, strokeWidth: 1, color: c),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        Text(label, style: W.sans(size: 12, color: W.text2)),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < _compliments.length; i++)
            _Chip(
              label: s.t(_compliments[i].$1, _compliments[i].$2),
              on: _tags.contains(i),
              onTap: () => setState(() => _tags.contains(i) ? _tags.remove(i) : _tags.add(i)),
            ),
        ]),
      ]),
    );
  }

  Widget _tipCard(AppState s, String driver) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('Tip your driver', 'شكرًا للسائق'), style: W.sans(size: 14, weight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(s.t('100% goes directly to $driver.', 'كل القرشة تذهب لـ$driver مباشرة.'),
                    style: W.sans(size: 11.5, color: W.text2)),
              ]),
            ),
            WIcon('gift', size: 18, color: s.accent),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < _tips.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tip = _tips[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tip == _tips[i] ? s.accent.withValues(alpha: 0.07) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _tip == _tips[i] ? s.accent : W.border,
                        width: _tip == _tips[i] ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(
                      _tips[i] == 0 ? s.t('None', 'بدون') : sdg(_tips[i]),
                      style: W.sans(size: 13, weight: FontWeight.w500, color: _tip == _tips[i] ? s.accent : W.text),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ]),
      );

  Widget _totalCard(AppState s, Trip t) {
    Widget stat(String label, String value, {bool end = false}) => Column(
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MonoLabel(label, size: 8.5, color: const Color(0x80FFFFFF)),
            const SizedBox(height: 3),
            Text(value, style: W.sans(size: 13, color: Colors.white)),
          ],
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(18)),
      child: Stack(children: [
        PositionedDirectional(
          top: -30,
          end: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [s.accent.withValues(alpha: 0.31), s.accent.withValues(alpha: 0)],
                stops: const [0, 0.7],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MonoLabel(s.t('TOTAL', 'الإجمالي'), size: 9, spacing: 0.3, color: const Color(0x8CFFFFFF)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: (t.fare + _tip).toDouble()),
                duration: const Duration(milliseconds: 250),
                builder: (_, v, _) => Text(sdg(v), style: W.serif(size: 52, color: Colors.white, letterSpacing: -1.5)),
              ),
              const SizedBox(width: 6),
              Text(s.t('SDG', 'ج.س'), style: W.mono(size: 11, color: const Color(0x99FFFFFF))),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stat(s.t('DISTANCE', 'المسافة'), s.t('${kmText(t.distanceKm)} km', '${kmText(t.distanceKm)} كم')),
              const SizedBox(width: 16),
              stat(s.t('DURATION', 'المدة'), s.t('${t.etaMin} min', '${t.etaMin} دقيقة')),
              const Spacer(),
              stat(
                s.t('PAYMENT', 'الدفع'),
                t.payment == 'cash' ? s.t('Paid in cash', 'دُفع نقدًا') : s.t('Paid with Wallet', 'دُفع عبر المحفظة'),
                end: true,
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _receiptLines(AppState s, Trip t) {
    Widget line(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(label, style: W.sans(size: 13, color: bold ? W.text : W.text2, weight: bold ? FontWeight.w600 : FontWeight.w400))),
            Text(value, style: W.mono(size: 12, color: W.text, letterSpacing: 0.04, weight: bold ? FontWeight.w600 : FontWeight.w400)),
          ]),
        );
    final cur = s.t('SDG', 'ج.س');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: Column(children: [
        line(s.t('${t.service.label} fare', 'أجرة ${t.service.labelAr}'), '${sdg(t.fare)} $cur'),
        line(s.t('Tip', 'إكرامية'), _tip == 0 ? '—' : '${sdg(_tip)} $cur'),
        line(s.t('Payment', 'الدفع'), t.payment == 'cash' ? s.t('Cash', 'نقدًا') : s.t('Wallet', 'المحفظة')),
        const Divider(height: 14, thickness: 0.5, color: W.border),
        line(s.t('Total', 'الإجمالي'), '${sdg(t.fare + _tip)} $cur', bold: true),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppState>().accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? a.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? a : W.border, width: on ? 1 : 0.5),
        ),
        child: Text(label, style: W.sans(size: 11.5, weight: FontWeight.w500, color: on ? a : W.text)),
      ),
    );
  }
}
