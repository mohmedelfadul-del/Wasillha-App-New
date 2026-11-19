import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/map_view.dart';
import '../../widgets/w_icon.dart';
import 'account_common.dart';

String _kindIcon(String kind) => switch (kind) {
      'home' => 'home',
      'work' => 'work',
      _ => 'pin',
    };

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<List<Place>> _places = _backend.savedPlaces();

  Future<void> _delete(Place p) async {
    try {
      await _backend.deletePlace(p.id);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _use(Place p) {
    context.read<AppState>().setDropoff(p);
    context.go('booking');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: W.screenBg,
      body: SafeArea(
        child: StreamBuilder<List<Place>>(
          stream: _places,
          builder: (context, snap) {
            final list = snap.data;
            final sorted = [...?list]..sort((a, b) => _rank(a.kind).compareTo(_rank(b.kind)));
            return ListView(
              padding: const EdgeInsets.only(bottom: 60),
              children: [
                AccountHeader(
                  title: s.t('SAVED PLACES', 'الأماكن المحفوظة'),
                  trailing: GestureDetector(
                    onTap: () => showAddPlaceSheet(context, _backend),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: s.accent.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const WIcon('plus', size: 18, strokeWidth: 1.8, color: Colors.white),
                    ),
                  ),
                ),
                _MapPreview(count: sorted.length),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SerifHeadline(s.t('Your ', 'اختصاراتك '), s.t('shortcuts.', 'السريعة.'), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      s.t("Save the places you go most. We'll surface them as one-tap options on the home screen.",
                          'احفظ الأماكن التي تزورها كثيرًا وسنعرضها كخيارات بلمسة واحدة في الشاشة الرئيسية.'),
                      style: W.sans(size: 13, color: W.text2, height: 1.5),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 0),
                  child: list == null
                      ? const Loading()
                      : sorted.isEmpty
                          ? ListCard(children: [
                              EmptyNote(icon: 'pin', text: s.t('No saved places yet — tap + to add one.', 'لا توجد أماكن محفوظة — اضغط + للإضافة.')),
                            ])
                          : ListCard(children: [
                              for (var i = 0; i < sorted.length; i++)
                                Dismissible(
                                  key: ValueKey(sorted[i].id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: AlignmentDirectional.centerEnd,
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: Text(s.t('Delete', 'حذف'), style: W.sans(size: 13, weight: FontWeight.w500, color: W.danger)),
                                  ),
                                  onDismissed: (_) => _delete(sorted[i]),
                                  child: _PlaceRow(
                                    p: sorted[i],
                                    last: i == sorted.length - 1,
                                    onTap: () => _use(sorted[i]),
                                    onDelete: () => _delete(sorted[i]),
                                  ),
                                ),
                            ]),
                ),
                if (sorted.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(child: MonoLabel(s.t('SWIPE TO DELETE · TAP TO RIDE', 'اسحب للحذف · اضغط للحجز'), size: 9)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _rank(String kind) => switch (kind) { 'home' => 0, 'work' => 1, _ => 2 };
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    const pins = [(0.24, 0.36, false), (0.62, 0.58, true), (0.28, 0.74, false), (0.70, 0.24, false)];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 0),
      child: Container(
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x14140F1E), blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: LayoutBuilder(
          builder: (context, c) => Stack(children: [
            const Positioned.fill(child: IgnorePointer(child: WMap(drivers: 0))),
            for (final (x, y, accent) in pins.take(count.clamp(0, pins.length)))
              Positioned(
                left: c.maxWidth * x - 7,
                top: c.maxHeight * y - 7,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent ? s.accent : W.text,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                ),
              ),
            PositionedDirectional(
              top: 12,
              start: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xD9FFFFFF), borderRadius: BorderRadius.circular(999)),
                child: MonoLabel(s.t('$count PLACES', '$count أماكن'), size: 9, spacing: 0.24),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.p, required this.last, required this.onTap, required this.onDelete});
  final Place p;
  final bool last;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final primary = p.kind == 'home';
    final kindTitle = switch (p.kind) {
      'home' => s.t('Home', 'البيت'),
      'work' => s.t('Work', 'العمل'),
      _ => null,
    };
    final placeName = p.label(s.ar);
    final title = kindTitle ?? placeName;
    final generic = {'home', 'work', 'البيت', 'العمل'}.contains(placeName.toLowerCase());
    final detail = kindTitle == null
        ? p.area
        : (generic ? p.area : [placeName, if (p.area.isNotEmpty) p.area].join(' · '));
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: W.border, width: 0.5))),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? s.accent.withValues(alpha: 0.08) : W.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: WIcon(_kindIcon(p.kind), size: 18, strokeWidth: 1.7, color: primary ? s.accent : W.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 14, weight: FontWeight.w500)),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: W.text2)),
              ],
            ]),
          ),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: WIcon('close', size: 14, color: W.text3),
            ),
          ),
          const WIcon('chevron', size: 14, color: W.text3),
        ]),
      ),
    );
  }
}

