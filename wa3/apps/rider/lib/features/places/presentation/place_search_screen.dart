import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../domain/places_repository.dart';
import 'map_picker_screen.dart';

/// Search a place through the server (`placesSearch`) or pick it on the map.
/// Pops with the chosen [Place].
class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key, required this.title, required this.near, this.currentLocation, this.pinKindIsPickup = false});
  final String title;
  final GeoPoint near;

  /// When set, offers "Use my current location" (pickup).
  final GeoPoint? currentLocation;
  final bool pinKindIsPickup;

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  int _seq = 0;
  bool _loading = false;
  Object? _error;
  List<PlaceSuggestion>? _results;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _seq++;
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.length < 2) return;
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.deps.places.search(q, near: widget.near, lang: context.s.lang);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickOnMap() async {
    final place = await Navigator.of(context).push<Place>(MaterialPageRoute(
      builder: (_) => MapPickerScreen(title: widget.title, initial: widget.currentLocation ?? widget.near, isPickup: widget.pinKindIsPickup),
    ));
    if (place != null && mounted) Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(WSpace.lg, WSpace.sm, WSpace.lg, WSpace.sm),
            child: TextField(
              controller: _q,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.t('ابحث عن مكان أو عنوان', 'Search a place or address'),
              ),
              onChanged: _onChanged,
              onSubmitted: (_) => _search(),
            ),
          ),
          if (widget.currentLocation != null)
            ListTile(
              leading: const Icon(Icons.my_location, color: MapColors.pickup),
              title: Text(s.t('موقعي الحالي', 'My current location')),
              onTap: () => Navigator.of(context).pop(Place(point: widget.currentLocation!, label: '')),
            ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(s.t('اختر على الخريطة', 'Choose on the map')),
            onTap: _pickOnMap,
          ),
          const Divider(),
          Expanded(child: _body(context)),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final s = context.s;
    if (_loading) return WStateView.loading(label: s.t('جارٍ البحث…', 'Searching…'));
    if (_error != null) return WStateView.error(context, _error!, onRetry: _search);
    final r = _results;
    if (r == null) {
      return WStateView.empty(icon: Icons.travel_explore, title: s.t('اكتب حرفين على الأقل للبحث', 'Type at least 2 letters to search'));
    }
    if (r.isEmpty) {
      return WStateView.empty(
        icon: Icons.search_off,
        title: s.t('لا توجد نتائج', 'No places found'),
        body: s.t('جرّب اسماً آخر أو اختر المكان على الخريطة.', 'Try another name or choose the place on the map.'),
        actionLabel: s.t('اختر على الخريطة', 'Choose on the map'),
        onAction: _pickOnMap,
      );
    }
    return ListView.separated(
      itemCount: r.length,
      separatorBuilder: (_, _) => const Divider(indent: WSpace.lg, endIndent: WSpace.lg),
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.place_outlined),
        title: Text(r[i].label.isNotEmpty ? r[i].label : r[i].address),
        subtitle: r[i].label.isNotEmpty && r[i].address.isNotEmpty ? Text(r[i].address) : null,
        onTap: () => Navigator.of(context).pop(r[i].toPlace()),
      ),
    );
  }
}
