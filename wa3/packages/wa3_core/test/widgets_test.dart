import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';

/// Every shared state renders at 320 px wide, RTL, with 200 % text, without overflow.
Widget harness(Widget child, {String lang = 'ar'}) => MediaQuery(
      data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2.0)),
      child: MaterialApp(
        theme: wasilhaTheme(Brightness.light),
        home: WStrings(
          strings: S(lang),
          child: Directionality(textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: Scaffold(body: child)),
        ),
      ),
    );

void main() {
  testWidgets('loading / empty / error / offline / permission states', (t) async {
    await t.binding.setSurfaceSize(const Size(320, 640));
    for (final w in <Widget>[
      WStateView.loading(),
      WStateView.empty(icon: Icons.history, title: 'لا توجد رحلات بعد', body: 'ستظهر رحلاتك المكتملة هنا.'),
      Builder(builder: (c) => WStateView.error(c, const ApiFailure('maps_unavailable', 'x'), onRetry: () {})),
      Builder(builder: (c) => WStateView.offline(c, onRetry: () {})),
      Builder(builder: (c) => WStateView.permissionDenied(c)),
    ]) {
      await t.pumpWidget(harness(w));
      await t.pump();
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('error view explains the specific failure in Arabic', (t) async {
    await t.pumpWidget(harness(Builder(builder: (c) => WStateView.error(c, const ApiFailure('outside_zone', 'x'), onRetry: () {}))));
    expect(find.textContaining('خارج منطقة الخدمة'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('badges and banners pair color with icon and text', (t) async {
    await t.binding.setSurfaceSize(const Size(320, 640));
    await t.pumpWidget(harness(const Column(children: [
      StatusBadge(tone: Tone.success, label: 'مقبول'),
      StatusBadge(tone: Tone.error, label: 'مرفوض مع سبب طويل جداً للتأكد من عدم الفيضان'),
      WBanner(tone: Tone.warning, text: 'آخر موقع للسائق قديم — قد لا يكون دقيقاً'),
    ])));
    expect(t.takeException(), isNull);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });

  testWidgets('primary action prevents double taps while busy', (t) async {
    var calls = 0;
    await t.pumpWidget(harness(PrimaryAction(label: 'تأكيد', onPressed: () async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    })));
    await t.tap(find.byType(FilledButton));
    await t.pump();
    await t.tap(find.byType(FilledButton));
    await t.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
  });

  testWidgets('touch targets are at least 48 dp', (t) async {
    await t.pumpWidget(harness(PrimaryAction(label: 'OK', onPressed: () async {})));
    expect(t.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
  });
}
