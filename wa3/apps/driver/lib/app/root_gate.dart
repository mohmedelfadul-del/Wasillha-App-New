import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/account/domain/driver_repository.dart';
import '../features/auth/presentation/name_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import 'home_shell.dart';
import 'live.dart';
import 'services.dart';

/// Signed out → sign-in · no driver doc → name · otherwise the home shell.
class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late final Stream<String?> _uid = context.services.auth.uidChanges();

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
        stream: _uid,
        initialData: context.services.auth.currentUid,
        builder: (context, snap) {
          final uid = snap.data;
          if (uid == null) return const SignInScreen();
          return _DriverGate(key: ValueKey(uid), uid: uid);
        },
      );
}

class _DriverGate extends StatefulWidget {
  const _DriverGate({super.key, required this.uid});
  final String uid;
  @override
  State<_DriverGate> createState() => _DriverGateState();
}

class _DriverGateState extends State<_DriverGate> {
  late Stream<Live<DriverState?>> _driver = context.services.driver.watchDriver(widget.uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<Live<DriverState?>>(
        stream: _driver,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(body: WStateView.error(context, snap.error!, onRetry: () => setState(() => _driver = context.services.driver.watchDriver(widget.uid))));
          }
          if (!snap.hasData) return Scaffold(body: WStateView.loading());
          final live = snap.data!;
          final d = live.data;
          // A cached "missing" doc may just mean we haven't reached the server yet.
          if (d == null && live.fromCache) return Scaffold(body: WStateView.loading());
          if (d == null) return const NameScreen();
          return HomeShell(live: Live(d, fromCache: live.fromCache));
        },
      );
}
