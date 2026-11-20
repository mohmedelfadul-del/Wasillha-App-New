import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.deps.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = context.s;
        final theme = Theme.of(context);
        Widget header(String t) => Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(WSpace.lg, WSpace.lg, WSpace.lg, WSpace.xs),
              child: Text(t, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            );
        return Scaffold(
          appBar: AppBar(title: Text(s.t('الإعدادات', 'Settings'))),
          body: ListView(children: [
            header(s.t('اللغة', 'Language')),
            RadioGroup<String>(
              groupValue: settings.lang,
              onChanged: (v) => settings.setLang(v!),
              child: const Column(children: [
                RadioListTile<String>(value: 'ar', title: Text('العربية')),
                RadioListTile<String>(value: 'en', title: Text('English')),
              ]),
            ),
            header(s.t('المظهر', 'Theme')),
            RadioGroup<ThemeMode>(
              groupValue: settings.theme,
              onChanged: (v) => settings.setTheme(v!),
              child: Column(children: [
                RadioListTile<ThemeMode>(value: ThemeMode.system, title: Text(s.t('حسب الجهاز', 'Match device'))),
                RadioListTile<ThemeMode>(value: ThemeMode.light, title: Text(s.t('فاتح', 'Light'))),
                RadioListTile<ThemeMode>(value: ThemeMode.dark, title: Text(s.t('داكن', 'Dark'))),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
