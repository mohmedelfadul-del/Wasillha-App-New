import 'package:wa3_core/wa3_core.dart';

/// App configuration. The operations support number is an ASSUMPTION
/// (placeholder); set the real one with --dart-define=OPS_PHONE=+249….
class AppConfig {
  const AppConfig._();
  static const opsPhone = String.fromEnvironment('OPS_PHONE', defaultValue: '+249900000000');

  /// wa.me wants digits only.
  static String get opsWhatsApp => opsPhone.replaceAll(RegExp(r'\D'), '');
}

/// Google Maps directions handoff (no key needed; opens the Maps app).
Uri directionsUri(GeoPoint to) =>
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${to.lat},${to.lng}&travelmode=driving');

Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);
Uri whatsAppUri(String digits) => Uri.parse('https://wa.me/$digits');
