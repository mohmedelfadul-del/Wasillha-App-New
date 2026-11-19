import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Send a parcel: pickup / drop-off, size, recipient → shared OfferScreen
/// (which creates the parcel trip and collects courier bids).
class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key});

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  String _size = 's';
  Place? _drop;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final d = s.dropoff;
    if (d != null && d.id != s.pickup.id) _drop = d;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<Place?> _pick({required bool pickup}) {
    final s = context.read<AppState>();
    final exclude = pickup ? _drop?.id : s.pickup.id;
    return showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacePicker(
        title: pickup ? s.t('Pickup from', 'الاستلام من') : s.t('Deliver to', 'التوصيل إلى'),
        exclude: exclude,
      ),
    );
  }

  void _confirm() {
    final s = context.read<AppState>();
    final d = _drop;
    String? err;
    if (d == null) {
      err = s.t('Choose a drop-off location', 'اختر موقع التسليم');
    } else if (_name.text.trim().isEmpty) {
      err = s.t("Enter the recipient's name", 'أدخل اسم المستلم');
    } else if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      err = s.t("Enter the recipient's phone number", 'أدخل رقم هاتف المستلم');
    }
    if (err != null) {
      showError(context, err);
      return;
    }
    final size = _sizes(s).firstWhere((x) => x.$1 == _size);
    final note = [
      'Parcel: ${size.$2}',
      'To: ${_name.text.trim()} (${_phone.text.trim()})',
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
    ].join(' · ');
    s.chooseService(ServiceType.parcel);
    s.setDropoff(d!);
    context.go('offer', args: {'note': note});
  }

  List<(String, String, String)> _sizes(AppState s) => [
        ('xs', s.t('Envelope', 'ظرف'), s.t('Docs · <1kg', 'وثائق · أقل من ١ كجم')),
        ('s', s.t('Small box', 'صندوق صغير'), s.t('Handbag · 1–5kg', 'حقيبة · ١–٥ كجم')),
        ('m', s.t('Large box', 'صندوق كبير'), s.t('Suitcase · 5–15kg', 'شنطة سفر · ٥–١٥ كجم')),
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final km = _drop == null ? null : s.pickup.kmTo(_drop!);
    final price = km == null ? null : ServiceType.parcel.fareFor(km);

    return Scaffold(
      backgroundColor: W.screenBg,
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, top + 14, 18, 24),
            children: [
              // Top bar
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => context.back(),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: W.border, width: 0.5),
                    ),
                    child: const WIcon('back', size: 17, strokeWidth: 1.7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel(s.t('S-03 · Courier', 'توصيل طرود'), size: 9.5),
                    const SizedBox(height: 2),
                    Text(s.t('Send a parcel', 'إرسال طرد'), style: W.serif(size: 22, height: 1.05)),
                    const SizedBox(height: 2),
                    Text(s.t('A driver picks up from your door', 'سيستلمه السائق من بابك'),
                        style: W.sans(size: 11.5, color: W.text2)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),

              // From → To
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: W.border, width: 0.5),
                  boxShadow: const [BoxShadow(color: Color(0x0A140F1E), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Row(children: [
                  Column(children: [
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: W.success, shape: BoxShape.circle)),
                    const SizedBox(height: 4),
                    Container(width: 1.5, height: 30, color: W.border2),
                    const SizedBox(height: 4),
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(children: [
                      _PlaceRow(
                        label: s.t('From', 'من'),
                        value: s.pickup.label(s.ar),
                        divider: true,
                        onTap: () async {
                          final p = await _pick(pickup: true);
                          if (p != null) s.setPickup(p);
                        },
                      ),
                      _PlaceRow(
                        label: s.t('To', 'إلى'),
                        value: _drop?.label(s.ar),
                        placeholder: s.t('Choose drop-off', 'اختر موقع التسليم'),
                        onTap: () async {
                          final p = await _pick(pickup: false);
                          if (p != null) setState(() => _drop = p);
                        },
                      ),
                    ]),
                  ),
                ]),
              ),

              // Sizes
              const SizedBox(height: 18),
              MonoLabel(s.t('Package size', 'الحجم'), size: 9.5),
              const SizedBox(height: 8),
              // Equal-height cards without IntrinsicHeight (which mis-measures wrapped Arabic text).
              Builder(
                builder: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final (id, label, sub) in _sizes(s)) ...[
                    if (id != 'xs') const SizedBox(width: 8),
                    Expanded(
                      child: _SizeCard(
                        label: label,
                        sub: sub,
                        active: id == _size,
                        onTap: () => setState(() => _size = id),
                      ),
                    ),
                  ],
                ]),
              ),

              // Receiver
              const SizedBox(height: 18),
              MonoLabel(s.t('Receiver', 'المستلم'), size: 9.5),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: W.border, width: 0.5),
                ),
                child: Column(children: [
                  _Field(
                    icon: 'user',
                    controller: _name,
                    hint: s.t('Name', 'الاسم'),
                    divider: true,
                    action: TextInputAction.next,
                  ),
                  _Field(
                    icon: 'phone',
                    controller: _phone,
                    hint: s.t('Phone · +249 9X XXX XXXX', 'الهاتف · +249 9X XXX XXXX'),
                    keyboard: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                    action: TextInputAction.next,
                  ),
                ]),
              ),

              // Notes
              const SizedBox(height: 18),
              MonoLabel(s.t('Driver notes', 'ملاحظات للسائق'), size: 9.5),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 3,
                style: W.sans(size: 13),
                decoration: InputDecoration(
                  hintText: s.t('e.g. call on arrival', 'مثال: اتصل عند الوصول'),
                  hintStyle: W.sans(size: 13, color: W.text3),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: W.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom bar
        Container(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottom),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x00FBFAF6), W.screenBg],
              stops: [0, 0.3],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: W.border, width: 0.5),
              ),
              child: Row(children: [
                MonoLabel(s.t('Estimate', 'تقدير'), size: 9.5),
                if (km != null) ...[
                  const SizedBox(width: 8),
                  Text('· ${km.toStringAsFixed(1)} km', style: W.mono(size: 10, color: W.text2)),
                ],
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(price == null ? '—' : sdg(price), style: W.serif(size: 24, height: 1)),
                  const SizedBox(width: 4),
                  MonoLabel(s.t('SDG', 'ج.س'), size: 10, spacing: 0.2),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            Btn(s.t('Find a courier', 'ابحث عن كابتن'), full: true, icon: 'arrow', onTap: _confirm),
          ]),
        ),
      ]),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.label, required this.value, required this.onTap, this.placeholder, this.divider = false});
  final String label;
  final String? value;
  final String? placeholder;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(top: divider ? 0 : 8, bottom: divider ? 8 : 0),
        decoration: BoxDecoration(
          border: divider ? const Border(bottom: BorderSide(color: W.border, width: 0.5)) : null,
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(label, size: 8.5),
              const SizedBox(height: 1),
              Text(
                value ?? placeholder ?? '',
                overflow: TextOverflow.ellipsis,
                style: W.sans(size: 13.5, weight: FontWeight.w500, color: value == null ? W.text3 : W.text),
              ),
            ]),
          ),
          const WIcon('chevDown', size: 14, color: W.text3),
        ]),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({required this.label, required this.sub, required this.active, required this.onTap});
  final String label;
  final String sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        constraints: const BoxConstraints(minHeight: 104),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? accent : W.border, width: active ? 1.5 : 0.5),
          boxShadow: active ? [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 22, offset: const Offset(0, 8))] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? accent.withValues(alpha: 0.13) : W.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: WIcon('bag', size: 15, strokeWidth: 1.7, color: active ? accent : W.text),
          ),
          const SizedBox(height: 8),
          Text(label, style: W.sans(size: 12.5, weight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(sub, style: W.sans(size: 10.5, color: W.text2)),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.controller,
    required this.hint,
    this.divider = false,
    this.keyboard,
    this.formatters,
    this.action,
  });
  final String icon;
  final TextEditingController controller;
  final String hint;
  final bool divider;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextInputAction? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: W.border, width: 0.5)) : null,
      ),
      child: Row(children: [
        WIcon(icon, size: 16, strokeWidth: 1.7, color: W.text3),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            inputFormatters: formatters,
            textInputAction: action,
            style: W.sans(size: 13.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintText: hint,
              hintStyle: W.sans(size: 13.5, color: W.text3),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Bottom-sheet list of known places (Catalog.places) with search.
class _PlacePicker extends StatefulWidget {
  const _PlacePicker({required this.title, this.exclude});
  final String title;
  final String? exclude;

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final places = Catalog.search(_q).where((p) => p.id != widget.exclude).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        decoration: const BoxDecoration(
          color: W.screenBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(widget.title, style: W.serif(size: 26)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: W.sans(size: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: s.t('Search places', 'ابحث عن مكان'),
                hintStyle: W.sans(size: 14, color: W.text3),
                prefixIcon: const Padding(padding: EdgeInsets.all(12), child: WIcon('search', size: 16, color: W.text3)),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: W.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: s.accent, width: 1),
                ),
              ),
            ),
          ),
          Flexible(
            child: places.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(s.t('No places found', 'لا توجد نتائج'),
                        textAlign: TextAlign.center, style: W.sans(size: 13, color: W.text2)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
                    itemCount: places.length,
                    itemBuilder: (_, i) {
                      final p = places[i];
                      return WRow(
                        icon: 'pin',
                        title: p.label(s.ar),
                        detail: p.area,
                        onTap: () => Navigator.of(context).pop(p),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
