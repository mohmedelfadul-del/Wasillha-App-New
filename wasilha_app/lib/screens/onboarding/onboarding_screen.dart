import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// 02 — Onboarding: three editorial slides.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.hero, this.kickerEn, this.kickerAr, this.en, this.ar, this.bodyEn, this.bodyAr);
  final String hero, kickerEn, kickerAr, en, ar, bodyEn, bodyAr;
}

const _slides = [
  _Slide('raksha', 'MOTION', 'الحركة', 'Every way to move.', 'كل وسائل النقل',
      'Raksha, car, motorcycle, delivery — one tap to anywhere across Khartoum.',
      'راكشة، سيارة، دراجة، توصيل — كلها في تطبيق واحد.'),
  _Slide('pricing', 'CLARITY', 'الشفافية', 'Price before you ride.', 'السعر قبل الركوب',
      'No surprises. See the fare and route up front, every single trip.',
      'بدون مفاجآت. التسعير واضح وعادل قبل تأكيد الرحلة.'),
  _Slide('trust', 'TRUST', 'الثقة', 'Drivers you trust.', 'سائقون موثوقون',
      'Every driver verified, every ride tracked. One tap for help, anywhere.',
      'كل سائق متحقق منه، مع تتبع مباشر وزر طوارئ.'),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AppState>().setOnboarded();
    context.root('login');
  }

  void _next() {
    if (_i < _slides.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: Column(children: [
          // top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
            child: Row(children: [
              Text('${(_i + 1).toString().padLeft(2, '0')} / 03',
                  style: W.mono(size: 10, color: W.text2, letterSpacing: 0.3)),
              const Spacer(),
              _LangToggle(ar: s.ar, onChanged: s.setLang),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: W.text2),
                child: Text(s.t('Skip', 'تخطي'),
                    style: s.ar ? W.ar(size: 13, color: W.text2) : W.sans(size: 13, color: W.text2)),
              ),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (context, i) => _SlideView(slide: _slides[i], s: s),
            ),
          ),
          // footer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
            child: Row(children: [
              for (var d = 0; d < _slides.length; d++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  width: d == _i ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: d == _i ? accent : W.border2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _next,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const WIcon('arrow', size: 20, strokeWidth: 1.8, color: Colors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.ar, required this.onChanged});
  final bool ar;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String id, String label, bool on, TextStyle style) => GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: on ? W.text : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label, style: style.copyWith(color: on ? Colors.white : W.text2)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('en', 'EN', !ar, W.mono(size: 10, letterSpacing: 0.12, weight: FontWeight.w500)),
        seg('ar', 'العربية', ar, W.ar(size: 11, weight: FontWeight.w500)),
      ]),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.s});
  final _Slide slide;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final accent = s.accent;
    final headline = s.ar ? slide.ar : slide.en;
    final words = headline.split(' ');
    final lead = words.sublist(0, words.length - 1).join(' ');
    final last = words.last;
    final headStyle = s.ar ? W.arSerif(size: 42, height: 1.15) : W.serif(size: 46, height: 1.02);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: Center(child: FittedBox(child: OnboardHero(kind: slide.hero))),
          ),
        ),
        Text(s.t(slide.kickerEn, slide.kickerAr),
            style: s.ar ? W.ar(size: 12, color: accent, weight: FontWeight.w500) : W.mono(size: 10, color: accent, letterSpacing: 0.32)),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '$lead '),
            TextSpan(text: last, style: TextStyle(color: accent)),
          ]),
          style: headStyle,
        ),
        const SizedBox(height: 8),
        // the other-language echo line, as in the design
        Text(s.ar ? slide.en : slide.ar,
            style: s.ar ? W.serif(size: 22, color: W.text2) : W.arSerif(size: 22, color: W.text2)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(s.t(slide.bodyEn, slide.bodyAr),
              style: s.ar ? W.ar(size: 14, color: W.text2, height: 1.55) : W.sans(size: 14, color: W.text2, height: 1.55)),
        ),
      ]),
    );
  }
}

