import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/auth_repository.dart';
import 'auth_errors.dart';
import 'auth_frame.dart';

/// First sign-in: set up an authenticator app (TOTP). No QR package is
/// available, so the setup key is shown as text to type into the app.
class EnrollTotpScreen extends StatefulWidget {
  const EnrollTotpScreen({super.key, required this.repo, required this.onSignOut});
  final AuthRepository repo;
  final Future<void> Function() onSignOut;
  @override
  State<EnrollTotpScreen> createState() => _EnrollTotpScreenState();
}

class _EnrollTotpScreenState extends State<EnrollTotpScreen> {
  final _code = TextEditingController();
  TotpEnrollment? _enrollment;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final e = await widget.repo.startTotpEnrollment();
      if (mounted) setState(() => _enrollment = e);
    } catch (e) {
      if (mounted) setState(() => _error = authError(context.s, e));
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
      await widget.repo.completeTotpEnrollment(_enrollment!, _code.text);
    } catch (e) {
      if (mounted) setState(() => _error = authError(s, e));
    }
  }

  Future<void> _copy(String v) async {
    await Clipboard.setData(ClipboardData(text: v));
    if (mounted) showSuccess(context, context.s.t('تم النسخ', 'Copied'));
  }

  static String _grouped(String key) => [for (var i = 0; i < key.length; i += 4) key.substring(i, (i + 4).clamp(0, key.length))].join(' ');

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final e = _enrollment;
    final mono = Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 1.5);
    return AuthFrame(title: s.t('إعداد تطبيق المصادقة', 'Set up your authenticator app'), error: _error, children: [
      Text(s.t('حسابات الموظفين تتطلب تحققاً بخطوتين. ستحتاج تطبيق مصادقة على هاتفك (مثل Google Authenticator أو Microsoft Authenticator).',
          'Staff accounts require two-step verification. You need an authenticator app on your phone (for example Google Authenticator or Microsoft Authenticator).')),
      const SizedBox(height: WSpace.lg),
      if (e == null) ...[
        PrimaryAction(label: s.t('إنشاء مفتاح الإعداد', 'Create setup key'), icon: Icons.key, onPressed: _start),
        TextButton(onPressed: widget.onSignOut, child: Text(s.t('تسجيل الخروج', 'Sign out'))),
      ] else ...[
        Text(s.t('١. في التطبيق اختر «إضافة حساب» ثم «إدخال مفتاح الإعداد». اختر نوع «حسب الوقت».',
            '1. In the app choose “Add account”, then “Enter a setup key”. Choose “Time based”.')),
        const SizedBox(height: WSpace.sm),
        Text(s.t('٢. اكتب هذا المفتاح:', '2. Type this key:')),
        const SizedBox(height: WSpace.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
            SelectableText(_grouped(e.secretKey), key: const Key('totp-secret'), style: mono, semanticsLabel: e.secretKey.split('').join(' ')),
            IconButton(tooltip: s.t('نسخ المفتاح', 'Copy key'), icon: const Icon(Icons.copy), onPressed: () => _copy(e.secretKey)),
          ]),
        ),
        Text(s.t('الحساب: Wasilha Ops · ${e.codeLength ?? 6} أرقام · كل ${e.intervalSeconds ?? 30} ثانية',
            'Account: Wasilha Ops · ${e.codeLength ?? 6} digits · every ${e.intervalSeconds ?? 30} s'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: WSpace.md),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(s.t('رابط الإعداد (otpauth) لمن يستخدم مدير كلمات مرور', 'Setup link (otpauth) for password managers')),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                Expanded(child: SelectableText(e.otpauthUri, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                IconButton(tooltip: s.t('نسخ الرابط', 'Copy link'), icon: const Icon(Icons.copy), onPressed: () => _copy(e.otpauthUri)),
              ]),
            ),
          ],
        ),
        if (e.deadline != null)
          Text(s.t('أكمل الإعداد قبل ${clock(e.deadline!.toLocal())}', 'Finish before ${clock(e.deadline!.toLocal())}'), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: WSpace.md),
        Text(s.t('٣. أدخل الرمز الذي يظهر في التطبيق:', '3. Enter the code the app shows:')),
        const SizedBox(height: WSpace.sm),
        CodeField(controller: _code, onSubmitted: _verify),
        const SizedBox(height: WSpace.md),
        PrimaryAction(label: s.t('تحقق وفعّل', 'Verify and turn on'), onPressed: _verify),
        TextButton(onPressed: widget.onSignOut, child: Text(s.t('تسجيل الخروج', 'Sign out'))),
      ],
    ]);
  }
}

/// Authenticator enrolled, but this session predates it: sign in again with a code.
class ReauthScreen extends StatelessWidget {
  const ReauthScreen({super.key, required this.onSignOut});
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthFrame(title: s.t('سجّل الدخول برمز المصادقة', 'Sign in with your authenticator code'), children: [
      Text(s.t('تطبيق المصادقة مُعدّ لحسابك، لكن هذه الجلسة لم تُوثَّق به. سجّل الخروج ثم الدخول مجدداً وأدخل الرمز.',
          'Your authenticator app is set up, but this session was not verified with it. Sign out, sign in again and enter your code.')),
      const SizedBox(height: WSpace.lg),
      PrimaryAction(label: s.t('تسجيل الخروج والدخول مجدداً', 'Sign out and sign in again'), icon: Icons.logout, onPressed: onSignOut),
    ]);
  }
}
