import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../vehicles/presentation/vehicles_screen.dart';
import '../domain/driver_repository.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.driver});
  final DriverState driver;

  Future<void> _signOut(BuildContext context) async {
    final s = context.s;
    final ok = await confirmAction(
      context,
      title: s.t('تسجيل الخروج؟', 'Sign out?'),
      body: s.t('سنقطع اتصالك بالعمل أولاً ولن تصلك طلبات.', 'We’ll take you offline first and you won’t get requests.'),
      confirmLabel: s.t('خروج', 'Sign out'),
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final svc = context.services;
    try {
      if (driver.profile.online) await svc.driver.goOffline();
    } on ApiFailure catch (e) {
      if (context.mounted) showFailure(context, e);
      return;
    }
    svc.location.stop();
    await svc.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = driver.profile;
    void push(Widget w) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => w));
    ListTile item(IconData icon, String title, VoidCallback onTap, {String? subtitle}) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          minVerticalPadding: WSpace.md,
          onTap: onTap,
        );
    return Scaffold(
      appBar: AppBar(title: Text(p.name.isEmpty ? s.t('حسابي', 'Account') : p.name)),
      body: ListView(children: [
        item(Icons.person_outline, s.t('ملفي وتقييمي', 'Profile and rating'), () => push(ProfileScreen(driver: driver))),
        item(Icons.badge_outlined, s.t('وثائقي', 'My documents'), () => push(DocumentsScreen(uid: p.uid, status: p.status))),
        item(Icons.directions_car_outlined, s.t('مركباتي', 'My vehicles'), () => push(VehiclesScreen(uid: p.uid))),
        item(Icons.history, s.t('رحلاتي', 'My trips'), () => push(HistoryScreen(uid: p.uid))),
        item(Icons.notifications_none, s.t('الإشعارات', 'Notifications'), () => push(NotificationsScreen(uid: p.uid))),
        item(Icons.support_agent, s.t('الدعم', 'Support'), () => push(const SupportScreen())),
        item(Icons.settings_outlined, s.t('الإعدادات', 'Settings'), () => push(const SettingsScreen())),
        const Divider(),
        if (driver.hasTrip)
          Padding(
            padding: const EdgeInsets.all(WSpace.lg),
            child: Text(s.t('أنهِ رحلتك الحالية قبل تسجيل الخروج.', 'Finish your current trip before signing out.')),
          )
        else
          ListTile(
            leading: const Icon(Icons.logout, color: WColors.error),
            title: Text(s.t('تسجيل الخروج', 'Sign out'), style: const TextStyle(color: WColors.error)),
            onTap: () => _signOut(context),
          ),
      ]),
    );
  }
}
