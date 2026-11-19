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
import 'food_order_view.dart';
import 'food_widgets.dart';

/// Food delivery: restaurant list → restaurant menu with floating cart →
/// checkout → live order status.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  Restaurant? _r;
  final Map<String, int> _cart = {};
  String? _cat;
  String? _orderId;
  bool _placing = false;
  final Set<String> _favs = {};

  int get _count => _cart.values.fold(0, (a, b) => a + b);
  int _subtotal(Restaurant r) => r.menu.fold(0, (sum, m) => sum + (_cart[m.id] ?? 0) * m.price);

  void _open(Restaurant r) {
    setState(() {
      if (_r?.id != r.id) _cart.clear();
      _r = r;
      _cat = null;
    });
  }

  void _inc(MenuItem m) => setState(() => _cart[m.id] = (_cart[m.id] ?? 0) + 1);
  void _dec(MenuItem m) => setState(() {
        final q = (_cart[m.id] ?? 0) - 1;
        if (q <= 0) {
          _cart.remove(m.id);
        } else {
          _cart[m.id] = q;
        }
      });

  Future<void> _checkout(Restaurant r) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(restaurant: r, cart: Map.of(_cart)),
    );
    if (ok != true || !mounted) return;
    final backend = context.read<WasilhaBackend>();
    final s = context.read<AppState>();
    final lines = [
      for (final m in r.menu)
        if ((_cart[m.id] ?? 0) > 0) OrderLine(name: m.name, qty: _cart[m.id]!, price: m.price),
    ];
    setState(() => _placing = true);
    try {
      final id = await backend.placeFoodOrder(restaurant: r, lines: lines, total: _subtotal(r) + r.deliveryFee);
      s.activeOrderId = id;
      if (mounted) {
        setState(() {
          _orderId = id;
          _cart.clear();
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return PopScope(
      canPop: r == null || _orderId != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _r = null);
      },
      child: Scaffold(
        backgroundColor: W.screenBg,
        body: _orderId != null && r != null
            ? FoodOrderView(orderId: _orderId!, restaurant: r)
            : r == null
                ? _list(context)
                : _menu(context, r),
      ),
    );
  }

  // ── Restaurant list ───────────────────────────────────────
  Widget _list(BuildContext context) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, top + 12, 18, 40),
      children: [
        Row(children: [
          _HeaderBtn(icon: 'back', onTap: () => context.back()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(s.t('S-04 · Food', 'أكل'), size: 9.5),
              const SizedBox(height: 2),
              Text(s.t('Order food', 'اطلب أكل'), style: W.serif(size: 26)),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Text(s.t('Kitchens near ${s.pickup.label(false)} · paid from your wallet',
                'مطاعم قريبة من ${s.pickup.label(true)} · الدفع من المحفظة'),
            style: W.sans(size: 12, color: W.text2)),
        const SizedBox(height: 18),
        for (var i = 0; i < Catalog.restaurants.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RestaurantCard(r: Catalog.restaurants[i], index: i, onTap: () => _open(Catalog.restaurants[i])),
          ),
      ],
    );
  }

  // ── Restaurant page ───────────────────────────────────────
  Widget _menu(BuildContext context, Restaurant r) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final idx = Catalog.restaurants.indexWhere((x) => x.id == r.id);
    final grad = foodHeroGradients[(idx < 0 ? 0 : idx) % foodHeroGradients.length];
    final cats = <String>{for (final m in r.menu) m.category}.where((c) => c.isNotEmpty).toList();
    final items = _cat == null ? r.menu : r.menu.where((m) => m.category == _cat).toList();
    final fav = _favs.contains(r.id);
    return Stack(children: [
      CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              height: 240 + top - 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad, stops: const [0, 0.55, 1], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Stack(children: [
                const Positioned.fill(child: FoodGrain()),
                PositionedDirectional(
                  top: top + 6,
                  start: 16,
                  end: 16,
                  child: Row(children: [
                    _HeaderBtn(icon: 'back', translucent: true, onTap: () => setState(() => _r = null)),
                    const Spacer(),
                    _HeaderBtn(
                      icon: 'star',
                      translucent: true,
                      color: fav ? W.gold : W.text,
                      onTap: () => setState(() => fav ? _favs.remove(r.id) : _favs.add(r.id)),
                    ),
                  ]),
                ),
                PositionedDirectional(
                  start: 18,
                  end: 18,
                  bottom: 34,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MonoLabel('S-04 · ${s.t('Food', 'أكل')}', color: const Color(0xB3FBFAF6), spacing: 0.28),
                    const SizedBox(height: 6),
                    Text(r.label(s.ar), style: W.serif(size: 34, color: W.screenBg, height: 1.05)),
                    const SizedBox(height: 4),
                    Text('${r.cuisine} · ${r.place.area}', style: W.sans(size: 12.5, color: const Color(0xD9FBFAF6))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: W.border, width: 0.5),
                boxShadow: const [BoxShadow(color: Color(0x1A140F1E), blurRadius: 32, offset: Offset(0, 14))],
              ),
              child: Row(children: [
                FoodStat(first: true, label: s.t('Rating', 'تقييم'), value: r.rating.toStringAsFixed(1), sub: '★'),
                FoodStat(label: s.t('Delivery', 'توصيل'), value: '${r.etaMin}', sub: s.t('min', 'د')),
                FoodStat(label: s.t('Fee', 'رسوم'), value: sdg(r.deliveryFee), sub: s.t('SDG', 'ج.س')),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _Chip(label: s.t('All', 'الكل'), active: _cat == null, onTap: () => setState(() => _cat = null)),
                for (final c in cats) _Chip(label: _catLabel(s, c), active: _cat == c, onTap: () => setState(() => _cat = c)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = items[i];
              final tone = foodDishTones[r.menu.indexOf(m) % foodDishTones.length];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: W.border, width: 0.5),
                ),
                child: Row(children: [
                  FoodDishThumb(tone: tone),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.label(s.ar), style: W.sans(size: 14, weight: FontWeight.w500)),
                      if (m.desc.isNotEmpty || s.ar) ...[
                        const SizedBox(height: 2),
                        Text(s.ar ? m.name : m.desc,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 11.5, color: W.text2)),
                      ],
                      const SizedBox(height: 4),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text(sdg(m.price), style: W.serif(size: 18)),
                        const SizedBox(width: 4),
                        MonoLabel(s.t('SDG', 'ج.س'), size: 9.5, spacing: 0.2),
                      ]),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  FoodQty(qty: _cart[m.id] ?? 0, onInc: () => _inc(m), onDec: () => _dec(m)),
                ]),
              );
            },
          ),
        ),
      ]),
      if (_count > 0)
        PositionedDirectional(
          start: 18,
          end: 18,
          bottom: 26 + MediaQuery.paddingOf(context).bottom * 0.5,
          child: FoodCartBar(count: _count, total: _subtotal(r), loading: _placing, onTap: () => _checkout(r)),
        ),
    ]);
  }

  static String _catLabel(AppState s, String c) => switch (c) {
        'Coffee' => s.t('Coffee', 'قهوة'),
        'Bakery' => s.t('Bakery', 'مخبوزات'),
        'Kitchen' => s.t('Kitchen', 'المطبخ'),
        'Mains' => s.t('Mains', 'رئيسية'),
        'Drinks' => s.t('Drinks', 'مشروبات'),
        'Grill' => s.t('Grill', 'مشاوي'),
        'Sides' => s.t('Sides', 'إضافات'),
        _ => c,
      };
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap, this.translucent = false, this.color = W.text});
  final String icon;
  final VoidCallback onTap;
  final bool translucent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: translucent ? const Color(0xE6FFFFFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: translucent ? null : Border.all(color: W.border, width: 0.5),
        ),
        child: WIcon(icon, size: 17, strokeWidth: 1.7, color: color),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? W.text : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? W.text : W.border, width: 0.5),
          ),
          child: Text(label, style: W.sans(size: 12.5, color: active ? Colors.white : W.text)),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.r, required this.index, required this.onTap});
  final Restaurant r;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final grad = foodHeroGradients[index % foodHeroGradients.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: W.border, width: 0.5),
          boxShadow: W.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 112,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, stops: const [0, 0.55, 1], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              const Positioned.fill(child: FoodGrain()),
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: 14,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.label(s.ar), style: W.serif(size: 28, color: W.screenBg, height: 1.05)),
                  const SizedBox(height: 2),
                  Text(r.cuisine, style: W.sans(size: 12, color: const Color(0xD9FBFAF6))),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const WIcon('star', size: 12, color: W.gold),
              const SizedBox(width: 4),
              Text(r.rating.toStringAsFixed(1), style: W.sans(size: 12.5, weight: FontWeight.w500)),
              const SizedBox(width: 12),
              const WIcon('clock', size: 12, color: W.text3),
              const SizedBox(width: 4),
              Text(s.t('${r.etaMin} min', '${r.etaMin} د'), style: W.sans(size: 12.5, color: W.text2)),
              const SizedBox(width: 12),
              const WIcon('bike', size: 12, color: W.text3),
              const SizedBox(width: 4),
              Flexible(
                child: Text('${sdg(r.deliveryFee)} ${s.t('SDG', 'ج.س')}',
                    overflow: TextOverflow.ellipsis, style: W.sans(size: 12.5, color: W.text2)),
              ),
              const Spacer(),
              const WIcon('chevron', size: 14, color: W.text3),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Order summary with delivery fee; pops `true` to place the order.
