import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme/tokens.dart';
import 'w_icon.dart';

/// Wasilha card palette (split-cards.jsx → WASILHA).
class WCardColors {
  WCardColors._();
  static const purple = Color(0xFF9D00FF);
  static const lavender = Color(0xFFDBD4FF);
  static const ivory = Color(0xFFFFFFE3);
  static const deepPurple = Color(0xFF723480);
}

const _morphCurve = Cubic(0.22, 0.85, 0.22, 1);
const _softCurve = Cubic(0.2, 0.8, 0.2, 1);
const _morphDuration = Duration(milliseconds: 520);
const _fadeDuration = Duration(milliseconds: 360);

// ─────────────────────────────────────────────────────────────
// Pair geometries (connected-pairs.jsx → PAIR_GEOM). Coordinates are in
// percent of the card box; every state of a geometry has the same vertex
// count so the shared edge can be morphed by lerping vertices.
// ─────────────────────────────────────────────────────────────

enum PairGeom { diagonal, trapezoid, chevron, hexZig }

enum _PairState { rest, aActive, bActive }

class _Shape {
  const _Shape(this.a, this.b, this.sep);
  final List<Offset> a;
  final List<Offset> b;
  final List<Offset> sep;

  static _Shape lerp(_Shape x, _Shape y, double t) => _Shape(
        _lerpList(x.a, y.a, t),
        _lerpList(x.b, y.b, t),
        _lerpList(x.sep, y.sep, t),
      );

  static List<Offset> _lerpList(List<Offset> x, List<Offset> y, double t) =>
      [for (var i = 0; i < x.length; i++) Offset.lerp(x[i], y[i], t)!];
}

_Shape _diagonal(double top, double bot) => _Shape(
      [const Offset(0, 0), Offset(top, 0), Offset(bot, 100), const Offset(0, 100)],
      [Offset(top, 0), const Offset(100, 0), const Offset(100, 100), Offset(bot, 100)],
      [Offset(top, 0), Offset(bot, 100)],
    );

_Shape _trapezoid(double rightY, double leftY) => _Shape(
      [const Offset(0, 0), const Offset(100, 0), Offset(100, rightY), Offset(0, leftY)],
      [Offset(0, leftY), Offset(100, rightY), const Offset(100, 100), const Offset(0, 100)],
      [Offset(0, leftY), Offset(100, rightY)],
    );

_Shape _chevron(double y) => _Shape(
      [const Offset(0, 0), const Offset(100, 0), Offset(100, y), Offset(50, y + 16), Offset(0, y)],
      [Offset(0, y), Offset(50, y + 16), Offset(100, y), const Offset(100, 100), const Offset(0, 100)],
      [Offset(0, y), Offset(50, y + 16), Offset(100, y)],
    );

_Shape _hexZig(double n, double f) => _Shape(
      [
        const Offset(0, 0), Offset(n, 0), Offset(f, 28), Offset(n, 50), //
        Offset(f, 72), Offset(n, 100), const Offset(0, 100),
      ],
      [
        Offset(n, 0), const Offset(100, 0), const Offset(100, 100), Offset(n, 100), //
        Offset(f, 72), Offset(n, 50), Offset(f, 28),
      ],
      [Offset(n, 0), Offset(f, 28), Offset(n, 50), Offset(f, 72), Offset(n, 100)],
    );

_Shape _shapeFor(PairGeom g, _PairState s) {
  switch (g) {
    case PairGeom.diagonal:
      return switch (s) {
        _PairState.rest => _diagonal(54, 46),
        _PairState.aActive => _diagonal(72, 62),
        _PairState.bActive => _diagonal(38, 28),
      };
    case PairGeom.trapezoid:
      return switch (s) {
        _PairState.rest => _trapezoid(42, 60),
        _PairState.aActive => _trapezoid(60, 76),
        _PairState.bActive => _trapezoid(22, 38),
      };
    case PairGeom.chevron:
      return switch (s) {
        _PairState.rest => _chevron(48),
        _PairState.aActive => _chevron(64),
        _PairState.bActive => _chevron(32),
      };
    case PairGeom.hexZig:
      return switch (s) {
        _PairState.rest => _hexZig(52, 46),
        _PairState.aActive => _hexZig(70, 64),
        _PairState.bActive => _hexZig(34, 28),
      };
  }
}

