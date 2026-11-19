import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'ride_common.dart';

/// Dark hero card with the editable fare and the fair-range track.
class FareCard extends StatelessWidget {
  const FareCard({
    super.key,
    required this.offer,
    required this.fairLo,
    required this.fairHi,
    required this.trackLo,
    required this.trackHi,
    required this.locked,
    required this.onAdjust,
    required this.onFair,
  });

  final int offer;
  final int fairLo;
  final int fairHi;
  final int trackLo;
  final int trackHi;

  /// True once the request is posted (fare can only be raised then).
  final bool locked;
  final ValueChanged<int> onAdjust;
  final VoidCallback onFair;

  double _pct(int v) => trackHi == trackLo ? 0.5 : ((v - trackLo) / (trackHi - trackLo)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.accent;
    final within = offer >= fairLo && offer <= fairHi;
    final status = within
        ? s.t('IN FAIR RANGE', 'ضمن النطاق العادل')
        : offer < fairLo
            ? s.t('BELOW FAIR', 'أقل من العادل')
            : s.t('ABOVE FAIR', 'أعلى من العادل');
    final statusColor = within ? const Color(0xFF9DEACB) : const Color(0xFFF0B27A);
    final dotColor = within ? W.success : const Color(0xFFE4A93A);

    Widget stepBtn(String icon, int d, {bool accentBtn = false}) => GestureDetector(
          onTap: locked ? null : () => onAdjust(d),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: locked ? 0.35 : 1,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentBtn ? a.withValues(alpha: 0.14) : const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentBtn ? a.withValues(alpha: 0.4) : const Color(0x24FFFFFF), width: 0.5),
                boxShadow: accentBtn ? [BoxShadow(color: a.withValues(alpha: 0.2), blurRadius: 14)] : null,
              ),
              child: WIcon(icon, size: 18, strokeWidth: 1.8, color: Colors.white),
            ),
          ),
        );

    final chips = <(String, int?)>[
      ('−100', -100),
      ('−50', -50),
      (s.t('Fair', 'مقترح'), null),
      ('+50', 50),
      ('+100', 100),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: W.text,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x2E140F1E), blurRadius: 40, offset: Offset(0, 18))],
      ),
      child: Stack(children: [
        PositionedDirectional(
          end: -60,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [a.withValues(alpha: 0.33), a.withValues(alpha: 0)], stops: const [0, 0.65]),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              MonoLabel(s.t('YOUR OFFER', 'عرضك'), size: 9.5, spacing: 0.28, color: const Color(0x8CFFFFFF)),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: dotColor, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 6),
              MonoLabel(status, size: 9.5, color: statusColor),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              stepBtn('minus', -50),
              const SizedBox(width: 18),
              Expanded(
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: offer.toDouble()),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      builder: (_, v, _) => Text(
                        sdg(v),
                        style: W.serif(size: 56, color: Colors.white, letterSpacing: -2.2)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  MonoLabel(s.t('SDG', 'ج.س'), spacing: 0.34, color: const Color(0x73FFFFFF)),
                ]),
              ),
              const SizedBox(width: 18),
              stepBtn('plus', 50, accentBtn: true),
            ]),
            const SizedBox(height: 20),
            // Fair-range track
            LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              final lo = _pct(fairLo), hi = _pct(fairHi), th = _pct(offer);
              return Directionality(
                textDirection: TextDirection.ltr,
                child: SizedBox(
                  height: 14,
                  child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(3)),
                    ),
                    Positioned(
                      left: w * lo,
                      width: w * (hi - lo),
                      top: 4,
                      height: 6,
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0x599DEACB), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      left: w * th - 7,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: a,
                          shape: BoxShape.circle,
                          border: Border.all(color: W.text, width: 3, strokeAlign: BorderSide.strokeAlignOutside),
                          boxShadow: [BoxShadow(color: a, blurRadius: 12)],
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                Text(sdg(trackLo), style: W.mono(size: 10, color: const Color(0x80FFFFFF), letterSpacing: 0.06)),
                Expanded(
                  child: Text(
                    '${sdg(fairLo)} — ${sdg(fairHi)} ${s.t('fair range', 'نطاق عادل')}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: s.ar
                        ? W.ar(size: 10.5, color: const Color(0xFF9DEACB))
                        : W.mono(size: 10, color: const Color(0xFF9DEACB), letterSpacing: 0.06),
                  ),
                ),
                Text(sdg(trackHi), style: W.mono(size: 10, color: const Color(0x80FFFFFF), letterSpacing: 0.06)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: locked ? null : () => chips[i].$2 == null ? onFair() : onAdjust(chips[i].$2!),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: locked ? 0.35 : 1,
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chips[i].$2 == null ? a.withValues(alpha: 0.13) : const Color(0x0AFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: chips[i].$2 == null ? a.withValues(alpha: 0.5) : const Color(0x1AFFFFFF),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          chips[i].$1,
                          style: chips[i].$2 == null
                              ? (s.ar ? W.ar(size: 12, color: Colors.white) : W.serif(size: 14, color: Colors.white))
                              : W.mono(size: 11.5, color: Colors.white, letterSpacing: 0.08),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// CSS `ws-bid-in`: fade + rise + slight scale, once per bid.
class BidIn extends StatelessWidget {
  const BidIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: const Cubic(0.2, 0.85, 0.2, 1),
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)),
            child: Transform.scale(scale: 0.985 + 0.015 * v, child: c),
          ),
        ),
        child: child,
      );
}

