import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Switch between driver tabs. Drive is the root; the other tabs sit on top
/// of it so the system back button returns to Drive.
void driverTab(BuildContext context, String id) {
  if (id == 'driverHome') {
    context.root('driverHome');
  } else {
    Navigator.of(context).pushNamedAndRemoveUntil(id, (r) => r.settings.name == 'driverHome');
  }
}

/// Back from a driver sub-screen: pop when possible, otherwise go to Drive.
void driverBack(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    context.root('driverHome');
  }
}

/// Driver bottom nav (screens-roles.jsx → DriverNav). A `Positioned`: put it
/// as the last child of a full-screen Stack.
class DriverNav extends StatelessWidget {
  const DriverNav({super.key, required this.active});

  /// driverHome | driverRequests | driverEarnings | settings
  final String active;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = [
      ('driverHome', s.t('Drive', 'القيادة'), 'car'),
      ('driverRequests', s.t('Requests', 'الطلبات'), 'bell'),
      ('driverEarnings', s.t('Earnings', 'الأرباح'), 'wallet'),
      ('settings', s.t('Account', 'حسابي'), 'user'),
    ];
    return Positioned(
      left: 12,
      right: 12,
      bottom: 22 + MediaQuery.paddingOf(context).bottom * 0.4,
      child: Center(
        child: Glass(
          padding: const EdgeInsets.all(8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (id, label, icon) in items)
              GestureDetector(
                onTap: id == active ? null : () => driverTab(context, id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 44,
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active == id ? W.text : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    WIcon(icon, size: 18, strokeWidth: 1.7, color: active == id ? Colors.white : W.text),
                    if (active == id) ...[
                      const SizedBox(width: 8),
                      Text(label, style: W.sans(size: 13, weight: FontWeight.w500, color: Colors.white)),
                    ],
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
