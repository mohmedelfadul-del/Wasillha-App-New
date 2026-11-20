import 'package:wa3_core/wa3_core.dart';

/// User-facing text for sign-in error codes.
String authMessage(S s, String code) => switch (code) {
      'invalid_phone_local' => s.t('أدخل رقم هاتف صحيحاً، مثل 912345678.', 'Enter a valid phone number, for example 912345678.'),
      'invalid-phone-number' => s.t('رقم الهاتف غير صحيح.', 'That phone number isn’t valid.'),
      'code_format' => s.t('الرمز من 6 أرقام.', 'The code has 6 digits.'),
      'invalid-verification-code' => s.t('الرمز غير صحيح. راجع الرسالة وحاول مجدداً.', 'That code is wrong. Check the SMS and try again.'),
      'session-expired' || 'code-expired' => s.t('انتهت صلاحية الرمز. اطلب رمزاً جديداً.', 'This code has expired. Ask for a new one.'),
      'too-many-requests' || 'quota-exceeded' => s.t('محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.', 'Too many attempts. Wait a while and try again.'),
      'network-request-failed' || 'send_timeout' => s.error('network'),
      'app-not-authorized' || 'missing-client-identifier' || 'captcha-check-failed' =>
        s.t('تعذّر التحقق من التطبيق لتسجيل الدخول. حدّث التطبيق أو تواصل معنا.', 'We couldn’t verify this app for sign-in. Update the app or contact us.'),
      _ => s.somethingWrong,
    };
