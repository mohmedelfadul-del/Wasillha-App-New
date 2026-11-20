import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/presentation/map_surface.dart';
import '../../places/presentation/place_search_screen.dart';
import '../../trip/presentation/trip_screen.dart';
import '../../trips/domain/trip_repository.dart';
import '../application/request_controller.dart';
import 'category_step.dart';
import 'fare_input.dart';
import 'places_header.dart';
import 'route_preview.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.currentLocation,
    this.category,
    this.initialDraft,
    this.preferredFare,
  });
  final Place? pickup;
  final Place dropoff;
  final GeoPoint? currentLocation;
  final Category? category;
  final DraftResult? initialDraft;
  final int? preferredFare;

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  late final RequestController _c = RequestController(
    trips: context.deps.trips,
    places: context.deps.places,
    lang: context.s.lang,
    pickup: widget.pickup,
    dropoff: widget.dropoff,
    category: widget.category,
    initialDraft: widget.initialDraft,
    preferredFare: widget.preferredFare,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _change({required bool pickup}) async {
    final s = context.s;
    final near = _c.pickup?.point ?? widget.currentLocation ?? defaultCenter;
    final place = await Navigator.of(context).push<Place>(MaterialPageRoute(
      builder: (_) => PlaceSearchScreen(
        title: pickup ? s.t('من أين؟', 'Pickup point') : s.t('إلى أين؟', 'Where to?'),
        near: near,
        currentLocation: pickup ? widget.currentLocation : null,
        pinKindIsPickup: pickup,
      ),
    ));
    if (place == null) return;
    pickup ? _c.setPickup(place) : _c.setDropoff(place);
  }

  Future<void> _confirm() async {
    final nav = Navigator.of(context);
    final id = await _c.confirm();
    if (!mounted) return;
    nav.pushReplacement(MaterialPageRoute(builder: (_) => TripScreen(tripId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(s.t('رحلتك', 'Your trip'))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WSpace.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PlacesHeader(pickup: _c.pickup, dropoff: _c.dropoff, onPickup: () => _change(pickup: true), onDropoff: () => _change(pickup: false)),
              const SizedBox(height: WSpace.lg),
              if (_c.pickup == null)
                Text(s.t('اختر نقطة الانطلاق للمتابعة.', 'Choose your pickup point to continue.'), style: Theme.of(context).textTheme.bodyLarge)
              else ...[
                CategoryStep(selected: _c.category, onSelect: _c.selectCategory, enabled: !_c.drafting),
                const SizedBox(height: WSpace.lg),
                ..._draftSection(context),
              ],
            ]),
          ),
        ),
        bottomNavigationBar: _c.draft == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.sm, WSpace.lg, WSpace.lg),
                  child: PrimaryAction(
                    label: _c.fareValid ? '${s.t('اطلب بسعر', 'Request for')} ${money(_c.fare!, ar: s.ar)}' : s.t('اطلب', 'Request'),
                    onPressed: _c.fareValid ? _confirm : null,
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _draftSection(BuildContext context) {
    final s = context.s;
    if (_c.category == null) return const [];
    if (_c.drafting) {
      return [
        Row(children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: WSpace.md),
          Expanded(child: Text(s.t('نحسب المسار والسعر…', 'Working out the route and price…'))),
        ]),
      ];
    }
    final err = _c.draftError;
    if (err != null) {
      final activeId = err.code == 'invalid_transition' ? err.details['tripId'] as String? : null;
      if (activeId != null) {
        return [
          WBanner(
            tone: Tone.warning,
            text: s.t('لديك رحلة جارية بالفعل.', 'You already have a trip in progress.'),
            actionLabel: s.t('افتحها', 'Open it'),
            onAction: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TripScreen(tripId: activeId))),
          ),
        ];
      }
      return [
        WBanner(tone: Tone.error, text: s.error(err.code, err.message), actionLabel: s.retry, onAction: _c.createDraft),
      ];
    }
    final d = _c.draft;
    if (d == null) return const [];
    return [
      if (_c.priceRefreshed) ...[
        WBanner(tone: Tone.warning, text: s.t('حدّثنا السعر. راجعه ثم أكّد الطلب.', 'We refreshed the price. Check it, then confirm.')),
        const SizedBox(height: WSpace.md),
      ],
      RoutePreview(pickup: _c.pickup!, dropoff: _c.dropoff, route: d.route, quote: d.quote),
      const SizedBox(height: WSpace.xl),
      FareInput(key: ValueKey(d.tripId), quote: d.quote, value: _c.fare, onChanged: _c.setFare),
    ];
  }
}