Path _polyPath(List<Offset> pts, Size size, bool mirror) {
  final path = Path();
  for (var i = 0; i < pts.length; i++) {
    final x = (mirror ? 100 - pts[i].dx : pts[i].dx) / 100 * size.width;
    final y = pts[i].dy / 100 * size.height;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path;
}

class _PolyClipper extends CustomClipper<Path> {
  _PolyClipper(this.points, this.mirror);
  final List<Offset> points;
  final bool mirror;

  @override
  Path getClip(Size size) => _polyPath(points, size, mirror)..close();

  @override
  bool shouldReclip(_PolyClipper old) => old.points != points || old.mirror != mirror;
}

class _SepPainter extends CustomPainter {
  _SepPainter(this.points, this.mirror);
  final List<Offset> points;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _polyPath(points, size, mirror),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xEBFFFFFF)
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SepPainter old) => old.points != points || old.mirror != mirror;
}

/// One half of a [ConnectedPair].
class PairSide {
  const PairSide({
    this.color,
    this.gradient,
    required this.ink,
    this.glow = WCardColors.purple,
    required this.label,
    required this.content,
    this.onTap,
  });

  final Color? color;
  final Gradient? gradient;
  final Color ink;
  final Color glow;
  final String label;
  final Widget content;
  final VoidCallback? onTap;
}

/// Two real, independently tappable cards joined by a morphable shared edge
/// (connected-pairs.jsx → ConnectedPair). Pressing one side grows it and
/// shrinks the other; the hairline separator follows.
class ConnectedPair extends StatefulWidget {
  const ConnectedPair({
    super.key,
    this.geom = PairGeom.diagonal,
    this.height = 170,
    this.radius = 28,
    required this.a,
    required this.b,
  });

  final PairGeom geom;
  final double height;
  final double radius;
  final PairSide a;
  final PairSide b;

  @override
  State<ConnectedPair> createState() => _ConnectedPairState();
}

