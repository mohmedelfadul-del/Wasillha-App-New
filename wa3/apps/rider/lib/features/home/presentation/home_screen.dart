import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/domain/live.dart';
import '../../common/presentation/cache_banner.dart';
import '../../common/presentation/map_surface.dart';
import '../../places/presentation/place_search_screen.dart';
import '../../request/presentation/request_screen.dart';
import '../../trip/presentation/trip_screen.dart';
import '../application/home_location_controller.dart';
import 'active_trip_card.dart';
import 'home_drawer.dart';
import 'location_notice.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeLocationController _loc = HomeLocationController(context.deps.location);
  late Stream<Live<List<Trip>>> _active = context.deps.trips.watchActiveTrips();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loc.locate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the system settings: check again without prompting.
    if (state == AppLifecycleState.resumed && !(_loc.result?.ok ?? true)) _loc.locate(request: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loc.dispose();
    super.dispose();
  }

  Future<void> _whereTo() async {
    final s = context.s;
    final here = _loc.result?.point;
    final nav = Navigator.of(context);
    final dropoff = await nav.push<Place>(MaterialPageRoute(
      builder: (_) => PlaceSearchScreen(title: s.t('إلى أين؟', 'Where to?'), near: here ?? defaultCenter),
    ));
    if (dropoff == null || !mounted) return;
    await nav.push(MaterialPageRoute(
      builder: (_) => RequestScreen(pickup: here == null ? null : Place(point: here, label: ''), dropoff: dropoff, currentLocation: here),
    ));
  }

  void _openTrip(String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripScreen(tripId: id)));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const HomeDrawer(),
      body: Stack(children: [
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _loc,
            builder: (context, _) {
              final p = _loc.result?.point;
              return context.deps.map(
                context,
                MapSpec(
                  center: p ?? defaultCenter,
                  zoom: p == null ? 12 : 15,
                  myLocation: p != null,
                  focusKey: 'fix-${_loc.fixes}',
                  semanticLabel: p == null
                      ? s.t('خريطة الخرطوم. موقعك غير معروف.', 'Map of Khartoum. Your location is unknown.')
                      : s.t('خريطة حول موقعك', 'Map around your location'),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(WSpace.md),
            child: Row(children: [
              Builder(
                builder: (context) => IconButton.filledTonal(
                  tooltip: s.t('القائمة', 'Menu'),
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: s.t('أظهر موقعي', 'Show my location'),
                icon: const Icon(Icons.my_location),
                onPressed: () => _loc.locate(),
              ),
            ]),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(WSpace.lg),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ListenableBuilder(listenable: _loc, builder: (context, _) => LocationNotice(controller: _loc)),
                    _activeOrWhereTo(context),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _activeOrWhereTo(BuildContext context) => StreamBuilder<Live<List<Trip>>>(
        stream: _active,
        builder: (context, snap) {
          final s = context.s;
          final trips = snap.data?.value ?? const <Trip>[];
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (snap.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: WSpace.sm),
                child: WBanner(
                  tone: Tone.error,
                  text: s.t('تعذّر التحقق من وجود رحلة حالية.', 'We couldn’t check for a current trip.'),
                  actionLabel: s.retry,
                  onAction: () => setState(() => _active = context.deps.trips.watchActiveTrips()),
                ),
              ),
            if (snap.data != null) CacheBanner(fromCache: snap.data!.fromCache),
            if (trips.isNotEmpty)
              ActiveTripCard(trip: trips.first, onOpen: () => _openTrip(trips.first.id))
            else
              _WhereToField(onTap: _whereTo),
          ]);
        },
      );
}

/// The one prominent entry point: looks like a field, opens place search.
class _WhereToField extends StatelessWidget {
  const _WhereToField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: s.t('إلى أين؟ ابحث عن وجهتك', 'Where to? Search your destination'),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: theme.colorScheme.outline)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WSpace.lg, vertical: WSpace.md),
              child: Row(children: [
                Icon(Icons.search, color: theme.colorScheme.primary),
                const SizedBox(width: WSpace.md),
                Expanded(child: Text(s.t('إلى أين؟', 'Where to?'), style: theme.textTheme.titleLarge)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
