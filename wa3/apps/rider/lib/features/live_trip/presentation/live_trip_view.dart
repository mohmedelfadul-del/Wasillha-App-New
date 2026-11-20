import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/presentation/cache_banner.dart';
import '../../common/presentation/map_surface.dart';
import '../../common/presentation/ticking.dart';
import '../../trips/domain/polyline.dart';
import 'driver_header.dart';
import 'trip_actions.dart';

/// Driver assigned → on the way → arrived → on trip → arrived at destination.
class LiveTripView extends StatefulWidget {
  const LiveTripView({super.key, required this.trip, this.fromCache = false});
  final Trip trip;
  final bool fromCache;
  @override
  State<LiveTripView> createState() => _LiveTripViewState();
}

class _LiveTripViewState extends State<LiveTripView> {
  Stream<DriverPosition?>? _presence;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.trip.driverId;
    if (_presence == null && id != null) _presence = context.deps.trips.watchDriverPosition(id);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.state(widget.trip.state))),
      body: StreamBuilder<DriverPosition?>(
        stream: _presence,
        builder: (context, snap) => Ticking(builder: (context, now) => _layout(context, snap, now)),
      ),
    );
  }

  Widget _layout(BuildContext context, AsyncSnapshot<DriverPosition?> snap, DateTime now) {
    final trip = widget.trip;
    final pos = snap.hasError ? null : snap.data;
    final top = <Widget>[
      DriverHeader(trip: trip),
      CacheBanner(fromCache: widget.fromCache),
      LocationFreshness(position: pos, now: now, waiting: snap.connectionState == ConnectionState.waiting && !snap.hasError),
    ];
    final map = _map(context, pos);
    final actions = SafeArea(top: false, child: TripActions(trip: trip));
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 560 || MediaQuery.textScalerOf(context).scale(14) > 20;
        if (compact) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...top,
                SizedBox(height: 240, child: map),
                actions,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...top,
            Expanded(child: map),
            actions,
          ],
        );
      },
    );
  }

  Widget _map(BuildContext context, DriverPosition? pos) {
    final s = context.s;
    final trip = widget.trip;
    final route = routePoints(trip.route) ?? [trip.pickup.point, trip.dropoff.point];
    final onBoard = !trip.state.isPrePickup;
    final driverPoint = pos?.point;
    final lines = <MapLine>[
      if (onBoard && driverPoint != null)
        MapLine(id: 'remaining', points: remainingRoute(route, driverPoint), dashed: trip.route.polyline == null)
      else
        MapLine(id: 'route', points: route, dashed: trip.route.polyline == null, color: onBoard ? MapColors.route : MapColors.routeTraveled),
    ];
    final pins = <MapPin>[
      if (!onBoard) MapPin(id: 'pickup', point: trip.pickup.point, kind: PinKind.pickup, label: '${s.t('نقطة الانطلاق', 'Pickup')}: ${trip.pickup.label}'),
      MapPin(id: 'dropoff', point: trip.dropoff.point, kind: PinKind.dropoff, label: '${s.t('الوجهة', 'Destination')}: ${trip.dropoff.label}'),
      if (driverPoint != null) MapPin(id: 'driver', point: driverPoint, kind: PinKind.driver, label: s.t('السائق', 'Driver')),
    ];
    return context.deps.map(
      context,
      MapSpec(
        center: driverPoint ?? trip.pickup.point,
        pins: pins,
        lines: lines,
        fit: [?driverPoint, onBoard ? trip.dropoff.point : trip.pickup.point],
        // Re-fit when the driver first appears and when the rider is picked up.
        focusKey: 'fit-${driverPoint != null}-$onBoard',
        semanticLabel: driverPoint == null
            ? s.t('خريطة الرحلة. موقع السائق غير متاح.', 'Trip map. The driver’s location isn’t available.')
            : s.t('خريطة الرحلة مع موقع السائق', 'Trip map with the driver’s position'),
      ),
    );
  }
}

/// Says plainly when the driver's position is missing or older than 30 s.
class LocationFreshness extends StatelessWidget {
  const LocationFreshness({super.key, required this.position, required this.now, this.waiting = false});
  final DriverPosition? position;
  final DateTime now;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final p = position;
    if (waiting) return const SizedBox.shrink();
    if (p == null) {
      return WBanner(tone: Tone.warning, text: s.t('موقع السائق غير متاح الآن.', 'The driver’s location isn’t available right now.'));
    }
    if (!p.isStale(now)) return const SizedBox.shrink();
    return WBanner(
      tone: Tone.warning,
      text:
          '${s.t('موقع السائق قديم — آخر تحديث قبل', 'Driver location is out of date — last update')} ${_ago(now.difference(p.updatedAt), s)}. '
          '${s.t('قد لا يكون في المكان الظاهر.', 'They may not be where the map shows.')}',
    );
  }
}

String _ago(Duration d, S s) {
  if (d.inSeconds < 60) return '${ltr('${d.inSeconds}')} ${s.t('ث', 's ago')}';
  if (d.inMinutes < 60) return '${ltr('${d.inMinutes}')} ${s.t('د', 'min ago')}';
  return '${ltr('${d.inHours}')} ${s.t('س', 'h ago')}';
}
