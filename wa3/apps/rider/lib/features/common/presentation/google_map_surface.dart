import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:wa3_core/wa3_core.dart';

import 'map_surface.dart';

Widget googleMapBuilder(BuildContext context, MapSpec spec) => GoogleMapSurface(spec: spec);

/// Google Maps rendering of a [MapSpec]. Pin colors come from [MapColors].
class GoogleMapSurface extends StatefulWidget {
  const GoogleMapSurface({super.key, required this.spec});
  final MapSpec spec;

  @override
  State<GoogleMapSurface> createState() => _GoogleMapSurfaceState();
}

class _GoogleMapSurfaceState extends State<GoogleMapSurface> {
  gm.GoogleMapController? _controller;
  final Map<PinKind, gm.BitmapDescriptor> _icons = {};
  gm.LatLng? _lastCenter;

  gm.LatLng _ll(GeoPoint p) => gm.LatLng(p.lat, p.lng);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons.isEmpty) _buildIcons(MediaQuery.devicePixelRatioOf(context));
  }

  Future<void> _buildIcons(double dpr) async {
    for (final kind in PinKind.values) {
      final color = MapPin(id: '', point: const GeoPoint(0, 0), kind: kind, label: '').color;
      final size = (kind == PinKind.driver ? 28 : 24) * dpr;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final r = size / 2;
      c.drawCircle(Offset(r, r), r, Paint()..color = Colors.white);
      c.drawCircle(Offset(r, r), r * 0.72, Paint()..color = color);
      final img = await rec.endRecording().toImage(size.ceil(), size.ceil());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) continue;
      _icons[kind] = gm.BitmapDescriptor.bytes(bytes.buffer.asUint8List(), imagePixelRatio: dpr);
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(GoogleMapSurface old) {
    super.didUpdateWidget(old);
    if (old.spec.focusKey != widget.spec.focusKey) _focus();
  }

  Future<void> _focus() async {
    final c = _controller;
    if (c == null) return;
    final fit = widget.spec.fit;
    if (fit != null && fit.length > 1) {
      var s = fit.first.lat, w = fit.first.lng, n = s, e = w;
      for (final p in fit) {
        s = math.min(s, p.lat);
        n = math.max(n, p.lat);
        w = math.min(w, p.lng);
        e = math.max(e, p.lng);
      }
      if (n - s < 0.002) {
        s -= 0.001;
        n += 0.001;
      }
      if (e - w < 0.002) {
        w -= 0.001;
        e += 0.001;
      }
      await _move(c, gm.CameraUpdate.newLatLngBounds(gm.LatLngBounds(southwest: gm.LatLng(s, w), northeast: gm.LatLng(n, e)), 56));
    } else {
      await _move(c, gm.CameraUpdate.newLatLngZoom(_ll(widget.spec.center), widget.spec.zoom));
    }
  }

  /// Honors "reduce motion": jump instead of animating.
  Future<void> _move(gm.GoogleMapController c, gm.CameraUpdate u) =>
      mounted && MediaQuery.disableAnimationsOf(context) ? c.moveCamera(u) : c.animateCamera(u);

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final markers = {
      for (final p in spec.pins)
        gm.Marker(
          markerId: gm.MarkerId(p.id),
          position: _ll(p.point),
          icon: _icons[p.kind] ?? gm.BitmapDescriptor.defaultMarkerWithHue(HSVColor.fromColor(p.color).hue),
          anchor: const Offset(0.5, 0.5),
          infoWindow: gm.InfoWindow(title: p.label),
          zIndexInt: p.kind == PinKind.driver ? 2 : 1,
        ),
    };
    final lines = {
      for (final l in spec.lines)
        gm.Polyline(
          polylineId: gm.PolylineId(l.id),
          points: l.points.map(_ll).toList(),
          color: l.color,
          width: 5,
          patterns: l.dashed ? [gm.PatternItem.dash(18), gm.PatternItem.gap(10)] : const [],
        ),
    };
    return Semantics(
      label: spec.semanticLabel,
      container: true,
      child: gm.GoogleMap(
        initialCameraPosition: gm.CameraPosition(target: _ll(spec.center), zoom: spec.zoom),
        markers: markers,
        polylines: lines,
        myLocationEnabled: spec.myLocation,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        scrollGesturesEnabled: spec.interactive,
        zoomGesturesEnabled: spec.interactive,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        padding: spec.padding,
        onMapCreated: (c) {
          _controller = c;
          if (spec.fit != null) _focus();
        },
        onCameraMove: (pos) {
          _lastCenter = pos.target;
          spec.onCameraMove?.call(GeoPoint(pos.target.latitude, pos.target.longitude));
        },
        onCameraIdle: () {
          final t = _lastCenter ?? _ll(spec.center);
          spec.onCameraIdle?.call(GeoPoint(t.latitude, t.longitude));
        },
      ),
    );
  }
}
