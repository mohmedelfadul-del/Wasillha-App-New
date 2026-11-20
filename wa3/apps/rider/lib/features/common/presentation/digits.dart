import 'package:flutter/services.dart';

/// Converts Eastern Arabic (٠-٩) and Persian (۰-۹) digits to ASCII.
String asciiDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Accepts digits typed on an Arabic keyboard, keeps ASCII digits only.
class AsciiDigitsFormatter extends TextInputFormatter {
  const AsciiDigitsFormatter();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = asciiDigits(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (t == newValue.text) return newValue;
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
