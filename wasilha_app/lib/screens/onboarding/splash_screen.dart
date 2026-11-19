import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../theme/tokens.dart';
import 'auth_common.dart';

/// 01 — Splash: logo fade-up, ambient accent glow, pulsing dots.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), _next);
  }

  Future<void> _next() async {
    if (!mounted) return;
    final backend = context.read<WasilhaBackend>();
    final s = context.read<AppState>();
    if (backend.uid != null) {
      String route = 'role';
      try {
        route = routeForProfile(await firstProfile(backend));
      } catch (_) {
        // Fall back to role selection if the profile can't be read.
      }
      if (!mounted) return;
      context.root(route);
    } else if (s.onboarded) {
      context.root('login');
    } else {
      context.swap('onboarding');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final size = MediaQuery.sizeOf(context);
    final fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: W.screenBg,
      body: Stack(children: [
        // ambient glow, centred at 40% height
        Positioned(
          left: size.width / 2 - 210,
          top: size.height * 0.4 - 210,
          child: PulseSoft(
            period: const Duration(seconds: 4),
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0)],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
        ),
        // logo + tagline
        Center(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(fade),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DecoratedBox(
                  decoration: const BoxDecoration(boxShadow: [
                    BoxShadow(color: Color(0x0F1E2A4E), blurRadius: 40, offset: Offset(0, 8)),
                  ]),
                  child: Image.asset('assets/wasilha-logo.png', width: 220, fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    s.t('MOBILITY FOR SUDAN', 'التنقّل للسودان'),
                    style: s.ar
                        ? W.ar(size: 12, color: W.text2)
                        : W.mono(size: 10, color: W.text2, letterSpacing: 0.5),
                  ),
                ),
              ]),
            ),
          ),
        ),
        // corner editorial marks
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('EST · 2026 · KRT', style: W.mono(size: 9, letterSpacing: 0.24)),
              Text('v 1.0', style: W.mono(size: 9, letterSpacing: 0.24)),
            ]),
          ),
        ),
        // loading dots
        Positioned(
          left: 0,
          right: 0,
          bottom: 70,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: PulseSoft(
                    delay: Duration(milliseconds: i * 200),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.4), shape: BoxShape.circle),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Text(
              s.t('CONNECTING SUDAN', 'مرحبا بالسودان'),
              style: s.ar ? W.ar(size: 11, color: W.text3) : W.mono(size: 9, color: W.text3, letterSpacing: 0.3),
            ),
          ]),
        ),
      ]),
    );
  }
}