class _ConnectedPairState extends State<ConnectedPair> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _morphDuration);
  late _Shape _from = _shapeFor(widget.geom, _PairState.rest);
  late _Shape _to = _from;
  _PairState _state = _PairState.rest;
  Timer? _reset;

  _Shape get _current => _Shape.lerp(_from, _to, _morphCurve.transform(_c.value));

  void _setState(_PairState s) {
    if (s == _state) return;
    _from = _current;
    _to = _shapeFor(widget.geom, s);
    _state = s;
    setState(() {});
    _c.forward(from: 0);
  }

  void _down(_PairState s) {
    _reset?.cancel();
    _setState(s);
  }

  void _release() {
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 420), () {
      if (mounted) _setState(_PairState.rest);
    });
  }

  void _tap(VoidCallback? cb) {
    if (cb == null) return;
    // Let the morph read before the next screen slides in.
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) cb();
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mirror = Directionality.of(context) == TextDirection.rtl;
    final aGlow = _state == _PairState.aActive;
    final bGlow = _state == _PairState.bActive;
    final r = widget.radius;

    Widget glow(Color c, double x, bool on) => Positioned(
          left: -10,
          right: -10,
          top: -10,
          bottom: -10,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: _fadeDuration,
              curve: _softCurve,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r + 10),
                  gradient: RadialGradient(
                    center: Alignment(mirror ? -x : x, 0),
                    radius: 0.9,
                    colors: [c.withValues(alpha: 0.19), c.withValues(alpha: 0)],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
        );

    Widget side(PairSide p, List<Offset> poly, _PairState me, bool dimmed, Alignment origin) {
      return Positioned.fill(
        child: ClipPath(
          clipper: _PolyClipper(poly, mirror),
          child: Semantics(
            button: true,
            label: p.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _down(me),
              onTapUp: (_) => _release(),
              onTapCancel: _release,
              onTap: () => _tap(p.onTap),
              child: Stack(children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(color: p.color, gradient: p.gradient)),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: dimmed ? 0.55 : 1,
                    duration: _fadeDuration,
                    child: AnimatedScale(
                      scale: dimmed ? 0.97 : 1,
                      duration: _fadeDuration,
                      curve: _softCurve,
                      alignment: mirror ? Alignment(-origin.x, origin.y) : origin,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: p.ink),
                        child: IconTheme.merge(data: IconThemeData(color: p.ink), child: p.content),
                      ),
                    ),
                  ),
                ),
                // brightness(0.94) on the inactive side
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: dimmed ? 1 : 0,
                      duration: _fadeDuration,
                      child: const ColoredBox(color: Color(0x0F000000)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(clipBehavior: Clip.none, children: [
        glow(widget.a.glow, -0.4, aGlow),
        glow(widget.b.glow, 0.4, bGlow),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              boxShadow: const [BoxShadow(color: Color(0x1A140F1E), blurRadius: 32, offset: Offset(0, 14))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final shape = _current;
                  return Stack(children: [
                    side(widget.a, shape.a, _PairState.aActive, bGlow, const Alignment(-0.6, 0)),
                    side(widget.b, shape.b, _PairState.bActive, aGlow, const Alignment(0.6, 0)),
                    Positioned.fill(
                      child: IgnorePointer(child: CustomPaint(painter: _SepPainter(shape.sep, mirror))),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(r),
                            border: Border.all(color: const Color(0x8CFFFFFF), width: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Side content helpers (SideLeft / SideRight / SideTop / SideBottom).
// They read their ink from DefaultTextStyle so they work on any side.
// ─────────────────────────────────────────────────────────────

Color _ink(BuildContext c) => DefaultTextStyle.of(c).style.color ?? W.text;

TextStyle _monoS(Color ink, double size, double ls, double op) =>
    W.mono(size: size, color: ink.withValues(alpha: op), letterSpacing: ls);

TextStyle _arS(Color ink, double size, double op) => W.ar(size: size, color: ink.withValues(alpha: op));

class _MonoTag extends StatelessWidget {
  const _MonoTag(this.text, {this.size = 9.5, this.ls = 0.3, this.op = 0.55});
  final String text;
  final double size;
  final double ls;
  final double op;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    final isAr = RegExp(r'[؀-ۿ]').hasMatch(text);
    return Text(
      isAr ? text : text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: isAr ? _arS(ink, size + 1.5, op + 0.1) : _monoS(ink, size, ls, op),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price(this.price, {this.size = 18});
  final String price;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    final ar = context.watch<AppState>().ar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(price, style: W.serif(size: size, color: ink)),
        const SizedBox(width: 3),
        Text(ar ? 'ج.س' : 'SDG',
            style: ar ? _arS(ink, 10, 0.7) : _monoS(ink, 9, 0.18, 0.7)),
      ],
    );
  }
}

class _NameLine extends StatelessWidget {
  const _NameLine({required this.name, this.ar, required this.size, this.arSize = 15, this.end = false});
  final String name;
  final String? ar;
  final double size;
  final double arSize;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: W.serif(size: size, color: ink, letterSpacing: -0.025 * size)),
        ),
        if (ar != null) ...[
          const SizedBox(width: 8),
          Text(ar!, style: _arS(ink, arSize, 0.65)),
        ],
      ],
    );
  }
}

/// Content anchored to the start (left in LTR) of a pair.
class SideStart extends StatelessWidget {
  const SideStart({super.key, required this.label, required this.name, this.ar, this.sub, this.price, this.eta, this.icon});
  final String label;
  final String name;
  final String? ar;
  final String? sub;
  final String? price;
  final String? eta;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * 0.48;
      return Stack(clipBehavior: Clip.none, children: [
        PositionedDirectional(
          top: 18,
          start: 22,
          width: w,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsetsDirectional.only(end: 26), child: _MonoTag(label)),
            const SizedBox(height: 6),
            _NameLine(name: name, ar: ar, size: 28),
            if (sub != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(sub!, maxLines: 2, style: W.sans(size: 11, color: ink.withValues(alpha: 0.68), height: 1.35)),
              ),
            ],
            if (price != null || eta != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (eta != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: ink.withValues(alpha: 0.7), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    _MonoTag(eta!, size: 10, ls: 0.18, op: 1),
                  ]),
                if (price != null) _Price(price!),
              ]),
            ],
          ]),
        ),
        if (icon != null)
          PositionedDirectional(
            top: 16,
            start: 22 + w - 20,
            child: Opacity(opacity: 0.85, child: WIcon(icon!, size: 30, strokeWidth: 1.5, color: ink)),
          ),
      ]);
    });
  }
}

