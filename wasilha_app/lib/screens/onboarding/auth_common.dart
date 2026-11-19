import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/backend.dart';
import '../../data/models.dart';

/// Route id for a signed-in user's profile: 'role' when the profile is
/// incomplete, otherwise the role's home screen.
String routeForProfile(UserProfile? p) {
  if (p == null || p.name.trim().isEmpty) return 'role';
  return routeForRole(p.role);
}

String routeForRole(UserRole r) => switch (r) {
      UserRole.rider => 'home',
      UserRole.driver => 'driverHome',
      UserRole.store => 'store',
    };

/// Reads the first value of the profile stream (with a timeout).
Future<UserProfile?> firstProfile(WasilhaBackend backend) =>
    backend.profile().first.timeout(const Duration(seconds: 10));

/// CSS `pulse-soft`: opacity 1 → 0.55 → 1, looping, with an optional delay.
class PulseSoft extends StatefulWidget {
  const PulseSoft({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.minOpacity = 0.55,
  });

  final Widget child;
  final Duration period;
  final Duration delay;
  final double minOpacity;

  @override
  State<PulseSoft> createState() => _PulseSoftState();
}

class _PulseSoftState extends State<PulseSoft> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.repeat();
    } else {
      _t = Timer(widget.delay, () {
        if (mounted) _c.repeat();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // triangle wave 0→1→0, eased
        final v = _c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2;
        final e = Curves.easeInOut.transform(v);
        return Opacity(opacity: 1 - (1 - widget.minOpacity) * e, child: child);
      },
      child: widget.child,
    );
  }
}

/// Small square back button used on the auth screens (radius 12).
class AuthBackBtn extends StatelessWidget {
  const AuthBackBtn({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: child,
      ),
    );
  }
}
