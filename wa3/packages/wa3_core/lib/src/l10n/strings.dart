import 'package:flutter/widgets.dart';

import '../contract/enums.dart';

/// Shared Arabic/English copy. Arabic is primary. Apps add their own screen
/// copy with [S.t]; this file holds what all three products say the same way.
class S {
  const S(this.lang);
  final String lang;
  bool get ar => lang == 'ar';
  TextDirection get dir => ar ? TextDirection.rtl : TextDirection.ltr;

  /// Pick the Arabic or English variant.
  String t(String arText, String en) => ar ? arText : en;

  String get currency => t('ج.س', 'SDG');
  String get retry => t('إعادة المحاولة', 'Try again');
  String get cancel => t('إلغاء', 'Cancel');
  String get confirm => t('تأكيد', 'Confirm');
  String get close => t('إغلاق', 'Close');
  String get loading => t('جارٍ التحميل…', 'Loading…');
  String get offlineTitle => t('لا يوجد اتصال', 'You’re offline');
  String get offlineBody => t('تحقق من الإنترنت. سنحدّث البيانات تلقائياً عند عودة الاتصال.', 'Check your internet. We’ll refresh automatically when you’re back online.');
  String get staleData => t('البيانات قد لا تكون محدّثة', 'This may be out of date');
  String get permissionDenied => t('ليس لديك صلاحية لهذا', 'You don’t have access to this');
  String get somethingWrong => t('حدث خطأ', 'Something went wrong');

  String state(TripState s) => switch (s) {
        TripState.draft => t('مسودة', 'Draft'),
        TripState.searching => t('نبحث عن سائقين', 'Finding drivers'),
        TripState.offering => t('وصلت عروض', 'Offers arriving'),
        TripState.driverAssigned => t('تم تعيين السائق', 'Driver assigned'),
        TripState.driverEnRoute => t('السائق في الطريق', 'Driver on the way'),
        TripState.driverArrived => t('السائق وصل', 'Driver has arrived'),
        TripState.inProgress => t('الرحلة جارية', 'On trip'),
        TripState.arrived => t('وصلت', 'Arrived'),
        TripState.paymentPending => t('بانتظار الدفع نقداً', 'Waiting for cash payment'),
        TripState.completed => t('مكتملة', 'Completed'),
        TripState.cancelled => t('ملغاة', 'Cancelled'),
        TripState.disputed => t('محل اعتراض', 'Disputed'),
      };

  String category(Category c) => switch (c) {
        Category.rickshaw => t('ركشة', 'Rickshaw'),
        Category.motorbike => t('موتر', 'Motorbike'),
        Category.economy => t('اقتصادي', 'Economy'),
        Category.comfort => t('مريح', 'Comfort'),
        Category.family => t('عائلي', 'Family'),
      };

  String cancelReason(String code) => switch (code) {
        'change_of_plans' => t('تغيّرت خططي', 'Change of plans'),
        'driver_too_far' => t('السائق بعيد جداً', 'Driver is too far'),
        'wrong_location' => t('الموقع غير صحيح', 'Wrong location'),
        'rider_no_show' => t('الراكب لم يحضر', 'Rider didn’t show up'),
        'rider_unreachable' => t('تعذّر الوصول للراكب', 'Can’t reach the rider'),
        'vehicle_issue' => t('مشكلة في المركبة', 'Vehicle problem'),
        'unsafe_situation' => t('موقف غير آمن', 'Unsafe situation'),
        'safety' => t('سلامة', 'Safety'),
        'fraud' => t('احتيال', 'Fraud'),
        'duplicate' => t('طلب مكرر', 'Duplicate'),
        'rider_request' => t('بطلب الراكب', 'Rider asked'),
        'driver_request' => t('بطلب السائق', 'Driver asked'),
        'no_offers' => t('لم يقبل أي عرض في الوقت المحدد', 'No offer was accepted in time'),
        'draft_expired' => t('انتهت صلاحية الطلب', 'Request expired'),
        _ => t('سبب آخر', 'Other'),
      };

  String docType(DocumentType d) => switch (d) {
        DocumentType.national_id => t('البطاقة الشخصية', 'National ID'),
        DocumentType.driving_license => t('رخصة القيادة', 'Driving licence'),
        DocumentType.vehicle_registration => t('ترخيص المركبة', 'Vehicle registration'),
        DocumentType.insurance => t('التأمين', 'Insurance'),
        DocumentType.driver_photo => t('صورتك الشخصية', 'Your photo'),
        DocumentType.vehicle_photo => t('صورة المركبة', 'Vehicle photo'),
      };

  String review(ReviewStatus r) => switch (r) {
        ReviewStatus.pending => t('قيد المراجعة', 'Under review'),
        ReviewStatus.approved => t('مقبول', 'Approved'),
        ReviewStatus.rejected => t('مرفوض', 'Rejected'),
        ReviewStatus.changesRequested => t('مطلوب تعديل', 'Changes requested'),
      };

  /// Precise, user-facing explanation for each server error code.
  String error(String code, [String? serverMessage]) => switch (code) {
        'network' => t('تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.', 'We couldn’t reach the server. Check your connection and try again.'),
        'stale_revision' => t('تغيّرت حالة الرحلة. حدّثنا الشاشة — راجعها وحاول مرة أخرى.', 'The trip changed. We refreshed it — check and try again.'),
        'invalid_transition' => t('لا يمكن تنفيذ هذا الإجراء في الحالة الحالية.', 'This action isn’t possible right now.'),
        'out_of_bounds' => t('القيمة خارج النطاق المسموح.', 'That amount is outside the allowed range.'),
        'offer_expired' => t('هذا العرض لم يعد متاحاً.', 'This offer is no longer available.'),
        'driver_busy' => t('هذا السائق أخذ رحلة أخرى للتو.', 'This driver just took another trip.'),
        'not_verified' => t('الحساب أو المركبة لم تُعتمد بعد.', 'Your account or vehicle isn’t approved yet.'),
        'outside_zone' => t('هذا الموقع خارج منطقة الخدمة حالياً.', 'This location is outside our service area.'),
        'maps_unavailable' => t('خدمة الخرائط غير متاحة الآن. حاول بعد قليل.', 'Maps are unavailable right now. Please try again shortly.'),
        'dispute_window_closed' => t('انتهت مهلة الاعتراض على هذه الرحلة.', 'The time to dispute this trip has passed.'),
        'permission_denied' => t('ليس لديك صلاحية لهذا الإجراء.', 'You don’t have permission to do this.'),
        'mfa_required' => t('أدخل رمز تطبيق المصادقة للمتابعة.', 'Enter your authenticator code to continue.'),
        'already_claimed' => t('زميل آخر يعمل على هذا العنصر.', 'Someone else is working on this item.'),
        'idempotency_mismatch' => t('تعارض في الطلب. أعد المحاولة.', 'Request conflict. Please try again.'),
        _ => serverMessage?.isNotEmpty == true ? serverMessage! : somethingWrong,
      };
}

/// Inherited access: `context.s.t('…', '…')`.
class WStrings extends InheritedWidget {
  const WStrings({super.key, required this.strings, required super.child});
  final S strings;
  static S of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<WStrings>()?.strings ?? const S('ar');
  @override
  bool updateShouldNotify(WStrings old) => old.strings.lang != strings.lang;
}

extension StringsX on BuildContext {
  S get s => WStrings.of(this);
}
