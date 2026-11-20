import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/app/live.dart';
import 'package:wasilha_driver/features/requests/domain/offer_math.dart';
import 'package:wasilha_driver/features/requests/presentation/offer_sheet.dart';
import 'package:wasilha_driver/features/requests/presentation/requests_section.dart';

import 'fakes.dart';

void main() {
  group('offer math', () {
    test('ETA ≈ distance / 25 km/h, at least 1, at most 60', () {
      expect(etaMinutesFor(0), 1);
      expect(etaMinutesFor(0.2), 1);
      expect(etaMinutesFor(5), 12);
      expect(etaMinutesFor(12.5), 30);
      expect(etaMinutesFor(40), 60);
    });

    test('price step is a round tenth of the range', () {
      expect(priceStep(1200, 1900), 50);
      expect(priceStep(100, 105), 1);
      expect(priceStep(1000, 6000), 500);
    });

    test('draft starts at the proposed fare and never leaves the bounds', () {
      final d = OfferDraft.forCard(requestCard(proposed: 1500, min: 1200, max: 1900));
      expect(d.price, 1500);
      expect(d.eta, 12);
      for (var i = 0; i < 30; i++) {
        d.raise();
      }
      expect(d.price, 1900);
      expect(d.canRaise, isFalse);
      for (var i = 0; i < 30; i++) {
        d.lower();
      }
      expect(d.price, 1200);
      expect(d.canLower, isFalse);
    });

    test('a proposed fare outside the bounds is clamped', () {
      expect(OfferDraft.forCard(requestCard(proposed: 5000, min: 1200, max: 1900)).price, 1900);
    });

    test('expired requests are hidden', () {
      final now = DateTime.now();
      final live = liveRequests([
        requestCard(id: 'gone', expiresIn: const Duration(seconds: -1)),
        requestCard(id: 'far', distanceKm: 9),
        requestCard(id: 'near', distanceKm: 1),
      ], now);
      expect(live.map((c) => c.tripId), ['near', 'far']);
    });
  });

  group('requests list', () {
    Future<Fakes> pump(WidgetTester t, List<RequestCard> cards) async {
      final f = Fakes();
      f.requests.inbox.add(Live(cards));
      await pumpHome(t, const Scaffold(body: SingleChildScrollView(child: RequestsSection(uid: 'd1'))), services: f.services(lang: 'en'));
      await t.pump();
      return f;
    }

    testWidgets('shows distance, fare, category, trip distance and countdown; hides expired', (t) async {
      await pump(t, [requestCard(id: 'live', distanceKm: 2.4), requestCard(id: 'old', proposed: 999, expiresIn: const Duration(seconds: -5))]);
      expect(find.textContaining('2.4'), findsOneWidget);
      expect(find.textContaining('1,500'), findsOneWidget);
      expect(find.text('Economy'), findsOneWidget);
      expect(find.textContaining('8.4'), findsOneWidget);
      expect(find.textContaining('Ends in'), findsOneWidget);
      expect(find.textContaining('999'), findsNothing);
    });

    testWidgets('empty state when nothing is nearby', (t) async {
      await pump(t, [requestCard(expiresIn: const Duration(seconds: -5))]);
      expect(find.text('No nearby requests right now'), findsOneWidget);
    });

    testWidgets('two taps: card → prefilled sheet → Send offer', (t) async {
      final f = await pump(t, [requestCard(id: 'trip9', proposed: 1500, min: 1200, max: 1900, distanceKm: 5)]);
      await t.tap(find.textContaining('Tap to make an offer'));
      await t.pumpAndSettle();
      expect(find.byType(OfferSheet), findsOneWidget);
      expect(find.descendant(of: find.byType(OfferSheet), matching: find.textContaining('1,500')), findsWidgets);
      await t.tap(find.widgetWithText(PrimaryAction, 'Send offer'));
      await t.pumpAndSettle();
      expect(f.requests.offers.single, (tripId: 'trip9', price: 1500, eta: 12));
      expect(find.byType(OfferSheet), findsNothing);
    });

    testWidgets('steppers stop at the quote bounds', (t) async {
      final f = await pump(t, [requestCard(id: 'trip9', proposed: 1800, min: 1200, max: 1900)]);
      await t.tap(find.textContaining('Tap to make an offer'));
      await t.pumpAndSettle();
      final plus = find.byTooltip('Raise price');
      await t.tap(plus);
      await t.pump();
      await t.tap(plus);
      await t.pump();
      await t.tap(plus);
      await t.pump();
      expect(t.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.add).first, matching: find.byType(IconButton))).onPressed, isNull);
      await t.tap(find.widgetWithText(PrimaryAction, 'Send offer'));
      await t.pumpAndSettle();
      expect(f.requests.offers.single.price, 1900);
    });
  });
}