/// Status dot with the CSS `ws-ping` ring while searching.
class PingDot extends StatelessWidget {
  const PingDot({super.key, required this.ping, required this.searching});
  final Animation<double> ping;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppState>().accent;
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: searching ? a : W.success, shape: BoxShape.circle),
          ),
        ),
        if (searching)
          Positioned(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: AnimatedBuilder(
              animation: ping,
              builder: (_, _) {
                final t = Curves.easeOut.transform(ping.value);
                return Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(
                    scale: 0.6 + 1.6 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: a, width: 1.5)),
                    ),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}

/// Placeholder bid row with the CSS `ws-pulse` shimmer.
class BidSkeleton extends StatelessWidget {
  const BidSkeleton({super.key, required this.pulse, required this.opacity});
  final Animation<double> pulse;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    Widget bar({double? w, double h = 10, double r = 4, BoxShape shape = BoxShape.rectangle, double? factor}) {
      final box = Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: W.surface2,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(r),
        ),
      );
      return factor == null ? box : FractionallySizedBox(widthFactor: factor, alignment: AlignmentDirectional.centerStart, child: box);
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: W.border2, width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: pulse,
          builder: (_, child) => Opacity(
            opacity: 0.5 + 0.4 * Curves.easeInOut.transform(pulse.value),
            child: child,
          ),
          child: Row(children: [
            bar(w: 42, h: 42, shape: BoxShape.circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                bar(factor: 0.45),
                const SizedBox(height: 6),
                bar(factor: 0.6, h: 8),
              ]),
            ),
            bar(w: 56, h: 24, r: 6),
          ]),
        ),
      ),
    );
  }
}

/// One incoming driver counter-offer.
class BidCard extends StatelessWidget {
  const BidCard({
    super.key,
    required this.bid,
    required this.requestedFare,
    required this.onAccept,
    required this.onDecline,
    this.accepting = false,
    this.disabled = false,
  });

  final Bid bid;
  final int requestedFare;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool accepting;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.accent;
    final delta = bid.amount - requestedFare;
    final matches = delta == 0;
    final deltaColor = delta <= 0 ? W.success : const Color(0xFFB05A1F);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: W.border, width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x0D140F1E), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Row(children: [
        Avatar(size: 42, label: bid.initials, tone: toneFor(bid.driverId)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Flexible(
                child: Text(bid.driverName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500)),
              ),
              const SizedBox(width: 6),
              Text('★ ${bid.rating.toStringAsFixed(1)}', style: W.mono(size: 10, color: W.text3, letterSpacing: 0)),
            ]),
            const SizedBox(height: 1),
            Text(bid.vehicle, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11, color: W.text2)),
            const SizedBox(height: 3),
            Row(children: [
              Text(s.t('${bid.etaMin} MIN', '${bid.etaMin} د'), style: W.mono(size: 9.5, letterSpacing: 0.14)),
              Container(
                width: 2,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(color: W.text3, shape: BoxShape.circle),
              ),
              Flexible(
                child: Text(s.t('${sdg(bid.trips)} TRIPS', '${sdg(bid.trips)} رحلة'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: W.mono(size: 9.5, letterSpacing: 0.14)),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(sdg(bid.amount), style: W.serif(size: 22, color: matches ? W.success : W.text)),
          const SizedBox(height: 3),
          Text(
            matches ? s.t('MATCHES', 'مطابق') : (delta > 0 ? '+${sdg(delta)}' : '−${sdg(-delta)}'),
            style: s.ar && matches
                ? W.ar(size: 10, color: deltaColor)
                : W.mono(size: 9.5, color: deltaColor, letterSpacing: 0.14),
          ),
        ]),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: disabled ? null : onAccept,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: a,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: a.withValues(alpha: 0.33), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: accepting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Semantics(
                      label: s.t('Accept', 'قبول'),
                      child: const WIcon('arrow', size: 16, strokeWidth: 2, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: disabled ? null : onDecline,
            child: Semantics(
              label: s.t('Decline', 'رفض'),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: WIcon('close', size: 12, strokeWidth: 2, color: W.text3),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
