import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/auth/presentation/sign_in_screen.dart';
import '../features/common/domain/live.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import 'deps.dart';

/// Signed out → sign in. Signed in → profile check → home.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.deps.auth;
    return StreamBuilder<String?>(
      stream: auth.uidChanges(),
      initialData: auth.uid,
      builder: (context, snap) {
        final uid = snap.data;
        if (uid == null) return const SignInScreen();
        return ProfileGate(key: ValueKey(uid));
      },
    );
  }
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Stream<Live<RiderProfile?>> _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream = context.deps.profile.watch();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Live<RiderProfile?>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(body: WStateView.error(context, snap.error!, onRetry: () => setState(() => _stream = context.deps.profile.watch())));
          }
          final live = snap.data;
          // A missing document from the cache isn't proof the rider has no profile.
          if (live == null || (live.value == null && live.fromCache)) {
            return Scaffold(body: WStateView.loading(label: context.s.loading));
          }
          if (live.value == null) return const ProfileSetupScreen();
          return const HomeScreen();
        },
      );
}
