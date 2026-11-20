import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/presentation/digits.dart';
import '../application/phone_sign_in_controller.dart';
import 'auth_messages.dart';
import 'code_step.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final PhoneSignInController _c = PhoneSignInController(context.deps.auth);
  final _dial = TextEditingController(text: '+249');
  final _phone = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    _dial.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            leading: _c.stage == SignInStage.code
                ? IconButton(tooltip: context.s.t('تغيير الرقم', 'Change number'), icon: const BackButtonIcon(), onPressed: _c.changeNumber)
                : null,
          ),
          body: SafeArea(child: _c.stage == SignInStage.phone ? _phoneStep(context) : CodeStep(controller: _c)),
        ),
      );

  Widget _phoneStep(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WSpace.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.t('وصلها', 'Wasilha'), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: WSpace.sm),
        Text(s.t('سجّل دخولك برقم هاتفك', 'Sign in with your phone number'), style: theme.textTheme.headlineMedium),
        const SizedBox(height: WSpace.sm),
        Text(s.t('سنرسل لك رمزاً في رسالة نصية.', 'We’ll text you a one-time code.'), style: theme.textTheme.bodyMedium),
        const SizedBox(height: WSpace.xl),
        // Phone numbers are always left-to-right.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _dial,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+0-9٠-٩]')), LengthLimitingTextInputFormatter(4)],
                decoration: InputDecoration(labelText: s.t('الرمز', 'Code')),
                onChanged: (v) {
                  _c.dialCode = v;
                  _c.clearError();
                },
              ),
            ),
            const SizedBox(width: WSpace.sm),
            Expanded(
              child: TextField(
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [const AsciiDigitsFormatter(), LengthLimitingTextInputFormatter(14)],
                decoration: InputDecoration(
                  labelText: s.t('رقم الهاتف', 'Phone number'),
                  hintText: '912345678',
                  errorText: _c.error == null ? null : authMessage(s, _c.error!),
                  errorMaxLines: 4,
                ),
                onChanged: (_) => _c.clearError(),
                onSubmitted: (_) => _c.sendCode(_phone.text, lang: s.lang),
              ),
            ),
          ]),
        ),
        const SizedBox(height: WSpace.xl),
        PrimaryAction(label: s.t('أرسل الرمز', 'Send code'), onPressed: () => _c.sendCode(_phone.text, lang: s.lang)),
      ]),
    );
  }
}
