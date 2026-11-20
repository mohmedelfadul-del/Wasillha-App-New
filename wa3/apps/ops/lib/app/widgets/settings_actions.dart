import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../settings.dart';

/// Language toggle and theme menu, for app bars.
class SettingsActions extends StatelessWidget {
  const SettingsActions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = SettingsScope.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (MediaQuery.sizeOf(context).width < 600)
        IconButton(onPressed: settings.toggleLang, tooltip: s.ar ? 'English' : 'العربية', icon: const Icon(Icons.translate))
      else
        TextButton(
          onPressed: settings.toggleLang,
          child: Text(s.ar ? 'English' : 'العربية', semanticsLabel: s.t('التبديل إلى الإنجليزية', 'Switch to Arabic')),
        ),
      PopupMenuButton<ThemeMode>(
        tooltip: s.t('المظهر', 'Theme'),
        icon: const Icon(Icons.brightness_6_outlined),
        initialValue: settings.themeMode,
        onSelected: settings.setTheme,
        itemBuilder: (_) => [
          PopupMenuItem(value: ThemeMode.system, child: Text(s.t('حسب النظام', 'System'))),
          PopupMenuItem(value: ThemeMode.light, child: Text(s.t('فاتح', 'Light'))),
          PopupMenuItem(value: ThemeMode.dark, child: Text(s.t('داكن', 'Dark'))),
        ],
      ),
    ]);
  }
}
