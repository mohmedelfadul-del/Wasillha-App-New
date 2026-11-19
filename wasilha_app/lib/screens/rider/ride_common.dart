import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/w_icon.dart';

/// Shared bits for the rider ride flow (search → booking → offer →
/// tracking → complete).

/// City-average trip duration (~27 km/h), same rule as [Trip.etaMin].
int rideMinutes(double km) => (km / 0.45).round().clamp(3, 120);

/// Per-service duration: motorcycles cut through traffic, rakshas are slower.
int serviceMinutes(ServiceType svc, double km) {
  final f = switch (svc) {
    ServiceType.moto => 0.85,
    ServiceType.raksha => 1.15,
    _ => 1.0,
  };
  return (rideMinutes(km) * f).round().clamp(2, 140);
}

String kmText(double km) => km < 10 ? km.toStringAsFixed(1) : km.round().toString();

/// "3.2 km · 12 min" / "٣٫٢ كم · ١٢ دقيقة" (Latin digits kept for clarity).
String distanceDetail(AppState s, double km) =>
    s.t('${kmText(km)} km · ${rideMinutes(km)} min', '${kmText(km)} كم · ${rideMinutes(km)} دقيقة');

/// Rounded to the nearest 50 SDG.
int round50(num v) => ((v / 50).round() * 50);

/// Deterministic avatar tone for a name / id.
String toneFor(String key) {
  const tones = ['warm', 'olive', 'cool', 'purple'];
  return tones[key.hashCode.abs() % tones.length];
}

String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final s = parts.take(2).map((p) => p[0]).join().toUpperCase();
  return s.isEmpty ? 'W' : s;
}

/// Grab handle at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 38,
          height: 4,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

/// 40×40 rounded-square white back button used on map screens.
class SquareIconBtn extends StatelessWidget {
  const SquareIconBtn({super.key, required this.icon, required this.onTap, this.size = 40, this.bordered = false});
  final String icon;
  final VoidCallback onTap;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: bordered ? Border.all(color: W.border, width: 0.5) : null,
            boxShadow: const [BoxShadow(color: Color(0x1A140F1E), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: WIcon(icon, size: size * 0.44, strokeWidth: 1.7, color: W.text),
        ),
      );
}

/// Bottom sheet surface used by booking / tracking.
class RideSheet extends StatelessWidget {
  const RideSheet({super.key, required this.child, this.maxHeightFactor = 0.66, this.bottomPad = 30});
  final Widget child;
  final double maxHeightFactor;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * maxHeightFactor),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: W.screenBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Color(0x1A140F1E), blurRadius: 32, offset: Offset(0, -10))],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + mq.padding.bottom * 0.5),
          child: child,
        ),
      ),
    );
  }
}

/// Slide-up entry used for sheets (CSS `sheet-in`).
class SheetIn extends StatelessWidget {
  const SheetIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        builder: (_, v, c) => FractionalTranslation(translation: Offset(0, v * 0.35), child: c),
        child: child,
      );
}

void comingSoon(BuildContext context, AppState s, String what) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(s.t('$what — coming soon', '$what — قريبًا')),
    behavior: SnackBarBehavior.floating,
    backgroundColor: W.text,
  ));
}
