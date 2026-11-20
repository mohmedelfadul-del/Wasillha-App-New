import '../../common/presentation/digits.dart';

/// Sudan is the default country.
const defaultDialCode = '+249';

/// Returns the E.164 number, or null when the input can't be a valid number.
/// Sudanese mobile numbers: 9 digits after +249 (a leading 0 is dropped).
String? normalizePhone(String dialCode, String national) {
  final dial = asciiDigits(dialCode).replaceAll(RegExp(r'[^0-9]'), '');
  var n = asciiDigits(national).replaceAll(RegExp(r'[\s\-().]'), '');
  if (dial.isEmpty || dial.length > 3 || !RegExp(r'^[0-9]+$').hasMatch(n)) return null;
  if (n.startsWith('0')) n = n.substring(1);
  if (dial == '249') {
    if (!RegExp(r'^[19][0-9]{8}$').hasMatch(n)) return null;
  } else if (n.length < 6 || dial.length + n.length > 15) {
    return null;
  }
  return '+$dial$n';
}
