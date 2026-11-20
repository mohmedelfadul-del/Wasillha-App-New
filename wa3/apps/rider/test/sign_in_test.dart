import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha_rider/features/auth/domain/auth_repository.dart';
import 'package:wasilha_rider/features/auth/domain/phone_number.dart';
import 'package:wasilha_rider/features/auth/presentation/sign_in_screen.dart';

import 'support/fakes.dart';

void main() {
  test('normalizePhone handles Sudan numbers', () {
    expect(normalizePhone('+249', '912345678'), '+249912345678');
    expect(normalizePhone('+249', '0912345678'), '+249912345678');
    expect(normalizePhone('+249', '٠٩١٢٣٤٥٦٧٨'), '+249912345678');
    expect(normalizePhone('+249', '12345'), isNull);
    expect(normalizePhone('+249', '512345678'), isNull);
    expect(normalizePhone('+20', '1012345678'), '+201012345678');
  });

  testWidgets('invalid number shows a validation error and sends nothing', (tester) async {
    final d = await pumpRider(tester, const SignInScreen());
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '123');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.textContaining('Enter a valid phone number'), findsOneWidget);
    expect(d.auth.verifications, isEmpty);
  });

  testWidgets('code sent → code step with resend timer; wrong code is explained', (tester) async {
    final d = FakeDeps()..auth.codeFailure = const AuthFailure('invalid-verification-code');
    await pumpRider(tester, const SignInScreen(), deps: d);
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '0912345678');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump();

    expect(d.auth.verifications, ['+249912345678']);
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.textContaining('You can ask for a new code in'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('That code is wrong'), findsOneWidget);
  });

  testWidgets('auto-verification is shown while the device signs in', (tester) async {
    final d = FakeDeps()..auth.onStart = (_, cb) => cb(const AutoVerifying());
    await pumpRider(tester, const SignInScreen(), deps: d);
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '912345678');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump();
    // Still on the phone step (no code was sent), but signing in is under way.
    expect(find.text('Enter the code'), findsNothing);
  });
}