/// Abstract editorial hero illustrations (280×280).
class OnboardHero extends StatelessWidget {
  const OnboardHero({super.key, required this.kind});
  final String kind;

  static const _cardShadow = [BoxShadow(color: Color(0x1A140F1E), blurRadius: 60, offset: Offset(0, 24))];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final card = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: _cardShadow);

    Widget body;
    if (kind == 'raksha') {
      body = Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(-12, 8),
            child: Transform.rotate(
              angle: -0.105,
              child: Container(
                decoration: BoxDecoration(color: W.text.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(-6, 4),
            child: Transform.rotate(
              angle: -0.052,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: 0.19), width: 0.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.03)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: card,
            child: Stack(children: [
              const Center(child: WIcon('raksha', size: 160, strokeWidth: 1.2, color: W.text)),
              Positioned(
                left: 20,
                bottom: 18,
                child: Text('RAKSHA · KRT', style: W.mono(size: 9, letterSpacing: 0.22)),
              ),
              Positioned(
                right: 20,
                top: 18,
                child: Text(s.t('● LIVE', '● مباشر'),
                    style: s.ar ? W.ar(size: 10, color: accent) : W.mono(size: 9, color: accent, letterSpacing: 0.22)),
              ),
            ]),
          ),
        ),
      ]);
    } else if (kind == 'pricing') {
      final types = [s.t('Raksha', 'ركشة'), s.t('Car', 'سيارة'), s.t('Bike', 'دراجة')];
      body = Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Container(
            decoration: card,
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('FARE PREVIEW', 'معاينة الأجرة'), size: 9),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('4,200', style: W.serif(size: 64)),
                const SizedBox(width: 4),
                Text('SDG', style: W.mono(size: 11, color: W.text2)),
              ]),
              const SizedBox(height: 6),
              Text(s.t('Khartoum 2 → Bahri', 'الخرطوم ٢ ← بحري'), style: W.sans(size: 12, color: W.text2)),
              const Spacer(),
              Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 1 ? W.text : W.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(types[i],
                          style: W.sans(size: 11, weight: FontWeight.w500, color: i == 1 ? Colors.white : W.text)),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
        ),
        PositionedDirectional(
          top: -10,
          end: -10,
          child: Transform.rotate(
            angle: 0.14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.31), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Text(s.t('fair', 'عادل'),
                  style: s.ar ? W.arSerif(size: 18, color: Colors.white) : W.serif(size: 18, color: Colors.white)),
            ),
          ),
        ),
      ]);
    } else {
      body = Container(
        decoration: card,
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Avatar(size: 54, label: 'OM', tone: 'warm'),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t('Omar M.', 'عمر م.'), style: W.sans(size: 16, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(children: [
                const WIcon('star', size: 12, color: W.gold),
                const SizedBox(width: 4),
                Text(s.t('4.96 · 2,108 rides', '4.96 · 2,108 رحلة'), style: W.sans(size: 12, color: W.text2)),
              ]),
            ]),
          ]),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('VEHICLE', 'المركبة'), size: 9, spacing: 0.2),
              const SizedBox(height: 4),
              Text(s.t('Toyota Corolla · White', 'تويوتا كورولا · أبيض'), style: W.sans(size: 14)),
              const SizedBox(height: 8),
              Text('KRT · 4421', style: W.mono(size: 14, color: W.text, weight: FontWeight.w600, letterSpacing: 0.18)),
            ]),
          ),
          const Spacer(),
          Row(children: [
            Expanded(child: _chip('shield', s.t('Verified', 'موثّق'), W.surface2, W.text2)),
            const SizedBox(width: 8),
            Expanded(child: _chip('eye', s.t('Tracked', 'متتبَّع'), accent.withValues(alpha: 0.08), accent)),
          ]),
        ]),
      );
    }
    return SizedBox(width: 280, height: 280, child: body);
  }

  Widget _chip(String icon, String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          WIcon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(label, style: W.sans(size: 11, color: fg)),
        ]),
      );
}
