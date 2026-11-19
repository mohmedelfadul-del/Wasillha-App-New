import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Hero gradients per restaurant (cycled).
const foodHeroGradients = [
  [Color(0xFFB86E4B), Color(0xFF8C4B30), Color(0xFF5A2E1E)],
  [Color(0xFF8A7A3E), Color(0xFF63562A), Color(0xFF3A3218)],
  [Color(0xFF5E6E7E), Color(0xFF3F4C5A), Color(0xFF242C36)],
];

/// Dish thumbnail tones (cycled).
const foodDishTones = [Color(0xFFE8DAB6), Color(0xFFC8B89C), Color(0xFFB86E4B), Color(0xFFD7B889), Color(0xFFCFA98A), Color(0xFFBFC29A)];

/// Subtle dotted "grain" over the hero gradient.
class FoodGrain extends StatelessWidget {
  const FoodGrain({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(child: CustomPaint(painter: _GrainPainter(), size: Size.infinite));
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x26FBFAF6);
    for (double y = 0; y <= size.height + 40; y += 40) {
      for (double x = 0; x <= size.width + 40; x += 40) {
        canvas.drawCircle(Offset(x + 20, y + 20), 0.8, p);
        canvas.drawCircle(Offset(x, y), 0.6, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Square-ish striped dish placeholder.
class FoodDishThumb extends StatelessWidget {
  const FoodDishThumb({super.key, required this.tone, this.size = 72});
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [tone, tone.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _StripePainter())),
        PositionedDirectional(
          start: 8,
          bottom: 6,
          child: Text('DISH', style: W.mono(size: 8, color: const Color(0x66000000), letterSpacing: 0.12)),
        ),
      ]),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 8;
    for (double d = -size.height; d < size.width + size.height; d += 22) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Quantity stepper / add button on a menu row.
class FoodQty extends StatelessWidget {
  const FoodQty({super.key, required this.qty, required this.onInc, required this.onDec});
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return GestureDetector(
        onTap: onInc,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: W.border, width: 0.5),
          ),
          child: const WIcon('plus', size: 16, strokeWidth: 1.8),
        ),
      );
    }
    Widget b(String icon, VoidCallback f) => GestureDetector(
          onTap: f,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(width: 26, height: 26, child: Center(child: WIcon(icon, size: 14, strokeWidth: 1.8, color: Colors.white))),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b('minus', onDec),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 14),
          child: Text('$qty', textAlign: TextAlign.center, style: W.mono(size: 12, color: Colors.white, letterSpacing: 0)),
        ),
        const SizedBox(width: 4),
        b('plus', onInc),
      ]),
    );
  }
}

/// Floating cart bar; slides/fades in on mount (CSS `ws-cart-in`).
class FoodCartBar extends StatefulWidget {
  const FoodCartBar({super.key, required this.count, required this.total, required this.onTap, this.loading = false});
  final int count;
  final int total;
  final VoidCallback onTap;
  final bool loading;

  @override
  State<FoodCartBar> createState() => _FoodCartBarState();
}

class _FoodCartBarState extends State<FoodCartBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: const Cubic(0.2, 0.85, 0.2, 1));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 20 * (1 - _a.value)), child: child),
      ),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 14, 0),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.33), blurRadius: 30, offset: const Offset(0, 14))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x2E000000), borderRadius: BorderRadius.circular(10)),
              child: Text(
                s.t('${widget.count} ITEMS', '${widget.count} صنف'),
                style: s.ar ? W.ar(size: 11, color: Colors.white) : W.mono(size: 11, color: Colors.white, letterSpacing: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.t('View basket', 'عرض السلة'),
                  overflow: TextOverflow.ellipsis, style: W.sans(size: 14.5, color: Colors.white)),
            ),
            if (widget.loading)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              Text(sdg(widget.total), style: W.serif(size: 22, color: Colors.white)),
            const SizedBox(width: 12),
            const WIcon('arrow', size: 16, strokeWidth: 1.9, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

/// Mono label + serif value tile used in the restaurant stats strip.
class FoodStat extends StatelessWidget {
  const FoodStat({super.key, required this.label, required this.value, required this.sub, this.first = false});
  final String label;
  final String value;
  final String sub;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsetsDirectional.only(start: first ? 0 : 14),
        decoration: BoxDecoration(
          border: first ? null : const BorderDirectional(start: BorderSide(color: W.border, width: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MonoLabel(label, size: 9),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: W.serif(size: 22)),
            const SizedBox(width: 4),
            Flexible(child: Text(sub, overflow: TextOverflow.ellipsis, style: W.sans(size: 10.5, color: W.text3))),
          ]),
        ]),
      ),
    );
  }
}
