import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/auth_repository.dart';
import 'auth_errors.dart';
import 'auth_frame.dart';

/// Email + password, then the authenticator code when the account has TOTP.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.repo});
  final AuthRepository repo;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  MfaChallenge? _challenge;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final s = context.s;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = s.t('أدخل البريد الإلكتروني وكلمة المرور.', 'Enter your email and password.'));
      return;
    }
    setState(() => _error = null);
    try {
      final r = await widget.repo.signIn(_email.text, _password.text);
      if (r is NeedsTotp && mounted) setState(() => _challenge = r.challenge);
    } catch (e) {
      if (mounted) setState(() => _error = authError(s, e));
    }
  }

  Future<void> _verify() async {
    final s = context.s;
    if (!isTotpCode(_code.text)) {
      setState(() => _error = s.t('أدخل الرمز المكوّن من ٦ أرقام.', 'Enter the 6-digit code.'));
      return;
    }
    setState(() => _error = null);
    try {
      await widget.repo.resolveTotp(_challenge!, _code.text);
    } catch (e) {
      if (mounted) setState(() => _error = authError(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_challenge != null) {
      return AuthFrame(title: s.t('التحقق بخطوتين', 'Two-step verification'), error: _error, children: [
        Text(s.t('افتح تطبيق المصادقة وأدخل الرمز الحالي لحساب «Wasilha Ops».', 'Open your authenticator app and enter the current code for “Wasilha Ops”.')),
        if (_challenge!.factorName != null) Text(_challenge!.factorName!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: WSpace.md),
        CodeField(controller: _code, onSubmitted: _verify),
        const SizedBox(height: WSpace.md),
        PrimaryAction(label: s.t('تحقق وادخل', 'Verify and sign in'), onPressed: _verify),
        TextButton(onPressed: () => setState(() { _challenge = null; _code.clear(); _error = null; }), child: Text(s.t('رجوع', 'Back'))),
      ]);
    }
    return AuthFrame(title: s.t('دخول الموظفين', 'Staff sign-in'), error: _error, children: [
      TextField(
        key: const Key('email'),
        controller: _email,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(labelText: s.t('البريد الإلكتروني', 'Email')),
      ),
      const SizedBox(height: WSpace.md),
      TextField(
        key: const Key('password'),
        controller: _password,
        obscureText: true,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _signIn(),
        decoration: InputDecoration(labelText: s.t('كلمة المرور', 'Password')),
      ),
      const SizedBox(height: WSpace.lg),
      PrimaryAction(label: s.t('متابعة', 'Continue'), onPressed: _signIn),
      const SizedBox(height: WSpace.md),
      Text(s.t('يتطلب الدخول تطبيق مصادقة (رمز من ٦ أرقام).', 'Sign-in requires an authenticator app (6-digit code).'),
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
