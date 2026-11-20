import 'package:wa3_core/wa3_core.dart';

/// "2026-11-20 14:05", bidi-isolated.
String dateTime(DateTime t) => '${ltr('${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}')} ${clock(t)}';