/// Content anchored to the end (right in LTR) of a pair.
class SideEnd extends StatelessWidget {
  const SideEnd({super.key, required this.label, required this.name, this.ar, this.sub, this.price, this.eta, this.icon});
  final String label;
  final String name;
  final String? ar;
  final String? sub;
  final String? price;
  final String? eta;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * 0.46;
      return Stack(clipBehavior: Clip.none, children: [
        PositionedDirectional(
          top: 18,
          end: 22,
          width: w,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Padding(padding: const EdgeInsetsDirectional.only(start: 26), child: _MonoTag(label, op: 0.62)),
            const SizedBox(height: 6),
            _NameLine(name: name, ar: ar, size: 26, arSize: 14, end: true),
            if (sub != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(sub!,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    style: W.sans(size: 11, color: ink.withValues(alpha: 0.72), height: 1.35)),
              ),
            ],
            if (price != null || eta != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (eta != null) _MonoTag(eta!, size: 10, ls: 0.18, op: 0.85),
                  if (price != null) _Price(price!),
                ],
              ),
            ],
          ]),
        ),
        if (icon != null)
          PositionedDirectional(
            top: 16,
            end: 22 + w - 18,
            child: WIcon(icon!, size: 28, strokeWidth: 1.5, color: ink),
          ),
      ]);
    });
  }
}

/// Content across the top of a horizontally split pair.
class SideTop extends StatelessWidget {
  const SideTop({super.key, required this.label, required this.name, this.ar, this.sub, this.price, this.icon});
  final String label;
  final String name;
  final String? ar;
  final String? sub;
  final String? price;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return Stack(children: [
      PositionedDirectional(
        top: 14,
        start: 22,
        end: 22,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _MonoTag(label),
              const SizedBox(height: 4),
              _NameLine(name: name, ar: ar, size: 24, arSize: 14),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11, color: ink.withValues(alpha: 0.65))),
              ],
            ]),
          ),
          const SizedBox(width: 14),
          if (price != null) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(price!, style: W.serif(size: 18, color: ink)),
              const SizedBox(height: 2),
              Text(context.watch<AppState>().ar ? 'ج.س' : 'SDG', style: _monoS(ink, 9, 0.18, 0.7)),
            ]),
            const SizedBox(width: 10),
          ],
          if (icon != null) WIcon(icon!, size: 26, strokeWidth: 1.5, color: ink),
        ]),
      ),
    ]);
  }
}

/// Content along the bottom of a horizontally split pair.
class SideBottom extends StatelessWidget {
  const SideBottom({super.key, required this.label, required this.name, this.ar, this.eta, this.price, this.icon});
  final String label;
  final String name;
  final String? ar;
  final String? eta;
  final String? price;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return Stack(children: [
      PositionedDirectional(
        start: 22,
        end: 22,
        bottom: 12,
        child: Row(children: [
          if (icon != null) ...[
            WIcon(icon!, size: 22, strokeWidth: 1.5, color: ink),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _MonoTag(label, size: 9, ls: 0.28, op: 0.65),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13, weight: FontWeight.w500, color: ink)),
                  ),
                  if (ar != null) ...[
                    const SizedBox(width: 6),
                    Text(ar!, style: _arS(ink, 12, 0.6)),
                  ],
                ],
              ),
            ]),
          ),
          if (eta != null) ...[
            const SizedBox(width: 8),
            Flexible(flex: 2, child: _MonoTag(eta!, size: 10, ls: 0.2, op: 0.78)),
          ],
          if (price != null) ...[
            const SizedBox(width: 8),
            _Price(price!, size: 17),
          ],
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// The four Home pairs (home-pairs.jsx).
// ─────────────────────────────────────────────────────────────

