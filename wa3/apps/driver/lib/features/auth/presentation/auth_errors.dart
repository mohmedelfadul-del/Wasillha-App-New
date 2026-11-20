import 'package:wa3_core/wa3_core.dart';

/// Firebase Auth error codes explained to the driver.
String authError(S s, String code) => switch (code) {
      'invalid-phone-number' => s.t('رقم الهاتف غير صحيح. اكتب رقمك السوداني مثل 912345678.', 'That phone number isn’t valid. Enter your Sudanese number, e.g. 912345678.'),
      'too-many-requests' || 'quota-exceeded' => s.t('محاولات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.', 'Too many attempts. Wait a while and try again.'),
      'invalid-verification-code' => s.t('الرمز غير صحيح. تأكد من الأرقام الستة في الرسالة.', 'That code is wrong. Check the 6 digits in the SMS.'),
      'session-expired' || 'code-expired' => s.t('انتهت صلاحية الرمز. اطلب رمزاً جديداً.', 'The code expired. Ask for a new one.'),
      'network-request-failed' => s.t('لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.', 'No internet connection. Check your network and try again.'),
      'user-disabled' => s.t('هذا الحساب موقوف. تواصل مع الدعم.', 'This account is disabled. Contact support.'),
      _ => s.t('تعذّر تسجيل الدخول. حاول مرة أخرى.', 'We couldn’t sign you in. Please try again.'),
    };