class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({required this.restaurant, required this.cart});
  final Restaurant restaurant;
  final Map<String, int> cart;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = restaurant;
    final lines = [for (final m in r.menu) if ((cart[m.id] ?? 0) > 0) (m, cart[m.id]!)];
    final subtotal = lines.fold<int>(0, (a, l) => a + l.$1.price * l.$2);
    final total = subtotal + r.deliveryFee;
    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(l, style: W.sans(size: bold ? 14.5 : 13, weight: bold ? FontWeight.w600 : FontWeight.w400, color: bold ? W.text : W.text2))),
            Text(v, style: bold ? W.serif(size: 24) : W.mono(size: 12.5, color: W.text, letterSpacing: 0.02)),
          ]),
        );
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: const BoxDecoration(
        color: W.screenBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: W.border2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          MonoLabel(s.t('Your basket', 'سلتك')),
          const SizedBox(height: 4),
          Text(r.label(s.ar), style: W.serif(size: 28)),
          const SizedBox(height: 14),
          WCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              for (final (m, q) in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text('$q×', style: W.mono(size: 12, color: W.text2, letterSpacing: 0.02)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(m.label(s.ar), style: W.sans(size: 13.5, weight: FontWeight.w500))),
                    Text(sdg(m.price * q), style: W.mono(size: 12.5, color: W.text, letterSpacing: 0.02)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          row(s.t('Subtotal', 'المجموع الفرعي'), sdg(subtotal)),
          row(s.t('Delivery fee', 'رسوم التوصيل'), sdg(r.deliveryFee)),
          const Divider(color: W.border, height: 18, thickness: 0.5),
          row(s.t('Total · SDG', 'الإجمالي · ج.س'), sdg(total), bold: true),
          const SizedBox(height: 10),
          StreamBuilder<UserProfile?>(
            stream: context.read<WasilhaBackend>().profile(),
            builder: (context, snap) {
              final bal = snap.data?.balance;
              final short = bal != null && bal < total;
              return Row(children: [
                WIcon('wallet', size: 14, color: short ? W.danger : W.text2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bal == null
                        ? s.t('Paid from your Wasilha wallet', 'الدفع من محفظة وصلها')
                        : s.t('Wallet balance · ${sdg(bal)} SDG', 'رصيد المحفظة · ${sdg(bal)} ج.س'),
                    style: W.sans(size: 12, color: short ? W.danger : W.text2),
                  ),
                ),
                if (short)
                  GestureDetector(
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop(false);
                      nav.pushNamed('topup');
                    },
                    child: Text(s.t('Top up', 'اشحن'), style: W.sans(size: 12, weight: FontWeight.w600, color: s.accent)),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 18),
          Btn(
            s.t('Place order · ${sdg(total)} SDG', 'تأكيد الطلب · ${sdg(total)} ج.س'),
            full: true,
            icon: 'arrow',
            onTap: () => Navigator.of(context).pop(true),
          ),
        ]),
      ),
    );
  }
}
