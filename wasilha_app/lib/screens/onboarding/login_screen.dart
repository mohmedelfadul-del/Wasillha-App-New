import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// 03 — Login: Sudan (+249) phone entry → SMS code.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (_error != null) setState(() => _error = null);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// National number without the leading 0 (e.g. "912345678").
  String get _national {
    var d = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  bool get _valid => RegExp(r'^[19]\d{8}$').hasMatch(_national);

  Future<void> _send() async {
    final s = context.read<AppState>();
    if (!_valid) {
      setState(() => _error = s.t('Enter a valid Sudanese number — 9 digits starting with 9 or 1.',
          'أدخل رقمًا سودانيًا صحيحًا — ٩ أرقام تبدأ بـ ٩ أو ١.'));
      return;
    }
    final phone = '+249$_national';
    setState(() => _loading = true);
    try {
      await context.read<WasilhaBackend>().sendCode(phone);
      if (!mounted) return;
      context.go('otp', args: phone);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _soon() {
    final s = context.read<AppState>();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: W.text,
      content: Text(s.t('Coming soon — use your phone number for now.', 'قريبًا — استخدم رقم هاتفك حاليًا.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final body = s.ar ? W.ar(size: 14, color: W.text2, height: 1.5) : W.sans(size: 14, color: W.text2, height: 1.5);

    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 16),
                Image.asset('assets/wasilha-logo.png', height: 56),
                const SizedBox(height: 40),
                Text(s.t('STEP 01 / WELCOME', 'الخطوة ٠١ / مرحبًا'),
                    style: s.ar ? W.ar(size: 12, color: accent, weight: FontWeight.w500) : W.mono(size: 10, color: accent, letterSpacing: 0.32)),
                const SizedBox(height: 14),
                if (s.ar) ...[
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'أهلاً '),
                      TextSpan(text: 'بعودتك', style: TextStyle(color: accent)),
                    ]),
                    style: W.arSerif(size: 48, height: 1.15),
                  ),
                  const SizedBox(height: 6),
                  Text('Welcome back.', style: W.serif(size: 24, color: W.text2)),
                ] else ...[
                  Text('Welcome', style: W.serif(size: 52)),
                  Text('back.', style: W.serif(size: 52, color: accent)),
                  const SizedBox(height: 10),
                  Text('أهلاً بعودتك', style: W.arSerif(size: 24, color: W.text2)),
                ],
                const SizedBox(height: 16),
                Text(
                  s.t("Enter your phone number. We'll send a one-time code to verify it's really you.",
                      'أدخل رقم هاتفك. سنرسل لك رمزًا لمرة واحدة للتحقق من هويتك.'),
                  style: body,
                ),
                const SizedBox(height: 40),
                _PhoneField(controller: _ctrl, focus: _focus, error: _error != null, onSubmit: _send),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!, style: (s.ar ? W.ar(size: 12) : W.sans(size: 12)).copyWith(color: W.danger)),
                  ),
                const SizedBox(height: 18),
                Btn(
                  s.t('Send code', 'أرسل الرمز'),
                  full: true,
                  icon: 'arrow',
                  loading: _loading,
                  onTap: _national.isEmpty ? null : _send,
                ),
                const SizedBox(height: 28),
                Row(children: [
                  const Expanded(child: Divider(color: W.border2, thickness: 0.5, height: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: MonoLabel(s.t('OR CONTINUE WITH', 'أو تابع باستخدام'), size: 11, spacing: 0.16),
                  ),
                  const Expanded(child: Divider(color: W.border2, thickness: 0.5, height: 0.5)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  for (final (i, l) in [('Apple', 'Apple'), ('Google', 'Google'), ('Email', 'البريد')].indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _soon,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: W.border, width: 0.5),
                          ),
                          child: Text(s.t(l.$1, l.$2), style: s.ar ? W.ar(size: 13) : W.sans(size: 13)),
                        ),
                      ),
                    ),
                  ],
                ]),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 30),
                  child: Center(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: s.t("By continuing you agree to Wasilha's ", 'بالمتابعة فإنك توافق على ')),
                        TextSpan(
                          text: s.t('Terms', 'الشروط'),
                          style: const TextStyle(color: W.text, decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: s.t(' & ', ' و')),
                        TextSpan(
                          text: s.t('Privacy', 'سياسة الخصوصية'),
                          style: const TextStyle(color: W.text, decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: s.t('.', ' الخاصة بوصلها.')),
                      ]),
                      textAlign: TextAlign.center,
                      style: (s.ar ? W.ar(size: 11, color: W.text3) : W.sans(size: 11, color: W.text3)).copyWith(height: 1.5),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.focus, required this.error, required this.onSubmit});
  final TextEditingController controller;
  final FocusNode focus;
  final bool error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Phone numbers always read left-to-right, even in Arabic.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: focus.requestFocus,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: error ? W.danger : W.border, width: error ? 1 : 0.5),
            boxShadow: const [BoxShadow(color: Color(0x0D140F1E), blurRadius: 22, offset: Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🇸🇩', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('+249', style: W.mono(size: 14, color: W.text, weight: FontWeight.w500, letterSpacing: 0)),
                const SizedBox(width: 6),
                const WIcon('chevDown', size: 14, color: W.text2),
              ]),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                onSubmitted: (_) => onSubmit(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _SudanPhoneFormatter(),
                ],
                cursorColor: context.watch<AppState>().accent,
                style: W.mono(size: 16, color: W.text, letterSpacing: 0.04),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  hintText: '91 234 5678',
                  hintStyle: W.mono(size: 16, color: W.text3, letterSpacing: 0.04),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Groups digits as "91 234 5678" (or "091 234 5678" with a trunk 0).
class _SudanPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'\D'), '');
    final lead = d.startsWith('0') ? 3 : 2;
    final groups = [lead, 3, 4];
    final b = StringBuffer();
    var i = 0;
    for (final g in groups) {
      if (i >= d.length) break;
      if (b.isNotEmpty) b.write(' ');
      final end = (i + g).clamp(0, d.length);
      b.write(d.substring(i, end));
      i = end;
    }
    if (i < d.length) b.write(d.substring(i));
    final text = b.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
