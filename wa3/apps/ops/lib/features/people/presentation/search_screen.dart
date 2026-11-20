import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../trips/presentation/trip_tile.dart';
import '../application/search.dart';
import 'driver_profile_screen.dart';

/// Global search: trip id, rider/driver id, or exact phone number.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _q = TextEditingController(text: widget.initialQuery ?? '');
  Future<SearchResults>? _results;
  String _searched = '';

  @override
  void initState() {
    super.initState();
    if ((widget.initialQuery ?? '').trim().isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _search() {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    final services = context.services;
    setState(() {
      _searched = q;
      _results = searchEverything(q, people: services.people, trips: services.trips);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PageBody(children: [
      TextField(
        controller: _q,
        autofocus: true,
        textInputAction: TextInputAction.search,
        textDirection: TextDirection.ltr,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          labelText: s.t('معرّف رحلة أو راكب أو سائق، أو رقم هاتف كامل', 'Trip, rider or driver id, or full phone number'),
          helperText: s.t('مطابقة تامة فقط. الهاتف بالصيغة الدولية مثل ‎+2499…', 'Exact match only. Phone in international form, e.g. +2499…'),
          suffixIcon: IconButton(tooltip: s.t('بحث', 'Search'), icon: const Icon(Icons.search), onPressed: _search),
        ),
      ),
      const SizedBox(height: WSpace.lg),
      if (_results != null)
        FutureBuilder<SearchResults>(
          future: _results,
          builder: (context, snap) {
            if (snap.hasError) return opsErrorView(context, snap.error!, onRetry: _search);
            if (!snap.hasData) return WStateView.loading(label: s.t('نبحث…', 'Searching…'));
            final r = snap.data!;
            final now = context.services.now();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final f in r.failures.take(1)) WBanner(tone: Tone.error, text: describeFailure(s, f)),
              if (r.isEmpty && r.failures.isEmpty)
                WStateView.empty(icon: Icons.search_off, title: s.t('لا نتائج مطابقة تماماً لـ «${ltr(_searched)}»', 'Nothing matches “${ltr(_searched)}” exactly')),
              if (r.trip != null) ...[SectionTitle(s.t('رحلة', 'Trip')), TripTile(record: r.trip!, now: now)],
              if (r.riders.isNotEmpty) SectionTitle(s.t('ركاب', 'Riders')),
              for (final x in r.riders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(x.name.isEmpty ? ltr(x.uid) : x.name),
                  subtitle: Text('${ltr(x.phone)} · ${ltr(shortId(x.uid))}'),
                  onTap: () => openRider(context, x.uid),
                ),
              if (r.drivers.isNotEmpty) SectionTitle(s.t('سائقون', 'Drivers')),
              for (final d in r.drivers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(d.name.isEmpty ? ltr(d.uid) : d.name),
                  subtitle: Text('${ltr(d.phone)} · ${driverStatusLabel(s, d.status)}'),
                  onTap: () => openDriver(context, d.uid),
                ),
            ]);
          },
        ),
    ]);
  }
}