/// Bottom sheet: pick a kind (home / work / other) and a place from the catalog.
void showAddPlaceSheet(BuildContext context, WasilhaBackend backend) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _AddPlaceSheet(backend: backend),
  );
}

class _AddPlaceSheet extends StatefulWidget {
  const _AddPlaceSheet({required this.backend});
  final WasilhaBackend backend;

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  String _kind = 'other';
  String _q = '';
  String? _saving;

  Future<void> _save(Place p) async {
    final s = context.read<AppState>();
    setState(() => _saving = p.id);
    // Home and work are singletons: re-saving replaces the previous one.
    final id = _kind == 'other' ? 'saved-${p.id}' : _kind;
    try {
      await widget.backend.savePlace(Place(
        id: id,
        name: p.name,
        nameAr: p.nameAr,
        area: p.area,
        lat: p.lat,
        lng: p.lng,
        kind: _kind,
      ));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(s.t('Saved ${p.name}', 'تم حفظ ${p.label(true)}')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: W.text,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = null);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final results = Catalog.search(_q);
    final kinds = [
      ('home', 'home', s.t('Home', 'البيت')),
      ('work', 'work', s.t('Work', 'العمل')),
      ('other', 'pin', s.t('Other', 'آخر')),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MonoLabel(s.t('ADD A PLACE', 'إضافة مكان'), spacing: 0.3),
                const SizedBox(height: 8),
                SerifHeadline(s.t('Save a ', 'احفظ '), s.t('shortcut.', 'اختصارًا.'), size: 30),
                const SizedBox(height: 16),
                Row(children: [
                  for (final (id, icon, label) in kinds) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _kind = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _kind == id ? s.accent.withValues(alpha: 0.06) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kind == id ? s.accent : W.border, width: _kind == id ? 1.5 : 0.5),
                          ),
                          child: Column(children: [
                            WIcon(icon, size: 18, strokeWidth: 1.7, color: _kind == id ? s.accent : W.text),
                            const SizedBox(height: 4),
                            Text(label, style: W.sans(size: 12, weight: FontWeight.w500, color: _kind == id ? s.accent : W.text)),
                          ]),
                        ),
                      ),
                    ),
                    if (id != 'other') const SizedBox(width: 8),
                  ],
                ]),
                const SizedBox(height: 14),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const WIcon('search', size: 16, color: W.text3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        cursorColor: s.accent,
                        style: W.sans(size: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: s.t('Search Khartoum places', 'ابحث عن مكان في الخرطوم'),
                          hintStyle: W.sans(size: 14, color: W.text3),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final p = results[i];
                  return WRow(
                    icon: 'pin',
                    title: p.label(s.ar),
                    detail: p.area,
                    divider: i < results.length - 1,
                    onTap: _saving == null ? () => _save(p) : null,
                    trailing: _saving == p.id
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: s.accent))
                        : const WIcon('plus', size: 16, color: W.text3),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
