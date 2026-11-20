import 'package:wa3_core/wa3_core.dart';

/// Precise sign-in failure copy.
String authError(S s, Object e) {
  final code = e is ApiFailure ? e.code : 'internal';
  return switch (code) {
    'auth/invalid-credential' || 'auth/wrong-password' || 'auth/user-not-found' || 'auth/invalid-login-credentials' =>
      s.t('البريد الإلكتروني أو كلمة المرور غير صحيحة.', 'The email or password is incorrect.'),
    'auth/invalid-email' => s.t('صيغة البريد الإلكتروني غير صحيحة.', 'That email address is not valid.'),
    'auth/user-disabled' => s.t('هذا الحساب معطّل. تواصل مع مدير النظام.', 'This account is disabled. Contact an admin.'),
    'auth/too-many-requests' => s.t('محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.', 'Too many attempts. Wait a moment and try again.'),
    'auth/invalid-verification-code' || 'auth/invalid-mfa-verification-code' || 'auth/code-expired' =>
      s.t('رمز تطبيق المصادقة غير صحيح أو انتهت صلاحيته.', 'The authenticator code is wrong or has expired.'),
    'auth/network-request-failed' || 'network' => s.error('network'),
    'auth/requires-recent-login' =>
      s.t('لأمان حسابك، سجّل الخروج ثم الدخول مجدداً وأعد المحاولة.', 'For your security, sign out, sign in again and retry.'),
    'auth/no-totp-factor' => s.t('هذا الحساب مسجّل بعامل تحقق غير تطبيق المصادقة. تواصل مع مدير النظام.',
        'This account uses a second factor other than an authenticator app. Contact an admin.'),
    'auth/operation-not-allowed' || 'auth/unsupported-first-factor' => s.t('المصادقة الثنائية بتطبيق المصادقة غير مفعّلة لهذا المشروع.',
        'Authenticator-app two-factor is not enabled for this project.'),
    'auth/totp-challenge-timeout' || 'auth/missing-multi-factor-session' =>
      s.t('انتهت مهلة الإعداد. ابدأ من جديد.', 'The setup timed out. Start again.'),
    _ => e is ApiFailure && e.message.isNotEmpty ? e.message : s.somethingWrong,
  };
}
