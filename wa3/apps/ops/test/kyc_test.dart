import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_ops/app/widgets/failure.dart';
import 'package:wasilha_ops/features/kyc/domain/kyc_repository.dart';
import 'package:wasilha_ops/features/kyc/presentation/kyc_review_panel.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  final decisions = <String>[];
  var claims = 0;

  Widget panel(ReviewDocument d) => KycReviewPanel(
        doc: d,
        now: testNow,
        onClaim: () async => claims++,
        onDecide: (dec, reason) async => decisions.add('${dec.name}:$reason'),
        filePreview: const Text('FILE PREVIEW'),
      );

  setUp(() {
    decisions.clear();
    claims = 0;
  });

  test('claimStateOf', () {
    expect(claimStateOf(reviewDoc(), 'me-uid', testNow), ClaimState.unclaimed);
    expect(claimStateOf(reviewDoc(claimedBy: 'me-uid', claimedAt: testNow), 'me-uid', testNow), ClaimState.mine);
    expect(claimStateOf(reviewDoc(claimedBy: 'x', claimedAt: testNow.subtract(const Duration(minutes: 5))), 'me-uid', testNow), ClaimState.other);
    expect(claimStateOf(reviewDoc(claimedBy: 'x', claimedAt: testNow.subtract(const Duration(minutes: 16))), 'me-uid', testNow), ClaimState.unclaimed);
    expect(claimStateOf(reviewDoc(status: ReviewStatus.approved), 'me-uid', testNow), ClaimState.decided);
  });

  testWidgets('unclaimed: claim action, no file, no decisions', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc()));
    expect(find.text('Unclaimed'), findsOneWidget);
    expect(find.text('Claim for review'), findsOneWidget);
    expect(find.text('FILE PREVIEW'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    await tester.tap(find.text('Claim for review'));
    await tester.pump();
    expect(claims, 1);
  });

  testWidgets('claimed by me: file and decisions', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc(claimedBy: 'me-uid', claimedAt: testNow.subtract(const Duration(minutes: 2)))));
    expect(find.text('Claimed by you'), findsOneWidget);
    expect(find.text('FILE PREVIEW'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.byKey(const Key('reject')), findsOneWidget);
    expect(find.byKey(const Key('request-changes')), findsOneWidget);
    expect(find.text('Claim for review'), findsNothing);
  });

  testWidgets('claimed by another reviewer: who holds it, no actions', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc(claimedBy: 'other-reviewer', claimedAt: testNow.subtract(const Duration(minutes: 3)))));
    expect(find.textContaining('Being reviewed by: '), findsOneWidget);
    expect(find.textContaining('other-reviewer'), findsWidgets);
    expect(find.text('Claim for review'), findsNothing);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('FILE PREVIEW'), findsNothing);
  });

  testWidgets('decided: shows decision, reason, decidedBy and decidedAt', (tester) async {
    await pumpWidgetIn(
      tester,
      panel(reviewDoc(status: ReviewStatus.rejected, reason: 'Blurry photo', decidedBy: 'lead-reviewer', decidedAt: testNow.subtract(const Duration(hours: 1)))),
    );
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Blurry photo'), findsOneWidget);
    expect(find.textContaining('lead-reviewer'), findsOneWidget);
    expect(find.text('Decided at:'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Claim for review'), findsNothing);
  });

  testWidgets('reject requires a reason', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc(claimedBy: 'me-uid', claimedAt: testNow)));
    await tester.ensureVisible(find.byKey(const Key('reject')));
    await tester.tap(find.byKey(const Key('reject')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('reason-confirm'));
    expect(confirm, findsOneWidget);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'cannot reject without a reason');
    await tester.enterText(find.byKey(const Key('reason-field')), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'blank reason is not a reason');
    await tester.enterText(find.byKey(const Key('reason-field')), 'Licence expired');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(decisions, ['rejected:Licence expired']);
  });

  testWidgets('request changes also requires a reason; dismissing sends nothing', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc(claimedBy: 'me-uid', claimedAt: testNow)));
    await tester.ensureVisible(find.byKey(const Key('request-changes')));
    await tester.tap(find.byKey(const Key('request-changes')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('reason-confirm'))).onPressed, isNull);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(decisions, isEmpty);
  });

  testWidgets('approve asks for confirmation without a reason', (tester) async {
    await pumpWidgetIn(tester, panel(reviewDoc(claimedBy: 'me-uid', claimedAt: testNow)));
    await tester.ensureVisible(find.text('Approve'));
    await tester.tap(find.text('Approve'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('reason-field')), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(decisions, ['approved:null']);
  });

  test('already_claimed names who holds the item', () {
    const s = S('en');
    final f = const ApiFailure('already_claimed', 'Another reviewer is working on this item', {'code': 'already_claimed', 'claimedBy': 'uid-42'});
    expect(describeFailure(s, f, myUid: 'me'), contains('uid-42'));
    expect(describeFailure(s, f, myUid: 'me'), contains('Someone else is working on this item.'));
    expect(describeFailure(s, f, myUid: 'uid-42'), 'You already hold this item.');
  });

  test('permission_denied and mfa_required are explained precisely', () {
    const s = S('en');
    expect(describeFailure(s, const ApiFailure('permission_denied', 'Requires role: kyc')), contains('Requires role: kyc'));
    expect(describeFailure(s, const ApiFailure('mfa_required', 'Sign in with your authenticator code')), contains('authenticator'));
  });
}
