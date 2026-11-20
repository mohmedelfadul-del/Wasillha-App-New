import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Precise explanation of a failure, adding what the server told us
/// (who holds a claim, which role is required, how much is owed).
String describeFailure(S s, ApiFailure f, {String? myUid}) {
  final base = s.error(f.code, f.message);
  switch (f.code) {
    case 'already_claimed':
      final holder = f.details['claimedBy'] as String?;
      if (holder == null) return '$base (${f.message})';
      if (holder == myUid) return s.t('أنت تحمل هذا العنصر بالفعل.', 'You already hold this item.');
      return '$base ${s.t('يحمله الآن: ', 'Held by: ')}${ltr(holder)}';
    case 'permission_denied':
      return f.message.isNotEmpty && f.message != f.code ? '$base (${f.message})' : base;
    case 'mfa_required':
      return s.t(
        'جلستك لم تُوثَّق برمز تطبيق المصادقة. سجّل الخروج ثم سجّل الدخول مجدداً باستخدام الرمز.',
        'Your session was not verified with your authenticator code. Sign out, then sign in again with your code.',
      );
    case 'index_missing':
      return s.t('هذه القائمة تحتاج فهرس قاعدة بيانات غير منشور بعد. أبلغ الفريق التقني.',
          'This list needs a database index that is not deployed yet. Tell the engineering team.');
    case 'not_found':
      return s.t('غير موجود.', 'Not found.');
    case 'validation_failed':
      return s.t('القيمة غير صالحة: ', 'Invalid value: ') + f.message;
    case 'out_of_bounds':
      final owed = f.details['owedMinor'];
      if (owed is num) {
        final m = moneyMinor(owed.toInt(), ar: s.ar);
        return s.t('المبلغ أكبر من المستحق ($m).', 'The amount exceeds what is owed ($m).');
      }
      return base;
    case 'internal':
      return s.t('حدث خطأ في الخادم. حاول مرة أخرى.', 'Something went wrong on the server. Please try again.');
    default:
      return base;
  }
}

void showOpsFailure(BuildContext context, Object e, {String? myUid}) {
  final f = e is ApiFailure ? e : ApiFailure('internal', e.toString());
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white),
      const SizedBox(width: WSpace.sm),
      Expanded(child: Text(describeFailure(context.s, f, myUid: myUid))),
    ]),
    backgroundColor: WColors.error,
    duration: const Duration(seconds: 8),
  ));
}

/// Full-area error state with precise copy for permission and MFA failures.
Widget opsErrorView(BuildContext context, Object error, {VoidCallback? onRetry}) {
  final s = context.s;
  final f = error is ApiFailure ? error : ApiFailure('internal', error.toString());
  if (f.isNetwork) return WStateView.offline(context, onRetry: onRetry);
  if (f.code == 'permission_denied' || f.code == 'mfa_required') {
    return WStateView.permissionDenied(context, body: describeFailure(s, f));
  }
  return WStateView.error(context, ApiFailure(f.code, describeFailure(s, f)), onRetry: onRetry);
}
