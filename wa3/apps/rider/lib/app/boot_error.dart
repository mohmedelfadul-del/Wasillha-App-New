import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Full-screen, honest failure when Firebase can't start. No fake mode.
class BootErrorScreen extends StatelessWidget {
  const BootErrorScreen({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WSpace.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_outline, size: 40, color: WColors.error),
            const SizedBox(height: WSpace.md),
            Text(s.t('تعذّر تشغيل التطبيق', 'The app couldn’t start'), style: theme.textTheme.headlineMedium),
            const SizedBox(height: WSpace.md),
            Text(s.t(
              'إعدادات Firebase غير موجودة أو غير صحيحة. أضف android/app/google-services.json (أندرويد) أو ios/Runner/GoogleService-Info.plist (iOS) لمشروع وصلها ثم أعد البناء.',
              'Firebase configuration is missing or invalid. Add android/app/google-services.json (Android) or ios/Runner/GoogleService-Info.plist (iOS) for the Wasilha project, then rebuild.',
            )),
            const SizedBox(height: WSpace.lg),
            SelectableText(ltr(error.toString()), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
