import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/widgets/access_denied.dart';
import '../../../app/widgets/failure.dart';
import '../application/session_controller.dart';
import '../domain/auth_repository.dart';
import 'enroll_screen.dart';
import 'sign_in_screen.dart';

/// Shows sign-in, TOTP enrollment or access denied until the session is an
/// authorized staff member with a TOTP-verified token; then [child].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.controller, required this.child, this.mfaOptional = false});
  final SessionController controller;
  final Widget child;
  final bool mfaOptional;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.loaded) return _page(const Scaffold(body: _Loading()), 'loading');
        if (controller.error != null && controller.session == null) {
          return _page(Scaffold(body: opsErrorView(context, controller.error!)), 'error');
        }
        final session = controller.session;
        final state = gateFor(session, mfaOptional: mfaOptional);
        return switch (state) {
          GateState.signedOut => _page(SignInScreen(repo: controller.repo), 'signin'),
          GateState.accessDenied => _page(AccessDeniedScreen(session: session!, onSignOut: controller.signOut), 'denied'),
          GateState.enrollTotp => _page(EnrollTotpScreen(repo: controller.repo, onSignOut: controller.signOut), 'enroll'),
          GateState.reauthWithTotp => _page(ReauthScreen(onSignOut: controller.signOut), 'reauth'),
          GateState.ready => SessionScope(session: session!, onSignOut: controller.signOut, child: child),
        };
      },
    );
  }

  /// Gives pre-console screens their own Navigator/Overlay (text fields, dialogs).
  Widget _page(Widget screen, String key) => Navigator(
        key: ValueKey('gate-$key'),
        pages: [MaterialPage<void>(key: ValueKey(key), child: screen)],
        onDidRemovePage: (_) {},
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => WStateView.loading(label: context.s.loading);
}
