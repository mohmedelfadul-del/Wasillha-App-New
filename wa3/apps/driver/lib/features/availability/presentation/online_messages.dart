import 'package:wa3_core/wa3_core.dart';

import '../application/availability_controller.dart';

/// Precise, honest reason why going online (or offline) didn't work.
String onlineFailureText(S s, OnlineBlock block, ApiFailure? f) {
  switch (block) {
    case OnlineBlock.permission:
      return s.t('إذن الموقع مغلق. لا يمكنك الاتصال بالعمل بدونه: نحتاج موقعك لعرض الطلبات القريبة وليتابع الراكب الرحلة.',
          'Location permission is off. You can’t go online without it: we need your location to show nearby requests and let riders follow the trip.');
    case OnlineBlock.noFix:
      return s.t('لم نتمكن من تحديد موقعك. تأكد أن الموقع مفعّل وأنك في مكان مكشوف، ثم حاول مرة أخرى.',
          'We couldn’t get your GPS position. Check that location is on and you have a clear sky view, then try again.');
    case OnlineBlock.server:
      final code = f?.code ?? 'network';
      final msg = (f?.message ?? '').toLowerCase();
      if (code == 'outside_zone') {
        return s.t('أنت خارج منطقة التشغيل. توجّه إلى داخل منطقة الخدمة ثم حاول مرة أخرى.', 'You are outside the operating area. Drive into the service area and try again.');
      }
      if (code == 'validation_failed' && msg.contains('location')) {
        return s.t('الخادم لا يرى موقعاً حديثاً لك. أبقِ الموقع مفعّلاً وحاول بعد ثوانٍ.', 'The server can’t see a recent location from you. Keep location on and try again in a few seconds.');
      }
      if (code == 'validation_failed' && msg.contains('vehicle')) {
        return s.t('اختر مركبة معتمدة أولاً.', 'Choose an approved vehicle first.');
      }
      if (code == 'not_verified') return s.t('حسابك لم يُعتمد بعد.', 'Your account isn’t approved yet.');
      return s.error(code, f?.message);
  }
}
