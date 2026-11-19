import 'package:flutter/material.dart';

import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';

// ── Data helpers shared by the driver screens ───────────────

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Completed trips (newest first) from `driverTrips()`.
List<Trip> completedTrips(List<Trip> all) =>
    all.where((t) => t.status == TripStatus.completed).toList();

/// Driver's take for a trip: agreed fare plus tip.
int tripEarning(Trip t) => t.fare + t.tip;

int sumEarnings(Iterable<Trip> trips) =>
    trips.fold(0, (s, t) => s + tripEarning(t));

List<Trip> tripsToday(List<Trip> all) {
  final now = DateTime.now();
  return completedTrips(all).where((t) => sameDay(t.createdAt, now)).toList();
}

/// Minutes for the driver to reach a pickup (assumes the driver is around
/// the city centre default pickup — the app does not track driver GPS yet).
int pickupEtaMin(Trip t) =>
    (t.pickup.kmTo(Catalog.defaultPickup) / 0.45).round().clamp(2, 20);

/// Two-letter initials for a rider name.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final s = parts.take(2).map((p) => p[0]).join().toUpperCase();
  return s.isEmpty ? 'R' : s;
}

String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String mmss(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ── Small visual pieces ─────────────────────────────────────

/// Radial accent glow placed in a corner of dark cards.
class AccentGlow extends StatelessWidget {
  const AccentGlow({
    super.key,
    required this.color,
    this.size = 160,
    this.top = -40,
    this.end = -30,
    this.alpha = 0.33,
  });
  final Color color;
  final double size;
  final double top;
  final double end;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: top,
      end: end,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.65],
            ),
          ),
        ),
      ),
    );
  }
}

/// Looping opacity pulse (CSS `pulse-soft`).
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    required this.color,
    this.size = 8,
    this.ring = true,
    this.animate = true,
  });
  final Color color;
  final double size;
  final bool ring;
  final bool animate;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.55).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: widget.ring
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Green-dot → line → accent-square route marker.
class RouteDots extends StatelessWidget {
  const RouteDots({
    super.key,
    required this.accent,
    this.dark = false,
    this.gap = 22,
    this.dot = 9,
    this.from = W.success,
  });
  final Color accent;
  final bool dark;
  final double gap;
  final double dot;
  final Color from;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(color: from, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Container(
          width: 1.5,
          height: gap,
          color: dark ? const Color(0x2EFFFFFF) : W.border2,
        ),
        const SizedBox(height: 4),
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(dot > 7 ? 2 : 1),
          ),
        ),
      ],
    );
  }
}

/// iOS-style switch from the design (green when on).
class DriverSwitch extends StatelessWidget {
  const DriverSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.width = 50,
    this.height = 28,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final knob = height - 6;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: 'Online',
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? W.success : const Color(0xFFD6D2C9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: knob,
              height: knob,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 40–44px rounded-square header button used on driver / store screens.
class SquareBtn extends StatelessWidget {
  const SquareBtn({
    super.key,
    required this.child,
    this.onTap,
    this.size = 40,
    this.color = Colors.white,
    this.shadow = true,
    this.border,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final bool shadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
          border: border,
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x1A140F1E),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Small loading spinner.
class MiniSpinner extends StatelessWidget {
  const MiniSpinner({super.key, this.color = W.text3, this.size = 18});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

void comingSoon(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: W.text,
    ),
  );
}
