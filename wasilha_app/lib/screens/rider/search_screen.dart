import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';
import 'ride_common.dart';

/// 13 — Destination search. Also used to change the pickup point
/// (tap the pickup row).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _editingPickup = false;
  late final Stream<List<Place>> _saved;
  late final Stream<List<Trip>> _trips;

  static const _suggested = [
    ('uofk', 'POPULAR', 'شائع'),
    ('soba', '24H', '٢٤ ساعة'),
    ('afra', 'OPEN', 'مفتوح'),
    ('souq-omdurman', 'MARKET', 'سوق'),
  ];

  @override
  void initState() {
    super.initState();
    final b = context.read<WasilhaBackend>();
    _saved = b.savedPlaces();
    _trips = b.myTrips();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _q => _ctrl.text;

  void _pick(Place p) {
    final s = context.read<AppState>();
    if (_editingPickup) {
      s.setPickup(p);
      setState(() => _editingPickup = false);
      _ctrl.clear();
      _focus.requestFocus();
      return;
    }
    s.setDropoff(p);
    context.swap('booking');
  }

  void _setMode(bool pickup) {
    if (_editingPickup == pickup) return;
    setState(() => _editingPickup = pickup);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Place>>(
          stream: _saved,
          builder: (context, savedSnap) {
            final saved = savedSnap.data ?? const <Place>[];
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _header(s)),
                SliverToBoxAdapter(child: _stopsField(s)),
                SliverToBoxAdapter(child: _quickActions(s, saved)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                  sliver: SliverToBoxAdapter(
                    child: _q.trim().isEmpty ? _browse(s, saved) : _results(s, saved),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _header(AppState s) {
    final title = _editingPickup ? s.t('Pick up from', 'الانطلاق من') : s.t('Where to', 'إلى أين');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 18, 0),
        child: Row(children: [
          TextButton(
            onPressed: () => context.back(),
            child: Text(s.t('Cancel', 'إلغاء'), style: W.sans(size: 13, color: W.text2)),
          ),
          Expanded(
            child: Center(
              child: Text(_editingPickup ? 'PICKUP · الانطلاق' : 'DESTINATION · الوجهة',
                  style: W.mono(size: 10, letterSpacing: 0.3)),
            ),
          ),
          const SizedBox(width: 60),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$title '),
              TextSpan(text: s.ar ? '؟' : '?', style: TextStyle(color: s.accent)),
            ]),
            style: s.ar ? W.arSerif(size: 38) : W.serif(size: 40, letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(
            _editingPickup
                ? s.t('Search for where the driver should meet you.', 'ابحث عن مكان لقاء السائق.')
                : s.t('Search or tap a saved place to begin.', 'ابحث، أو اختر من أماكنك المحفوظة.'),
            style: W.sans(size: 13, color: W.text2),
          ),
        ]),
      ),
    ]);
  }

  // ── Pickup + destination field ──────────────────────────────
  Widget _stopsField(AppState s) {
    final pickupLabel = s.pickup.id == Catalog.defaultPickup.id
        ? s.t('Current location · ${s.pickup.label(false)}', 'الموقع الحالي · ${s.pickup.label(true)}')
        : s.pickup.label(s.ar);
    Widget input(String hint) => TextField(
          controller: _ctrl,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            final r = Catalog.search(_q);
            if (_q.trim().isNotEmpty && r.isNotEmpty) _pick(r.first);
          },
          style: W.sans(size: 15, weight: FontWeight.w500),
          cursorColor: s.accent,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: hint,
            hintStyle: W.sans(size: 15, weight: FontWeight.w500, color: W.text3),
          ),
        );
    Widget clearBtn() => _q.isEmpty
        ? const SizedBox.shrink()
        : GestureDetector(
            onTap: _ctrl.clear,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: W.surface2, shape: BoxShape.circle),
              child: const WIcon('close', size: 12, strokeWidth: 2, color: W.text),
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: W.border, width: 0.5),
            boxShadow: const [BoxShadow(color: Color(0x0D140F1E), blurRadius: 22, offset: Offset(0, 8))],
          ),
          child: Column(children: [
            // Pickup row
            InkWell(
              onTap: () => _setMode(true),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: W.border, width: 0.5))),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: W.success, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MonoLabel(s.t('PICKUP', 'الانطلاق'), size: 8.5),
                      const SizedBox(height: 1),
                      if (_editingPickup)
                        input(s.t('Search pickup point…', 'ابحث عن نقطة الانطلاق…'))
                      else
                        Text(pickupLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: W.sans(size: 13.5, weight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  if (_editingPickup)
                    clearBtn()
                  else
                    GestureDetector(
                      onTap: () => s.setPickup(Catalog.defaultPickup),
                      child: const WIcon('target', size: 14, color: W.text3),
                    ),
                ]),
              ),
            ),
            // Destination row
            InkWell(
              onTap: () => _setMode(false),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: s.accent, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingPickup
                        ? Text(
                            s.dropoff?.label(s.ar) ?? s.t('Search place or district…', 'ابحث عن موقع أو حي…'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: W.sans(
                                size: 15, weight: FontWeight.w500, color: s.dropoff == null ? W.text3 : W.text),
                          )
                        : input(s.t('Search place or district…', 'ابحث عن موقع أو حي…')),
                  ),
                  if (!_editingPickup) clearBtn(),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => comingSoon(context, s, s.t('Multi-stop trips', 'الرحلات متعددة المحطات')),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: W.border2, width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const WIcon('plus', size: 13, strokeWidth: 2, color: W.text2),
              const SizedBox(width: 8),
              Text(s.t('Add a stop', 'إضافة محطة'), style: W.sans(size: 12.5, color: W.text2)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Home / Work / Airport / Add ─────────────────────────────
  Widget _quickActions(AppState s, List<Place> saved) {
    Place? byKind(String k) {
      for (final p in saved) {
        if (p.kind == k) return p;
      }
      return null;
    }

    final airport = Catalog.places.firstWhere((p) => p.id == 'airport');
    final items = [
      ('home', s.t('Home', 'المنزل'), byKind('home'), 'home'),
      ('work', s.t('Work', 'العمل'), byKind('work'), 'work'),
      ('plane', s.t('Airport', 'المطار'), airport, 'airport'),
      ('plus', s.t('Add', 'إضافة'), null, 'add'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickBtn(
              icon: items[i].$1,
              label: items[i].$2,
              dashed: items[i].$4 == 'add',
              onTap: () {
                final p = items[i].$3;
                if (p != null) return _pick(p);
                if (items[i].$4 == 'add') {
                  context.go('saved');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: W.text,
                    content: Text(s.t('No ${items[i].$2.toLowerCase()} address saved yet.',
                        'لم تحفظ عنوان ${items[i].$2} بعد.')),
                    action: SnackBarAction(
                      label: s.t('Add', 'إضافة'),
                      textColor: Colors.white,
                      onPressed: () => context.go('saved'),
                    ),
                  ));
                }
              },
            ),
          ),
        ],
      ]),
    );
  }

  // ── Empty query: saved / recent / suggested ─────────────────
  Widget _browse(AppState s, List<Place> saved) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (saved.isNotEmpty) ...[
        _SectionLabel(s.t('SAVED', 'المحفوظة')),
        _ListCard(children: [
          for (final p in saved)
            _PlaceRow(
              icon: p.kind == 'home' ? 'home' : (p.kind == 'work' ? 'work' : 'pin'),
              tinted: true,
              title: p.label(s.ar),
              detail: p.area.isEmpty ? distanceDetail(s, s.pickup.kmTo(p)) : p.area,
              onTap: () => _pick(p),
            ),
        ]),
        const SizedBox(height: 18),
      ],
      StreamBuilder<List<Trip>>(
        stream: _trips,
        builder: (context, snap) {
          final seen = <String>{};
          final recent = <Place>[];
          for (final t in snap.data ?? const <Trip>[]) {
            final key = '${t.dropoff.lat.toStringAsFixed(4)},${t.dropoff.lng.toStringAsFixed(4)}';
            if (seen.add(key)) recent.add(t.dropoff);
            if (recent.length == 3) break;
          }
          if (recent.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel(s.t('RECENT', 'الأخيرة')),
            for (final p in recent)
              _PlaceRow(
                icon: 'history',
                plainIcon: true,
                title: p.label(s.ar),
                detail: [if (p.area.isNotEmpty) p.area, distanceDetail(s, s.pickup.kmTo(p))].join(' · '),
                onTap: () => _pick(p),
                showArrow: false,
                divider: true,
              ),
            const SizedBox(height: 22),
          ]);
        },
      ),
      _SectionLabel(s.t('SUGGESTED', 'مقترحة لك'), bottom: 10),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (id, tag, tagAr) in _suggested)
            if (Catalog.places.any((p) => p.id == id))
              SizedBox(
                width: w,
                child: _SuggestCard(
                  place: Catalog.places.firstWhere((p) => p.id == id),
                  tag: s.t(tag, tagAr),
                  detail: distanceDetail(s, s.pickup.kmTo(Catalog.places.firstWhere((p) => p.id == id))),
                  onTap: () => _pick(Catalog.places.firstWhere((p) => p.id == id)),
                ),
              ),
        ]);
      }),
    ]);
  }

  // ── Typed query: live results ───────────────────────────────
  Widget _results(AppState s, List<Place> saved) {
    final q = _q.trim().toLowerCase();
    final savedHits = saved.where((p) =>
        p.name.toLowerCase().contains(q) || p.nameAr.contains(_q.trim()) || p.area.toLowerCase().contains(q));
    final results = <Place>[...savedHits, ...Catalog.search(_q)];
    final seen = <String>{};
    final unique = results.where((p) => seen.add('${p.kind}:${p.id}')).take(8).toList();
    if (unique.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Column(children: [
            const WIcon('search', size: 22, color: W.text3),
            const SizedBox(height: 10),
            Text(s.t('No places match “${_q.trim()}”', 'لا توجد أماكن تطابق «${_q.trim()}»'),
                textAlign: TextAlign.center, style: W.sans(size: 13, color: W.text2)),
          ]),
        ),
      );
    }
    return _ListCard(children: [
      for (final p in unique)
        _PlaceRow(
          icon: p.kind == 'home' ? 'home' : (p.kind == 'work' ? 'work' : 'pin'),
          title: p.label(s.ar),
          detail: [if (p.area.isNotEmpty) p.area, distanceDetail(s, s.pickup.kmTo(p))].join(' · '),
          onTap: () => _pick(p),
        ),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.bottom = 8});
  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(bottom: bottom), child: MonoLabel(text, size: 9.5, spacing: 0.3));
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: W.border, width: 0.5),
      ),
      child: Column(children: [
        for (var i = 0; i < children.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i < children.length - 1
                  ? const Border(bottom: BorderSide(color: W.border, width: 0.5))
                  : null,
            ),
            child: children[i],
          ),
      ]),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.tinted = false,
    this.plainIcon = false,
    this.showArrow = true,
    this.divider = false,
  });
  final String icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool tinted;
  final bool plainIcon;
  final bool showArrow;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: divider
            ? const BoxDecoration(border: Border(bottom: BorderSide(color: W.border, width: 0.5)))
            : null,
        child: Row(children: [
          if (plainIcon)
            WIcon(icon, size: 16, strokeWidth: 1.7, color: W.text3)
          else
            Container(
              width: tinted ? 36 : 34,
              height: tinted ? 36 : 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tinted ? accent.withValues(alpha: 0.08) : W.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: WIcon(icon, size: tinted ? 16 : 14, strokeWidth: 1.7, color: tinted ? accent : W.text),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 13.5, weight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: W.text2)),
            ]),
          ),
          if (showArrow) const WIcon('arrow', size: 14, color: W.text3),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({required this.icon, required this.label, required this.onTap, this.dashed = false});
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final fg = dashed ? W.text2 : W.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: dashed ? Border.all(color: W.border2, width: 0.5) : null,
          boxShadow: dashed ? null : const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(children: [
          WIcon(icon, size: 16, strokeWidth: 1.7, color: fg),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11, color: fg)),
        ]),
      ),
    );
  }
}

class _SuggestCard extends StatelessWidget {
  const _SuggestCard({required this.place, required this.tag, required this.detail, required this.onTap});
  final Place place;
  final String tag;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ar = context.watch<AppState>().ar;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(9)),
              child: const WIcon('pin', size: 14, strokeWidth: 1.7, color: W.text),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(999)),
              child: Text(tag,
                  style: ar ? W.ar(size: 9, color: Colors.white) : W.mono(size: 8, color: Colors.white, letterSpacing: 0.18)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(place.label(ar),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 12.5, weight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 10.5, color: W.text2)),
        ]),
      ),
    );
  }
}
