import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'auth_common.dart';

/// 04 — OTP: six-digit SMS code entry.
class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  static const _resendSecs = 47;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _resend = _resendSecs;
  bool _verifying = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _ctrl.addListener(() {
      setState(() {});
      if (_ctrl.text.length == 6 && !_verifying) _verify();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resend = _resendSecs);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resend <= 1) t.cancel();
      setState(() => _resend = (_resend - 1).clamp(0, _resendSecs));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _phone => ModalRoute.of(context)!.settings.arguments as String?;

  String _masked(String? p) {
    if (p == null || !p.startsWith('+249') || p.length < 13) return p ?? '+249';
    final n = p.substring(4); // 912345678
    return '+249 ${n.substring(0, 2)} *** ${n.substring(5)}';
  }

  Future<void> _verify() async {
    if (_ctrl.text.length != 6 || _verifying) return;
    final backend = context.read<WasilhaBackend>();
    setState(() => _verifying = true);
    try {
      await backend.verifyCode(_ctrl.text);
      final p = await firstProfile(backend);
      if (!mounted) return;
      context.root(routeForProfile(p));
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      _ctrl.clear();
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendCode() async {
    final phone = _phone;
    if (_resend > 0 || _sending || phone == null) return;
    final s = context.read<AppState>();
    setState(() => _sending = true);
    try {
      await context.read<WasilhaBackend>().sendCode(phone);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: W.text,
        content: Text(s.t('New code sent', 'تم إرسال رمز جديد')),
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final isDemo = context.read<WasilhaBackend>().isDemo;
    final code = _ctrl.text;
    final body = s.ar ? W.ar(size: 14, color: W.text2, height: 1.5) : W.sans(size: 14, color: W.text2, height: 1.5);

    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AuthBackBtn(
                onTap: () => context.back(),
                child: const WIcon('back', size: 18, strokeWidth: 1.7),
              ),
              const Spacer(),
              Text(s.t('STEP 02 / VERIFY', 'الخطوة ٠٢ / التحقق'),
                  style: s.ar ? W.ar(size: 12, color: W.text3) : W.mono(size: 10, color: W.text3, letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 40),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: s.t('Six digits.\n', 'ستة أرقام.\n')),
                TextSpan(text: s.t('One ride away.', 'وتبدأ رحلتك.'), style: TextStyle(color: accent)),
              ]),
              style: s.ar ? W.arSerif(size: 40, height: 1.2) : W.serif(size: 44, height: 1.02),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: s.t('We sent a code to ', 'أرسلنا رمزًا إلى ')),
                TextSpan(
                  text: '\u2066${_masked(_phone)}\u2069',
                  style: W.mono(size: 14, color: W.text, letterSpacing: 0.02),
                ),
              ]),
              style: body,
            ),
            const SizedBox(height: 36),
            _CodeBoxes(controller: _ctrl, focus: _focus, accent: accent, code: code),
            if (isDemo) ...[
              const SizedBox(height: 12),
              Row(children: [
                WIcon('sparkle', size: 13, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(s.t('Demo mode — any 6 digits work', 'الوضع التجريبي — أي ٦ أرقام تعمل'),
                      style: s.ar ? W.ar(size: 12, color: W.text3) : W.sans(size: 12, color: W.text3)),
                ),
              ]),
            ],
            const SizedBox(height: 24),
            Row(children: [
              Text(s.t("Didn't get it?", 'لم يصلك الرمز؟'), style: s.ar ? W.ar(size: 13, color: W.text2) : W.sans(size: 13, color: W.text2)),
              const Spacer(),
              GestureDetector(
                onTap: _resend > 0 ? null : _resendCode,
                child: _sending
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: accent))
                    : Text(
                        _resend > 0
                            ? s.t('RESEND IN 0:${_resend.toString().padLeft(2, '0')}',
                                'إعادة الإرسال بعد 0:${_resend.toString().padLeft(2, '0')}')
                            : s.t('TAP TO RESEND', 'اضغط لإعادة الإرسال'),
                        style: s.ar
                            ? W.ar(size: 12, color: _resend > 0 ? W.text3 : accent)
                            : W.mono(size: 12, color: _resend > 0 ? W.text3 : accent, letterSpacing: 0.06),
                      ),
              ),
            ]),
            const SizedBox(height: 32),
            Btn(
              s.t('Verify & continue', 'تحقق وتابع'),
              full: true,
              icon: 'arrow',
              loading: _verifying,
              onTap: code.length == 6 ? _verify : null,
            ),
          ]),
        ),
      ),
    );
  }
}

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.controller, required this.focus, required this.accent, required this.code});
  final TextEditingController controller;
  final FocusNode focus;
  final Color accent;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: focus.requestFocus,
        behavior: HitTestBehavior.opaque,
        child: Stack(children: [
          // Real input (invisible) that drives the boxes.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
              ),
            ),
          ),
          IgnorePointer(
            child: Row(children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _box(i)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _box(int i) {
    final filled = i < code.length;
    final isNext = i == code.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: filled ? accent : W.border, width: filled ? 1.5 : 0.5),
        boxShadow: filled
            ? [BoxShadow(color: accent.withValues(alpha: 0.125), blurRadius: 18, offset: const Offset(0, 6))]
            : const [BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: filled
          ? Text(code[i], style: W.mono(size: 28, color: W.text, weight: FontWeight.w500, letterSpacing: 0))
          : isNext
              ? PulseSoft(
                  period: const Duration(seconds: 1),
                  minOpacity: 0.2,
                  child: Container(width: 2, height: 28, color: accent),
                )
              : null,
    );
  }
}