LinearGradient _lg(double deg, List<Color> colors) {
  // CSS angle → Flutter alignment (0deg = to top, 90deg = to right).
  final rad = (deg - 90) * math.pi / 180;
  final dx = math.cos(rad), dy = math.sin(rad);
  return LinearGradient(begin: Alignment(-dx, -dy), end: Alignment(dx, dy), colors: colors);
}

/// Prices shown on the pairs. Callers pass real fares; defaults are the
/// service base fares.
class PairPrices {
  const PairPrices({
    required this.raksha,
    required this.moto,
    required this.car,
    required this.delivery,
    required this.foodFrom,
  });
  final int raksha;
  final int moto;
  final int car;
  final int delivery;
  final int foodFrom;
}

class RakshaMotorPair extends StatelessWidget {
  const RakshaMotorPair({super.key, required this.price, required this.motoPrice, this.onRaksha, this.onMotor});
  final int price;
  final int motoPrice;
  final VoidCallback? onRaksha;
  final VoidCallback? onMotor;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ConnectedPair(
      geom: PairGeom.diagonal,
      height: 184,
      a: PairSide(
        gradient: _lg(150, const [WCardColors.deepPurple, Color(0xFF4F1F5C)]),
        ink: WCardColors.ivory,
        label: s.t('Raksha', 'ركشة'),
        onTap: onRaksha,
        content: SideStart(
          label: s.t('S-01 · RAKSHA', 'ركشة · الأسرع'),
          name: s.t('Raksha', 'ركشة'),
          sub: s.t('Cheapest · cuts traffic', 'الأرخص · الأسرع في الزحمة'),
          price: sdg(price),
          eta: s.t('2 MIN', '٢ دقيقة'),
          icon: 'raksha',
        ),
      ),
      b: PairSide(
        color: WCardColors.ivory,
        ink: WCardColors.deepPurple,
        label: s.t('Motorcycle', 'موتر'),
        onTap: onMotor,
        content: SideEnd(
          label: s.t('S-02 · MOTOR', 'موتر · راكب واحد'),
          name: s.t('Motor', 'موتر'),
          sub: s.t('Beats every queue', 'يتسلل من الزحام'),
          price: sdg(motoPrice),
          eta: s.t('1 MIN', '١ دقيقة'),
          icon: 'bike',
        ),
      ),
    );
  }
}

class DeliveryRidesPair extends StatelessWidget {
  const DeliveryRidesPair({super.key, required this.ridePrice, this.onDelivery, this.onRide});
  final int ridePrice;
  final VoidCallback? onDelivery;
  final VoidCallback? onRide;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ConnectedPair(
      geom: PairGeom.trapezoid,
      height: 170,
      a: PairSide(
        color: WCardColors.lavender,
        ink: WCardColors.deepPurple,
        label: s.t('Delivery', 'توصيل'),
        onTap: onDelivery,
        content: SideTop(
          label: s.t('S-03 · COURIER', 'توصيل طلبات'),
          name: s.t('Delivery', 'توصيل'),
          sub: s.t('Up to 5 kg · anywhere', 'حتى ٥ كجم · أي مكان'),
          icon: 'bag',
        ),
      ),
      b: PairSide(
        gradient: _lg(160, const [WCardColors.purple, WCardColors.deepPurple]),
        ink: WCardColors.ivory,
        label: s.t('Rides', 'مشاوير'),
        onTap: onRide,
        content: SideBottom(
          label: s.t('S-04 · RIDES', 'مشاوير · سيارة'),
          name: s.t('Ride', 'مشوار'),
          eta: s.t('NOW · 3 MIN', 'الآن · ٣ دقيقة'),
          price: sdg(ridePrice),
          icon: 'car',
        ),
      ),
    );
  }
}

