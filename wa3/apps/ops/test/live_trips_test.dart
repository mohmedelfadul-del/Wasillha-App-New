import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  final trips = [
    tripRecord('trip-ok', TripState.driverEnRoute),
    tripRecord('trip-stuck', TripState.inProgress, stuck: true, inState: const Duration(minutes: 47)),
    tripRecord('trip-stale', TripState.driverArrived, stale: true),
  ];

  testWidgets('stuck and stale trips carry text badges, not color alone', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, fakeServices(session: staff(StaffRole.operations), trips: FakeTrips(trips)), route: '/trips');
    expect(find.text('3 live trips · 2 need attention'.replaceAll('3', '\u20663\u2069').replaceAll('2 need', '\u20662\u2069 need')), findsOneWidget);
    expect(find.byKey(const Key('badge-stuck')), findsOneWidget);
    expect(find.text('Stuck: no progress'), findsOneWidget);
    expect(find.byKey(const Key('badge-stale')), findsOneWidget);
    expect(find.text('Driver location stale'), findsOneWidget);
    expect(find.textContaining('In this state for: \u206647\u2069 min'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Trip needs attention')), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('flagged-only filter hides healthy trips', (tester) async {
    await pumpApp(tester, fakeServices(session: staff(StaffRole.operations), trips: FakeTrips(trips)), route: '/trips');
    expect(find.text('Driver en route to pickup'), findsOneWidget);
    await tester.tap(find.text('Flagged only'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Driver en route to pickup'), findsNothing);
    expect(find.byKey(const Key('badge-stuck')), findsOneWidget);
  });

  testWidgets('empty live board', (tester) async {
    await pumpApp(tester, fakeServices(session: staff(StaffRole.operations), trips: FakeTrips()), route: '/trips');
    expect(find.text('No live trips'), findsOneWidget);
  });
}
