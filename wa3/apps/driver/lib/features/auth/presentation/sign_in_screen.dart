import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../application/phone_sign_in_controller.dart';
import '../domain/phone_number.dart';
import 'auth_errors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final PhoneSignInController _c = PhoneSignInController(context.services.auth, clock: context.services.clock);
  final _phone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('وصلها — السائق', 'Wasilha Driver'))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.lg),
            child: _c.step == SignInStep.phone ? _phoneStep(s) : _codeStep(s),
          ),
        ),
      ),
    );
  }

  Widget _error(S s) => _c.errorCode == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: WSpace.md),
          child: WBanner(tone: Tone.error, text: authError(s, _c.errorCode!)),
        );

  Widget _phoneStep(S s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.t('سجّل الدخول برقم هاتفك', 'Sign in with your phone number'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: WSpace.sm),
        Text(s.t('سنرسل لك رمزاً من 6 أرقام في رسالة نصية.', 'We’ll text you a 6-digit code.')),
        const SizedBox(height: WSpace.xl),
        _error(s),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            decoration: InputDecoration(labelText: s.t('رقم الهاتف', 'Phone number'), prefixText: '$defaultCountryCode  ', hintText: '912345678'),
          ),
        ),
        const SizedBox(height: WSpace.xl),
        PrimaryAction(
          label: s.t('أرسل الرمز', 'Send code'),
          onPressed: () async {
            await _c.sendCode(_phone.text);
          },
        ),
      ]);

  Widget _codeStep(S s) {
    final at = _c.resendAt;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.t('أدخل الرمز', 'Enter the code'), style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: WSpace.sm),
      Text('${s.t('أرسلنا الرمز إلى', 'We sent it to')} ${ltr(_c.e164 ?? '')}'),
      const SizedBox(height: WSpace.xl),
      _error(s),
      Directionality(
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: s.t('الرمز', 'Code')),
        ),
      ),
      const SizedBox(height: WSpace.lg),
      PrimaryAction(label: s.t('تأكيد', 'Confirm'), onPressed: () => _c.confirm(_code.text)),
      const SizedBox(height: WSpace.md),
      if (at != null)
        Countdown(
          until: at,
          builder: (context, left) => TextButton(
            onPressed: left > Duration.zero || _c.sending ? null : () => _c.sendCode('', resend: true),
            child: Text(left > Duration.zero ? '${s.t('إعادة الإرسال بعد', 'Resend in')} ${mmss(left)}' : s.t('أعد إرسال الرمز', 'Resend code')),
          ),
        ),
      TextButton(onPressed: _c.changeNumber, child: Text(s.t('تغيير الرقم', 'Change number'))),
    ]);
  }
}
