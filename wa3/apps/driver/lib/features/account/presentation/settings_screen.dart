import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final st = context.services.settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('الإعدادات', 'Settings'))),
      body: ListenableBuilder(
        listenable: st,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
          Text(s.t('اللغة', 'Language'), style: Theme.of(context).textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: st.lang,
            onChanged: (v) => st.setLang(v!),
            child: const Column(children: [
              RadioListTile<String>(value: 'ar', title: Text('العربية')),
              RadioListTile<String>(value: 'en', title: Text('English')),
            ]),
          ),
          const Divider(height: WSpace.xl),
          Text(s.t('المظهر', 'Theme'), style: Theme.of(context).textTheme.titleMedium),
          RadioGroup<ThemeMode>(
            groupValue: st.theme,
            onChanged: (v) => st.setTheme(v!),
            child: Column(children: [
              RadioListTile<ThemeMode>(value: ThemeMode.system, title: Text(s.t('حسب الهاتف', 'Same as phone'))),
              RadioListTile<ThemeMode>(value: ThemeMode.light, title: Text(s.t('فاتح', 'Light'))),
              RadioListTile<ThemeMode>(value: ThemeMode.dark, title: Text(s.t('داكن', 'Dark'))),
            ]),
          ),
        ]),
      ),
    );
  }
}
