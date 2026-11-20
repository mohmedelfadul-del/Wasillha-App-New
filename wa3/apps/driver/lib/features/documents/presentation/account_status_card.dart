import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// What the account status means for working. Submitting documents never
/// grants permission to work; only an approved account can go online.
class AccountStatusCard extends StatelessWidget {
  const AccountStatusCard({super.key, required this.status, this.action});
  final DriverStatus status;
  final Widget? action;

  static String title(S s, DriverStatus st) => switch (st) {
        DriverStatus.onboarding => s.t('أكمل وثائقك', 'Complete your documents'),
        DriverStatus.underReview => s.t('وثائقك قيد المراجعة', 'Your documents are under review'),
        DriverStatus.approved => s.t('حسابك معتمد', 'Your account is approved'),
        DriverStatus.suspended => s.t('حسابك موقوف', 'Your account is suspended'),
      };

  static String body(S s, DriverStatus st) => switch (st) {
        DriverStatus.onboarding => s.t(
            'ارفع البطاقة الشخصية ورخصة القيادة وصورتك. إرسال الوثائق لا يعني السماح بالعمل — يراجع فريقنا كل وثيقة أولاً.',
            'Upload your national ID, driving licence and photo. Submitting does not let you work yet — our team reviews each document first.'),
        DriverStatus.underReview => s.t(
            'لا يمكنك الاتصال بالعمل حتى يُعتمد حسابك. سيظهر قرار كل وثيقة هنا، وإن رُفضت وثيقة سنوضح السبب.',
            'You can’t go online until your account is approved. Each decision appears here; if a document is rejected we’ll tell you why.'),
        DriverStatus.approved => s.t('يمكنك الاتصال بالعمل عند اختيار مركبة معتمدة.', 'You can go online once you choose an approved vehicle.'),
        DriverStatus.suspended => s.t('لا يمكنك الاتصال بالعمل. تواصل مع الدعم لمعرفة السبب.', 'You can’t go online. Contact support to find out why.'),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tone = switch (status) {
      DriverStatus.approved => Tone.success,
      DriverStatus.suspended => Tone.error,
      DriverStatus.underReview => Tone.info,
      DriverStatus.onboarding => Tone.warning,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusBadge(tone: tone, label: title(s, status)),
          const SizedBox(height: WSpace.sm),
          Text(body(s, status)),
          if (action != null) ...[const SizedBox(height: WSpace.md), action!],
        ]),
      ),
    );
  }
}
