import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/domain/live.dart';
import '../../common/presentation/cache_banner.dart';
import '../domain/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Stream<Live<RiderProfile?>> _stream = context.deps.profile.watch();

  Future<void> _signOut() async {
    final s = context.s;
    final ok = await confirmAction(context,
        title: s.t('تسجيل الخروج؟', 'Sign out?'),
        body: s.t('ستحتاج إلى رمز جديد للدخول مرة أخرى.', 'You’ll need a new code to sign in again.'),
        confirmLabel: s.t('خروج', 'Sign out'),
        destructive: true);
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    await context.deps.auth.signOut();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('الملف الشخصي', 'Profile'))),
      body: StreamBuilder<Live<RiderProfile?>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return WStateView.error(context, snap.error!, onRetry: () => setState(() => _stream = context.deps.profile.watch()));
          final live = snap.data;
          if (live == null) return WStateView.loading();
          final p = live.value;
          return ListView(children: [
            CacheBanner(fromCache: live.fromCache),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(s.t('الاسم', 'Name')),
              subtitle: Text(p?.name ?? '—'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(s.t('الهاتف', 'Phone')),
              subtitle: Text(ltr((p?.phone.isNotEmpty ?? false) ? p!.phone : (context.deps.auth.phoneNumber ?? '—'))),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(WSpace.lg),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: Text(s.t('تسجيل الخروج', 'Sign out')),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
