import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../data/models.dart';
import '../theme/tokens.dart';

/// Enable real Google Maps with:
///   flutter run --dart-define=USE_GOOGLE_MAPS=true
/// (and put your key in android/local.properties + ios/Flutter/Secrets.xcconfig,
/// see README). Without it the illustrated map from the design is used.
const kUseGoogleMaps = bool.fromEnvironment('USE_GOOGLE_MAPS');

/// Map surface used by home / booking / tracking / driver screens.
class WMap extends StatelessWidget {
  const WMap({
    super.key,
    this.pickup,
    this.dropoff,
    this.showRoute = false,
    this.drivers = 0,
    this.driverPos,
    this.pulse = false,
    this.styleOverride,
    this.padding = EdgeInsets.zero,
  });

  final Place? pickup;
  final Place? dropoff;
  final bool showRoute;

  /// Number of idle nearby-driver dots.
  final int drivers;

  /// Live position of the assigned driver (lat, lng).
  final (double, double)? driverPos;
  final bool pulse;

  /// white | dark | illustrated (defaults to the app setting).
  final String? styleOverride;

  /// Space covered by overlays (sheets) so the camera frames the route above them.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = styleOverride ?? s.mapStyle;
    if (kUseGoogleMaps) {
      return _GoogleMapView(
        pickup: pickup ?? s.pickup,
        dropoff: showRoute ? dropoff : null,
        driverPos: driverPos,
        drivers: drivers,
        dark: style == 'dark',
        accent: s.accent,
        padding: padding,
      );
    }
    return IllustratedMap(
      style: style,
      accent: s.accent,
      showRoute: showRoute,
      drivers: drivers,
      pulse: pulse,
      driverPoint: _project(driverPos),
    );
  }

  /// Map a real coordinate onto the illustrated route, where pickup sits at
  /// (100,640) and drop-off at (320,280) in the 402×874 artboard.
  Offset? _project((double, double)? pos) {
    final p = pickup, d = dropoff;
    if (pos == null || p == null || d == null) return null;
    final dx = d.lng - p.lng, dy = d.lat - p.lat;
    final len2 = dx * dx + dy * dy;
    double f = 0;
    if (len2 > 1e-12) {
      f = ((pos.$2 - p.lng) * dx + (pos.$1 - p.lat) * dy) / len2;
    }
    // Before pickup the driver approaches from below-left.
    if (f < 0) return Offset(100 - 60 * (-f).clamp(0, 1), 640 + 80 * (-f).clamp(0, 1));
    return _routePoint(f.clamp(0, 1).toDouble());
  }
}

/// Point along the illustrated route curve
/// M100 640 Q140 540 220 510 T320 280.
Offset _routePoint(double t) {
  Offset quad(Offset a, Offset c, Offset b, double u) =>
      a * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + b * (u * u);
  const a = Offset(100, 640), c1 = Offset(140, 540), m = Offset(220, 510);
  const c2 = Offset(300, 480), b = Offset(320, 280); // reflected control for T
  return t < 0.5 ? quad(a, c1, m, t * 2) : quad(m, c2, b, (t - 0.5) * 2);
}

class IllustratedMap extends StatefulWidget {
  const IllustratedMap({
    super.key,
    this.style = 'illustrated',
    required this.accent,
    this.showRoute = false,
    this.drivers = 0,
    this.pulse = false,
    this.driverPoint,
  });

  final String style;
  final Color accent;
  final bool showRoute;
  final int drivers;
  final bool pulse;
  final Offset? driverPoint;

  @override
  State<IllustratedMap> createState() => _IllustratedMapState();
}

