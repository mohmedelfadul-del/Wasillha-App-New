import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/features/request/presentation/fare_input.dart';
import 'package:wasilha_rider/features/request/presentation/request_screen.dart';

import 'support/fakes.dart';

void main() {
  const quote = Quote(referenceFare: 2000, minFare: 1500, maxFare: 3000);

  Future<List<int?>> pumpFare(WidgetTester tester, int initial) async {
    final values = <int?>[];
    await pumpRider(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, set) => FareInput(
            quote: quote,
            value: values.isEmpty ? initial : values.last,
            onChanged: (v) => set(() => values.add(v)),
          ),
        ),
      ),
    );
    return values;
  }

  testWidgets('typed fare below the minimum or above the maximum is rejected', (tester) async {
    final values = await pumpFare(tester, 2000);

    await tester.enterText(find.byKey(const Key('fare-field')), '1000');
    await tester.pump();
    expect(find.textContaining('The lowest allowed is'), findsOneWidget);
    expect(values.last, isNull);

    await tester.enterText(find.byKey(const Key('fare-field')), '3500');
    await tester.pump();
    expect(find.textContaining('The highest allowed is'), findsOneWidget);
    expect(values.last, isNull);

    await tester.enterText(find.byKey(const Key('fare-field')), '');
    await tester.pump();
    expect(find.text('Enter an amount'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fare-field')), '2600');
    await tester.pump();
    expect(find.textContaining('allowed is'), findsNothing);
    expect(values.last, 2600);
  });

  testWidgets('Arabic-Indic digits are accepted', (tester) async {
    final values = await pumpFare(tester, 2000);
    await tester.enterText(find.byKey(const Key('fare-field')), '٢٥٠٠');
    await tester.pump();
    expect(values.last, 2500);
  });

  testWidgets('stepper stops at the bounds', (tester) async {
    final values = await pumpFare(tester, 2990);
    await tester.tap(find.byTooltip('Raise the price'));
    await tester.pump();
    expect(values.last, 3000);
    final raise = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add));
    expect(raise.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('fare-field')), '1500');
    await tester.pump();
    final lower = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
    expect(lower.onPressed, isNull);
  });

  testWidgets('request flow: category → server price → invalid fare blocks confirm → valid fare confirms', (tester) async {
    final d = FakeDeps();
    d.trips.draft = () => sampleDraft(polyline: '_p~iF~ps|U_ulLnnqC_mqNvxq`@', estimated: false);
    await pumpRider(
      tester,
      const RequestScreen(pickup: Place(point: GeoPoint(15.59, 32.53), label: 'Riyadh'), dropoff: Place(point: GeoPoint(15.61, 32.55), label: 'Airport Road')),
      deps: d,
    );
    // Nothing price-related before a category is chosen.
    expect(find.text('Your price'), findsNothing);
    expect(find.textContaining('Request'), findsNothing);

    await tester.tap(find.text('Economy'));
    await tester.pump();
    await tester.pump();
    expect(d.trips.args['createDraft']?['category'], 'economy');
    expect(find.textContaining('Suggested price'), findsOneWidget);
    expect(find.textContaining('Estimated distance'), findsNothing);
    expect(d.maps.last.lines.single.points.length, 3);

    await tester.enterText(find.byKey(const Key('fare-field')), '900');
    await tester.pump();
    final disabled = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Request'));
    expect(disabled.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('fare-field')), '2200');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Request for ${money(2200, ar: false)}'));
    await tester.pump();
    expect(d.trips.args['confirmRequest'], {'tripId': 'trip-new', 'fare': 2200, 'revision': 1});
  });

  testWidgets('estimated route is labelled as an estimate', (tester) async {
    final d = FakeDeps();
    await pumpRider(
      tester,
      const RequestScreen(pickup: Place(point: GeoPoint(15.59, 32.53), label: 'Riyadh'), dropoff: Place(point: GeoPoint(15.61, 32.55), label: 'Airport Road'), category: null),
      deps: d,
    );
    await tester.tap(find.text('Comfort'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Estimated distance'), findsOneWidget);
    expect(d.maps.last.lines.single.dashed, isTrue);
  });
}
