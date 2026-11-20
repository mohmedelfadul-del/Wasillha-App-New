import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

/// What a map shows, independent of the map SDK, so screens can be tested
/// without platform views (tests inject a placeholder [MapBuilder]).
enum PinKind { pickup, dropoff, driver }

class MapPin {
  const MapPin({required this.id, required this.point, required this.kind, required this.label});
  final String id;
  final GeoPoint point;
  final PinKind kind;

  /// Read by screen readers (marker title).
  final String label;

  Color get color => switch (kind) {
        PinKind.pickup => MapColors.pickup,
        PinKind.dropoff => MapColors.dropoff,
        PinKind.driver => MapColors.driver,
      };
}

class MapLine {
  const MapLine({required this.id, required this.points, this.color = MapColors.route, this.dashed = false});
  final String id;
  final List<GeoPoint> points;
  final Color color;

  /// Dashed = an estimate (straight line), not a real road route.
  final bool dashed;
}

class MapSpec {
  const MapSpec({
    required this.center,
    required this.semanticLabel,
    this.zoom = 15,
    this.pins = const [],
    this.lines = const [],
    this.fit,
    this.focusKey,
    this.myLocation = false,
    this.onCameraMove,
    this.onCameraIdle,
    this.interactive = true,
    this.padding = EdgeInsets.zero,
  });

  final GeoPoint center;

  /// Read by screen readers for the whole map.
  final String semanticLabel;
  final double zoom;
  final List<MapPin> pins;
  final List<MapLine> lines;

  /// Points to keep in view. Applied on creation and whenever [focusKey] changes.
  final List<GeoPoint>? fit;

  /// Changing it moves the camera to [center] (or [fit]).
  final String? focusKey;
  final bool myLocation;
  final ValueChanged<GeoPoint>? onCameraMove;
  final ValueChanged<GeoPoint>? onCameraIdle;
  final bool interactive;
  final EdgeInsets padding;
}

typedef MapBuilder = Widget Function(BuildContext context, MapSpec spec);

/// Default map centre when the rider's location is unknown (Khartoum).
const defaultCenter = GeoPoint(15.5007, 32.5599);
