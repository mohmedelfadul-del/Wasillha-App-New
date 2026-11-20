import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../location/domain/location_service.dart';
import '../application/home_location_controller.dart';

/// Honest explanation when we don't know where the rider is.
class LocationNotice extends StatelessWidget {
  const LocationNotice({super.key, required this.controller});
  final HomeLocationController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = controller.result;
    if (controller.locating && !(r?.ok ?? false)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: WSpace.sm),
        child: Row(children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: WSpace.md),
          Expanded(child: Text(s.t('نحدد موقعك…', 'Finding your location…'))),
        ]),
      );
    }
    if (r == null || r.ok) return const SizedBox.shrink();
    final manual = s.t('يمكنك اختيار نقطة الانطلاق بنفسك.', 'You can still choose your pickup point yourself.');
    final (text, action, onAction) = switch (r.status) {
      LocationStatus.denied => (
          '${s.t('لم تسمح بالوصول إلى موقعك.', 'Location access isn’t allowed.')} $manual',
          s.t('السماح', 'Allow'),
          () => controller.locate(),
        ),
      LocationStatus.deniedForever => (
          '${s.t('الوصول إلى الموقع محظور في إعدادات الجهاز.', 'Location access is blocked in your device settings.')} $manual',
          s.t('الإعدادات', 'Settings'),
          controller.openSettings,
        ),
      LocationStatus.serviceOff => (
          '${s.t('خدمة الموقع مطفأة.', 'Location services are off.')} $manual',
          s.t('تشغيل', 'Turn on'),
          controller.openSettings,
        ),
      _ => (
          '${s.t('تعذّر تحديد موقعك الآن.', 'We couldn’t get your location right now.')} $manual',
          s.retry,
          () => controller.locate(),
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: WSpace.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WBanner(tone: Tone.warning, text: text, actionLabel: action, onAction: onAction),
      ),
    );
  }
}
