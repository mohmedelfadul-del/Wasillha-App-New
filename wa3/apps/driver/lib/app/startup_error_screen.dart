import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// Firebase couldn't start: say exactly which configuration is missing.
/// There is no fake mode.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.detail});
  final String detail;
  @override
  Widget build(BuildContext context) {
    const s = S('ar');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: wasilhaTheme(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline, color: WColors.error, size: 40),
              const SizedBox(height: WSpace.md),
              Text(s.t('تعذّر تشغيل التطبيق', 'The app couldn’t start'), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: WSpace.sm),
              const Text(
                'تعذّر الاتصال بـ Firebase. إعداد Firebase مفقود: أضف android/app/google-services.json (Android) '
                'أو ios/Runner/GoogleService-Info.plist (iOS) ثم أعد البناء.\n\n'
                'Firebase is not configured: add android/app/google-services.json (Android) or '
                'ios/Runner/GoogleService-Info.plist (iOS) and rebuild.',
              ),
              const SizedBox(height: WSpace.md),
              SelectableText(detail, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}
