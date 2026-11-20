import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../features/auth/application/session_controller.dart';
import 'routes.dart';
import 'sections.dart';
import 'settings.dart';
import 'widgets/access_denied.dart';
import 'widgets/settings_actions.dart';

/// Responsive frame: navigation rail on wide screens, drawer on narrow ones.
/// Shows only the sections the role can use, and the access-denied state
/// when the route itself is not allowed for the role.
class OpsShell extends StatelessWidget {
  const OpsShell({super.key, required this.section, required this.child, this.detail = false, this.allowed});
  final Section section;
  final Widget child;

  /// Detail pages show a back button instead of the drawer on narrow screens.
  final bool detail;

  /// Overrides the section's roles for this page (admin is always allowed).
  final Set<StaffRole>? allowed;

  static const wideBreakpoint = 900.0;

  bool _permits(StaffRole? role) => role == StaffRole.admin || (role != null && (allowed ?? section.roles).contains(role));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final role = context.role;
    final visible = Section.visibleFor(role);
    final idx = visible.indexOf(section);
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final body = _permits(role) ? child : SectionAccessDenied(section: section, role: role);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !detail || !canPop,
        leading: detail && canPop ? const BackButton() : null,
        title: Text(section.label(s), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [if (wide) const SettingsActions(), const _AccountMenu()],
      ),
      drawer: wide || (detail && canPop)
          ? null
          : NavigationDrawer(
              selectedIndex: idx < 0 ? null : idx,
              onDestinationSelected: (i) {
                Navigator.of(context).pop();
                openSection(context, visible[i]);
              },
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(28, 16, 16, 10),
                  child: Text(s.t('وصلها · التشغيل', 'Wasilha · Operations'), style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final v in visible) NavigationDrawerDestination(icon: Icon(v.icon), label: Text(v.label(s))),
              ],
            ),
      body: SafeArea(
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                NavigationRail(
                  scrollable: true,
                  extended: MediaQuery.sizeOf(context).width >= 1200,
                  labelType: MediaQuery.sizeOf(context).width >= 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  selectedIndex: idx < 0 ? null : idx,
                  onDestinationSelected: (i) => openSection(context, visible[i]),
                  destinations: [for (final v in visible) NavigationRailDestination(icon: Icon(v.icon), label: Text(v.label(s)))],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ])
            : body,
      ),
    );
  }
}

/// Signed-in identity, language/theme on narrow screens, and sign-out.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final session = context.session;
    final settings = SettingsScope.of(context);
    return PopupMenuButton<String>(
      tooltip: s.t('الحساب', 'Account'),
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) {
        switch (v) {
          case 'lang':
            settings.toggleLang();
          case 'light':
            settings.setTheme(ThemeMode.light);
          case 'dark':
            settings.setTheme(ThemeMode.dark);
          case 'system':
            settings.setTheme(ThemeMode.system);
          case 'signout':
            SessionScope.of(context).onSignOut();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ltr(session.email ?? session.uid)),
            if (session.role != null) Text(roleLabel(s, session.role!), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'lang', child: Text(s.ar ? 'English' : 'العربية')),
        PopupMenuItem(value: 'system', child: Text(s.t('المظهر: حسب النظام', 'Theme: system'))),
        PopupMenuItem(value: 'light', child: Text(s.t('المظهر: فاتح', 'Theme: light'))),
        PopupMenuItem(value: 'dark', child: Text(s.t('المظهر: داكن', 'Theme: dark'))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'signout', child: Text(s.t('تسجيل الخروج', 'Sign out'))),
      ],
    );
  }
}
