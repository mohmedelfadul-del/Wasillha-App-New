import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_ops/features/cockpit/domain/cockpit_repository.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  const narrow = Size(320, 800);
  final summaries = {
    QueueKind.kycPending: QueueSummary(kind: QueueKind.kycPending, count: 50, countIsLowerBound: true, oldestAt: testNow.subtract(const Duration(hours: 30)), oldestOwner: 'reviewer-uid-123', unowned: 41),
    QueueKind.urgentSafety: QueueSummary(kind: QueueKind.urgentSafety, count: 2, oldestAt: testNow.subtract(const Duration(minutes: 14))),
    QueueKind.flaggedTrips: QueueSummary(kind: QueueKind.flaggedTrips, count: 3, oldestAt: testNow.subtract(const Duration(minutes: 52)), stuck: 2, stale: 1),
    QueueKind.openCases: const QueueSummary(kind: QueueKind.openCases, count: 0),
  };

  testWidgets('cockpit renders RTL at 320 px with 200 % text without overflow', (tester) async {
    await pumpApp(tester, fakeServices(session: staff(StaffRole.admin), cockpit: FakeCockpit(summaries)), lang: 'ar', size: narrow, textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(Directionality.of(tester.element(find.text('بلاغات سلامة عاجلة'))), TextDirection.rtl);
    // Scroll through every row so each one is laid out at this size.
    for (final title in ['وثائق بانتظار المراجعة', 'رحلات متعثرة أو موقعها قديم', 'اعتراضات وطلبات دعم مفتوحة']) {
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: title);
    }
    expect(find.text('لا شيء بالانتظار'), findsOneWidget);
  });

  testWidgets('KYC queue renders RTL at 320 px with 200 % text without overflow', (tester) async {
    final docs = [
      reviewDoc(path: 'drivers/d1/documents/driving_license', claimedBy: 'me-uid', claimedAt: testNow.subtract(const Duration(minutes: 3))),
      reviewDoc(path: 'drivers/d1/documents/national_id', type: DocumentType.national_id, claimedBy: 'someone-else-uid', claimedAt: testNow),
      reviewDoc(path: 'vehicles/v1/documents/vehicle_registration', type: DocumentType.vehicle_registration, vehicleId: 'v1', submittedAt: testNow.subtract(const Duration(days: 3))),
    ];
    await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc), kyc: FakeKyc(docs)), route: '/kyc', lang: 'ar', size: narrow, textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(find.text('محجوز لك'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('غير محجوز'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('غير محجوز'), findsOneWidget);
  });

  testWidgets('KYC review detail renders RTL at 320 px with 200 % text without overflow', (tester) async {
    final docs = [reviewDoc(claimedBy: 'me-uid', claimedAt: testNow)];
    await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc), kyc: FakeKyc(docs)),
        route: '/kyc/review?path=${Uri.encodeQueryComponent(docs.first.path)}', lang: 'ar', size: narrow, textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('أنت تحجز هذا العنصر'), findsOneWidget);
  });
}
