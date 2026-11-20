import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_ops/app/sections.dart';
import 'package:wasilha_ops/features/auth/domain/auth_repository.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  group('gate', () {
    test('gateFor maps sessions to the right screen', () {
      expect(gateFor(null), GateState.signedOut);
      expect(gateFor(staff(null)), GateState.accessDenied);
      expect(gateFor(staff(StaffRole.kyc, isStaff: false)), GateState.accessDenied);
      expect(gateFor(const StaffSession(uid: 'u', staff: true, role: StaffRole.kyc, secondFactor: false, hasEnrolledTotp: false)), GateState.enrollTotp);
      expect(gateFor(const StaffSession(uid: 'u', staff: true, role: StaffRole.kyc, secondFactor: false, hasEnrolledTotp: true)), GateState.reauthWithTotp);
      expect(gateFor(staff(StaffRole.kyc)), GateState.ready);
      expect(StaffSession.parseRole('superuser'), isNull);
    });

    testWidgets('non-staff account sees access denied and can sign out', (tester) async {
      final auth = FakeAuth(staff(StaffRole.admin, isStaff: false));
      await pumpApp(tester, fakeServices(auth: auth));
      expect(find.text('You can’t use the operations console'), findsOneWidget);
      expect(find.text('This account is not a Wasilha staff account.'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pump();
      await tester.pump();
      expect(auth.signedOut, isTrue);
      expect(find.text('Staff sign-in'), findsOneWidget);
    });

    testWidgets('staff without a role sees access denied', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(null)));
      expect(find.text('You can’t use the operations console'), findsOneWidget);
      expect(find.textContaining('has no staff role'), findsOneWidget);
    });

    testWidgets('staff without an enrolled authenticator is guided to enroll', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc, mfa: false)));
      expect(find.text('Set up your authenticator app'), findsOneWidget);
      await tester.tap(find.text('Create setup key'));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('totp-secret')), findsOneWidget);
      expect(find.text('JBSW Y3DP EHPK 3PXP'), findsOneWidget);
    });
  });

  group('roles', () {
    testWidgets('kyc role opening /pricing directly gets the access-denied state', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc)), route: '/pricing');
      expect(find.text('You don’t have access to this'), findsOneWidget);
      expect(find.textContaining('“Pricing” is for: Admin'), findsOneWidget);
      expect(find.byKey(const Key('pricing-baseFare')), findsNothing);
    });

    testWidgets('kyc role opening /audit directly gets the access-denied state', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc)), route: '/audit');
      expect(find.text('You don’t have access to this'), findsOneWidget);
    });

    testWidgets('navigation shows only the sections the role can use', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(StaffRole.kyc)));
      final rail = find.byType(NavigationRail);
      expect(rail, findsOneWidget);
      expect(find.descendant(of: rail, matching: find.text('KYC review')), findsOneWidget);
      expect(find.descendant(of: rail, matching: find.text('Pricing')), findsNothing);
      expect(find.descendant(of: rail, matching: find.text('Audit log')), findsNothing);
      expect(find.descendant(of: rail, matching: find.text('Cash settlement')), findsNothing);
    });

    testWidgets('admin can open pricing', (tester) async {
      await pumpApp(tester, fakeServices(session: staff(StaffRole.admin)), route: '/pricing');
      await tester.pump();
      expect(find.byKey(const Key('pricing-baseFare')), findsOneWidget);
    });

    test('section matrix mirrors server roles', () {
      expect(Section.pricing.allows(StaffRole.operations), isFalse);
      expect(Section.pricing.allows(StaffRole.admin), isTrue);
      expect(Section.kyc.allows(StaffRole.support), isFalse);
      expect(Can.recordSettlement(StaffRole.operations), isFalse);
      expect(Can.recordSettlement(StaffRole.finance), isTrue);
      expect(Can.viewMoney(StaffRole.operations), isTrue);
      expect(Can.resolveDispute(StaffRole.operations), isFalse);
    });
  });
}