class _IllustratedMapState extends State<IllustratedMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _palettes = {
    'white': ['#F4F1EA', '#E4DFD3', '#FFFFFF', '#DDE6E8', '#E3E5D8', '#A8A296'],
    'dark': ['#15161A', '#26282E', '#3A3D45', '#1B2730', '#1C2620', '#5C5F66'],
    'illustrated': ['#F1ECDF', '#E5DFCC', '#FAF5E6', '#BBD3D8', '#D2DEB8', '#9C957F'],
  };

  static const _driverSpots = [
    [180, 220], [300, 340], [120, 480], [280, 590], [80, 730], [360, 680], [200, 130],
  ];

  String _svg() {
    final p = _palettes[widget.style] ?? _palettes['illustrated']!;
    final [bg, road, roadHi, water, park, label] = p;
    final a = colorHex(widget.accent);
    final route = widget.showRoute
        ? '<path d="M 100 640 Q 140 540, 220 510 T 320 280" stroke="$a" stroke-opacity="0.18" stroke-width="18" fill="none" stroke-linecap="round"/>'
            '<path d="M 100 640 Q 140 540, 220 510 T 320 280" stroke="$a" stroke-width="5" fill="none" stroke-linecap="round"/>'
            '<circle cx="100" cy="640" r="9" fill="#fff" stroke="$a" stroke-width="3.5"/>'
            '<g transform="translate(320 280)"><circle r="14" fill="$a"/><circle r="5" fill="#fff"/></g>'
        : '';
    final dots = StringBuffer();
    for (var i = 0; i < widget.drivers; i++) {
      final [x, y] = _driverSpots[i % _driverSpots.length];
      dots.write('<g transform="translate($x $y)"><circle r="6" fill="#0A0908" stroke="#fff" stroke-width="2"/><circle r="3" fill="#fff"/></g>');
    }
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 402 874">
<rect width="402" height="874" fill="$bg"/>
<path d="M-20 320 C 80 280, 130 380, 200 360 S 360 280, 460 320 L 460 410 C 360 380, 240 460, 160 440 S 30 470, -20 430 Z" fill="$water" opacity="0.95"/>
<path d="M120 -20 C 140 80, 200 180, 200 360" stroke="$water" stroke-width="44" fill="none" opacity="0.9"/>
<ellipse cx="60" cy="180" rx="80" ry="42" fill="$park" opacity="0.85"/>
<ellipse cx="340" cy="560" rx="100" ry="70" fill="$park" opacity="0.8"/>
<ellipse cx="90" cy="700" rx="120" ry="60" fill="$park" opacity="0.7"/>
<ellipse cx="380" cy="120" rx="60" ry="50" fill="$park" opacity="0.5"/>
<g stroke="$road" stroke-width="14" fill="none" stroke-linecap="round">
<path d="M-20 90 L 460 110"/><path d="M-20 220 L 460 240"/><path d="M-20 520 L 460 510"/>
<path d="M-20 640 L 460 660"/><path d="M-20 780 L 460 800"/><path d="M70 -20 L 90 894"/>
<path d="M210 -20 L 220 360"/><path d="M210 420 L 230 894"/><path d="M330 -20 L 340 894"/>
</g>
<g stroke="$roadHi" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.9">
<path d="M-20 90 L 460 110"/><path d="M-20 520 L 460 510"/><path d="M70 -20 L 90 894"/><path d="M330 -20 L 340 894"/>
</g>
<g stroke="$road" stroke-width="10" fill="none" stroke-linecap="round">
<path d="M-20 460 Q 200 470, 460 660"/><path d="M40 894 Q 200 720, 460 760"/>
</g>
$route
<g fill="$label" font-family="monospace" font-size="9" letter-spacing="1">
<text x="40" y="80" opacity="0.85">OMDURMAN</text><text x="260" y="80" opacity="0.85">KHARTOUM N.</text>
<text x="240" y="710" opacity="0.85">KHARTOUM</text><text x="40" y="600" opacity="0.7">RIVERSIDE</text>
</g>
$dots
</svg>''';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // Reproduce preserveAspectRatio="xMidYMid slice".
      final scale = [box.maxWidth / 402, box.maxHeight / 874].reduce((a, b) => a > b ? a : b);
      final w = 402 * scale, h = 874 * scale;
      final ox = (box.maxWidth - w) / 2, oy = (box.maxHeight - h) / 2;
      Offset at(Offset p) => Offset(ox + p.dx * scale, oy + p.dy * scale);
      return ClipRect(
        child: Stack(children: [
          Positioned(left: ox, top: oy, width: w, height: h, child: SvgPicture.string(_svg(), fit: BoxFit.fill)),
          if (widget.pulse)
            _positioned(at(const Offset(100, 640)), AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final v = _pulse.value < 0.5 ? _pulse.value * 2 : (1 - _pulse.value) * 2;
                final r = (14 + 18 * v) * scale;
                return Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent.withValues(alpha: 0.18 * (1 - v))),
                );
              },
            )),
          if (widget.driverPoint != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              left: at(widget.driverPoint!).dx - 17,
              top: at(widget.driverPoint!).dy - 17,
              child: const _DriverMarker(),
            ),
        ]),
      );
    });
  }

  Widget _positioned(Offset c, Widget child) => Positioned(
        left: c.dx,
        top: c.dy,
        child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
      );
}

class _DriverMarker extends StatelessWidget {
  const _DriverMarker();
  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: W.text,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
      );
}

// ── Google Maps ─────────────────────────────────────────────

const _darkMapStyle = '''[
{"elementType":"geometry","stylers":[{"color":"#15161a"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#5c5f66"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#15161a"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#26282e"}]},
{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3a3d45"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#1b2730"}]},
{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1c2620"}]},
{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]}
]''';

class _GoogleMapView extends StatefulWidget {
  const _GoogleMapView({
    required this.pickup,
    this.dropoff,
    this.driverPos,
    this.drivers = 0,
    required this.dark,
    required this.accent,
    required this.padding,
  });

  final Place pickup;
  final Place? dropoff;
  final (double, double)? driverPos;
  final int drivers;
  final bool dark;
  final Color accent;
  final EdgeInsets padding;

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  final _ctrl = Completer<GoogleMapController>();

  LatLng get _p => LatLng(widget.pickup.lat, widget.pickup.lng);

  @override
  void didUpdateWidget(covariant _GoogleMapView old) {
    super.didUpdateWidget(old);
    if (old.dropoff?.id != widget.dropoff?.id || old.pickup.id != widget.pickup.id) _frame();
  }

  Future<void> _frame() async {
    final c = await _ctrl.future;
    final d = widget.dropoff;
    if (d == null) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_p, 14.5));
      return;
    }
    final sw = LatLng(_min(_p.latitude, d.lat), _min(_p.longitude, d.lng));
    final ne = LatLng(_max(_p.latitude, d.lat), _max(_p.longitude, d.lng));
    await c.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 60));
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final d = widget.dropoff;
    final markers = <Marker>{
      Marker(markerId: const MarkerId('pickup'), position: _p, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
      if (d != null)
        Marker(markerId: const MarkerId('dropoff'), position: LatLng(d.lat, d.lng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)),
      if (widget.driverPos != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(widget.driverPos!.$1, widget.driverPos!.$2),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      for (var i = 0; i < widget.drivers; i++)
        Marker(
          markerId: MarkerId('idle$i'),
          position: LatLng(_p.latitude + 0.004 * ((i % 3) - 1) + 0.002 * i, _p.longitude + 0.005 * ((i % 2) * 2 - 1) - 0.001 * i),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          alpha: 0.8,
        ),
    };
    // Straight-line route; swap in the Directions API for road-snapped paths.
    final polylines = <Polyline>{
      if (d != null)
        Polyline(polylineId: const PolylineId('route'), points: [_p, LatLng(d.lat, d.lng)], color: widget.accent, width: 5),
    };
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _p, zoom: 14.5),
      style: widget.dark ? _darkMapStyle : null,
      markers: markers,
      polylines: polylines,
      padding: widget.padding,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: (c) {
        _ctrl.complete(c);
        _frame();
      },
    );
  }
}
