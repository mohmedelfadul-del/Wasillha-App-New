import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/deps.dart';
import '../../common/presentation/map_surface.dart';

/// Drag the map under a fixed centre pin; the server names the point (`placeLabel`).
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, required this.title, required this.initial, this.isPickup = false});
  final String title;
  final GeoPoint initial;
  final bool isPickup;
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GeoPoint _center = widget.initial;
  String? _label;
  Object? _error;
  bool _moving = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolve(_center);
    });
  }

  Future<void> _resolve(GeoPoint p) async {
    final seq = ++_seq;
    setState(() {
      _moving = false;
      _label = null;
      _error = null;
    });
    try {
      final l = await context.deps.places.label(p, lang: context.s.lang);
      if (mounted && seq == _seq) setState(() => _label = l);
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final pinColor = widget.isPickup ? MapColors.pickup : MapColors.dropoff;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Expanded(
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
              child: context.deps.map(
                context,
                MapSpec(
                  center: widget.initial,
                  zoom: 16,
                  semanticLabel: s.t('خريطة. حرّكها لوضع الدبوس على المكان المطلوب.', 'Map. Move it to place the pin on the spot you want.'),
                  onCameraMove: (p) {
                    _center = p;
                    if (!_moving) {
                      setState(() {
                        _moving = true;
                        _seq++;
                      });
                    }
                  },
                  onCameraIdle: (p) => _resolve(p),
                ),
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, size: 48, color: pinColor, semanticLabel: s.t('الدبوس', 'Pin')),
              ),
            ),
          ]),
        ),
        Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(WSpace.lg),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Semantics(liveRegion: true, child: _labelView(context)),
                const SizedBox(height: WSpace.md),
                PrimaryAction(
                  label: s.t('استخدم هذا الموقع', 'Use this location'),
                  onPressed: _label == null || _moving ? null : () async => Navigator.of(context).pop(Place(point: _center, label: _label!)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _labelView(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    if (_error != null) {
      return Row(children: [
        const Icon(Icons.error_outline, color: WColors.error),
        const SizedBox(width: WSpace.sm),
        Expanded(child: Text(s.error(_error is ApiFailure ? (_error as ApiFailure).code : 'internal'))),
        TextButton(onPressed: () => _resolve(_center), child: Text(s.retry)),
      ]);
    }
    if (_label == null) {
      return Text(_moving ? s.t('اترك الخريطة لتحديد العنوان', 'Release the map to get the address') : s.t('جارٍ تحديد العنوان…', 'Finding the address…'),
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Text(_label!, style: theme.textTheme.titleMedium);
  }
}