class CarShippingPair extends StatelessWidget {
  const CarShippingPair({super.key, required this.carPrice, required this.foodFrom, this.onCar, this.onFood});
  final int carPrice;
  final int foodFrom;
  final VoidCallback? onCar;
  final VoidCallback? onFood;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ConnectedPair(
      geom: PairGeom.chevron,
      height: 186,
      a: PairSide(
        color: WCardColors.ivory,
        ink: WCardColors.deepPurple,
        label: s.t('Car', 'سيارة'),
        onTap: onCar,
        content: SideTop(
          label: s.t('S-05 · CAR', 'سيارة · ٤ ركاب'),
          name: s.t('Car', 'سيارة'),
          sub: s.t('A/C · spacious', 'مكيّفة · فسيحة'),
          price: sdg(carPrice),
          icon: 'car',
        ),
      ),
      b: PairSide(
        gradient: _lg(140, const [Color(0xFFB86E4B), Color(0xFF5A2E1E)]),
        ink: WCardColors.ivory,
        glow: const Color(0xFFE4A93A),
        label: s.t('Food', 'طعام'),
        onTap: onFood,
        content: SideBottom(
          label: s.t('S-06 · FOOD', 'طعام · مطاعم'),
          name: s.t('Food', 'طعام'),
          eta: s.t('22–40 MIN', '٢٢–٤٠ دقيقة'),
          price: '${sdg(foodFrom)}+',
          icon: 'bowl',
        ),
      ),
    );
  }
}

class StoreTrackingPair extends StatelessWidget {
  const StoreTrackingPair({super.key, this.activeCount = 0, this.onStore, this.onTrack});

  /// Active trips + orders shown on the Track half.
  final int activeCount;
  final VoidCallback? onStore;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sub = activeCount == 0
        ? s.t('Nothing on the way', 'لا طلبات نشطة')
        : activeCount == 1
            ? s.t('1 active order', 'طلب نشط واحد')
            : s.t('$activeCount active orders', '$activeCount طلبات نشطة');
    return ConnectedPair(
      geom: PairGeom.hexZig,
      height: 164,
      a: PairSide(
        gradient: _lg(135, const [WCardColors.lavender, Color(0xFFBFB1F0)]),
        ink: WCardColors.deepPurple,
        label: s.t('Store', 'متجر'),
        onTap: onStore,
        content: SideStart(
          label: s.t('S-07 · STORE', 'متجر وصلها'),
          name: s.t('Store', 'متجر'),
          sub: s.t('Groceries · pharmacy', 'بقالة · أدوية · فطور'),
          icon: 'bowl',
        ),
      ),
      b: PairSide(
        gradient: _lg(160, const [WCardColors.deepPurple, Color(0xFF3A1A45)]),
        ink: WCardColors.ivory,
        label: s.t('Tracking', 'تتبع'),
        onTap: onTrack,
        content: SideEnd(
          label: s.t('S-08 · TRACK', 'تتبع طلبك'),
          name: s.t('Track', 'تتبع'),
          sub: sub,
          eta: activeCount > 0 ? s.t('LIVE', 'مباشر') : null,
          icon: 'pin',
        ),
      ),
    );
  }
}

/// The 4-pair "puzzle" on Home, with staggered widths and the `.ws-puzzle`
/// entry animation (fade + translateY 14px + scale .985, 450ms, 40/100/160/220ms delays).
///
/// [onTap] receives: raksha, moto, delivery, car, food, store, tracking.
class ConnectedPairsPuzzle extends StatefulWidget {
  const ConnectedPairsPuzzle({
    super.key,
    required this.prices,
    this.activeCount = 0,
    this.offset = 14,
    required this.onTap,
  });

  final PairPrices prices;
  final int activeCount;
  final double offset;
  final ValueChanged<String> onTap;

  @override
  State<ConnectedPairsPuzzle> createState() => _ConnectedPairsPuzzleState();
}

