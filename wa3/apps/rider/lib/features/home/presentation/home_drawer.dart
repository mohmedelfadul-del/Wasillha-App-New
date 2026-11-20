import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../history/presentation/history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    void open(Widget screen) {
      Navigator.of(context)
        ..pop()
        ..push(MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      child: SafeArea(
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(WSpace.lg),
            child: Text(s.t('وصلها', 'Wasilha'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          ListTile(leading: const Icon(Icons.history), title: Text(s.t('رحلاتي', 'My trips')), onTap: () => open(const HistoryScreen())),
          ListTile(leading: const Icon(Icons.person_outline), title: Text(s.t('الملف الشخصي', 'Profile')), onTap: () => open(const ProfileScreen())),
          ListTile(leading: const Icon(Icons.settings_outlined), title: Text(s.t('الإعدادات', 'Settings')), onTap: () => open(const SettingsScreen())),
        ]),
      ),
    );
  }
}
