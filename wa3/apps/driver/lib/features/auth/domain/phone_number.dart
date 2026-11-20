/// Default country for sign-in: Sudan (+249).
const defaultCountryCode = '+249';

/// Normalizes what a driver types into E.164. Local Sudanese numbers
/// (0912345678, 912345678, 249912345678) get +249; a number that already
/// starts with + or 00 is kept as international. Returns null if invalid.
String? normalizePhone(String input) {
  var d = input.replaceAll(RegExp(r'[\s\-().]'), '');
  if (d.startsWith('00')) d = '+${d.substring(2)}';
  if (d.startsWith('+')) {
    final digits = d.substring(1);
    if (!RegExp(r'^\d{8,15}$').hasMatch(digits)) return null;
    if (digits.startsWith('249') && !RegExp(r'^249[19]\d{8}$').hasMatch(digits)) return null;
    return d;
  }
  if (!RegExp(r'^\d+$').hasMatch(d)) return null;
  if (d.startsWith('249')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  if (!RegExp(r'^[19]\d{8}$').hasMatch(d)) return null;
  return '$defaultCountryCode$d';
}