class _ConnectedPairsPuzzleState extends State<ConnectedPairsPuzzle> with SingleTickerProviderStateMixin {
  static const _delays = [40, 100, 160, 220];
  static const _dur = 450;
  static const _total = 220 + _dur;
  static const _curve = Cubic(0.2, 0.85, 0.2, 1);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _total));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _block(int i, Widget child, {double offset = 0, double nextOverlap = 0, required double height}) {
    final anim = CurvedAnimation(
      parent: _c,
      curve: Interval(_delays[i] / _total, (_delays[i] + _dur) / _total, curve: _curve),
    );
    Widget w = Padding(
      padding: EdgeInsetsDirectional.only(start: offset > 0 ? offset : 0, end: offset < 0 ? -offset : 0),
      child: child,
    );
    // Negative top margin of the next block: let this one overflow into it.
    if (nextOverlap > 0) {
      w = SizedBox(
        height: height - nextOverlap,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: height,
          maxHeight: height,
          child: w,
        ),
      );
    }
    return AnimatedBuilder(
      animation: anim,
      child: w,
      builder: (context, child) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.985 + 0.015 * t, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prices;
    final tap = widget.onTap;
    final o = widget.offset;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _block(0, RakshaMotorPair(price: p.raksha, motoPrice: p.moto, onRaksha: () => tap('raksha'), onMotor: () => tap('moto')),
          height: 184, nextOverlap: 10),
      _block(1, DeliveryRidesPair(ridePrice: p.car, onDelivery: () => tap('delivery'), onRide: () => tap('car')),
          height: 170, nextOverlap: 10, offset: o),
      _block(2, CarShippingPair(carPrice: p.car, foodFrom: p.foodFrom, onCar: () => tap('car'), onFood: () => tap('food')),
          height: 186, nextOverlap: 6, offset: -o),
      _block(3, StoreTrackingPair(activeCount: widget.activeCount, onStore: () => tap('store'), onTrack: () => tap('tracking')),
          height: 164),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// ServiceCard (components.jsx) — grid tile & list row variants.
// ─────────────────────────────────────────────────────────────

enum ServiceCardLayout { grid, row }

class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.icon,
    required this.name,
    required this.sub,
    this.layout = ServiceCardLayout.grid,
    this.primary = false,
    this.onTap,
  });

  final String icon;
  final String name;
  final String sub;
  final ServiceCardLayout layout;
  final bool primary;
  final VoidCallback? onTap;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final child = widget.layout == ServiceCardLayout.row ? _row(accent) : _grid(accent);
    return Semantics(
      button: true,
      label: widget.name,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 120), child: child),
      ),
    );
  }

  Widget _row(Color accent) {
    final p = widget.primary;
    final fg = p ? Colors.white : W.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p ? W.text : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0F140F1E), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p ? const Color(0x1AFFFFFF) : W.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: WIcon(widget.icon, size: 22, strokeWidth: 1.6, color: p ? accent : W.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.name, style: W.sans(size: 15, weight: FontWeight.w500, color: fg)),
            const SizedBox(height: 2),
            Text(widget.sub, style: W.sans(size: 12, color: p ? const Color(0x8CFFFFFF) : W.text2)),
          ]),
        ),
        Opacity(opacity: 0.5, child: WIcon('chevron', size: 16, strokeWidth: 1.6, color: fg)),
      ]),
    );
  }

  Widget _grid(Color accent) {
    final p = widget.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF4F4F4), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (p)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const AlignmentDirectional(0.6, -0.8).resolve(Directionality.of(context)),
                  radius: 0.9,
                  colors: [accent.withValues(alpha: 0.33), accent.withValues(alpha: 0)],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p ? Colors.white : W.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: WIcon(widget.icon, size: 20, strokeWidth: 1.6, color: p ? accent : W.text),
            ),
            const SizedBox(height: 18),
            Text(widget.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 15, weight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 1),
            Text(widget.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: W.sans(size: 11, color: W.text2, letterSpacing: 0.2)),
          ]),
        ),
      ]),
    );
  }
}
