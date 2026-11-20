import '../contract/enums.dart';

/// Unicode isolates keep numbers, plates and phone numbers in the right order
/// inside Arabic text (bidi-safe). LRI … PDI.
String ltr(String s) => '\u2066$s\u2069';

/// "1,850" — Western digits with thousands separators (assumption: Western
/// digits are used in both languages for prices, plates and phone numbers).
String groupDigits(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (neg ? '-' : '') + b.toString();
}

/// Whole-unit money: "1,850 ج.س" / "1,850 SDG", bidi-isolated.
String money(int units, {required bool ar}) => ltr(groupDigits(units)) + (ar ? ' ج.س' : ' SDG');

/// Minor-unit ledger amounts shown as whole units (the ledger never holds fractions of a unit in v1).
String moneyMinor(int minor, {required bool ar}) {
  final whole = minor ~/ Tunables.minorPerUnit;
  final rest = (minor % Tunables.minorPerUnit).abs();
  final s = rest == 0 ? groupDigits(whole) : '${groupDigits(whole)}.${rest.toString().padLeft(2, '0')}';
  return ltr(s) + (ar ? ' ج.س' : ' SDG');
}

String km(int meters, {required bool ar}) {
  final v = meters >= 10000 ? (meters / 1000).round().toString() : (meters / 1000).toStringAsFixed(1);
  return ltr(v) + (ar ? ' كم' : ' km');
}

String minutes(int seconds, {required bool ar}) {
  final m = (seconds / 60).ceil().clamp(1, 999);
  return ltr('$m') + (ar ? ' د' : ' min');
}

/// "0:42" countdown.
String mmss(Duration d) {
  final s = d.inSeconds.clamp(0, 359999);
  return ltr('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}');
}

String clock(DateTime t) => ltr('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');

/// "12 min" / "3 h" age — for operations work queues.
String age(DateTime since, DateTime now, {required bool ar}) {
  final d = now.difference(since);
  if (d.inMinutes < 1) return ar ? 'الآن' : 'now';
  if (d.inMinutes < 60) return ltr('${d.inMinutes}') + (ar ? ' د' : ' min');
  if (d.inHours < 48) return ltr('${d.inHours}') + (ar ? ' س' : ' h');
  return ltr('${d.inDays}') + (ar ? ' يوم' : ' d');
}
