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
import 'store_widgets.dart';

/// 21 — Store dashboard: live orders from `storeOrders()`, menu, branches.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late final WasilhaBackend _backend = context.read<WasilhaBackend>();
  late final Stream<UserProfile?> _profile = _backend.profile();
  late final Stream<List<StoreOrder>> _orders = _backend.storeOrders();

  /// orders | menu | branches
  String _tab = 'orders';
  bool _searching = false;
  String _query = '';
  final Set<String> _busy = {};

  /// Menu items switched off locally (availability is not stored server-side yet).
  final Set<String> _off = {};

  static Restaurant? _resolve(String storeName) {
    final key = storeName.trim().toLowerCase();
    if (key.isEmpty) return Catalog.restaurants.first;
    for (final r in Catalog.restaurants) {
      if (r.id == storeName || r.name.toLowerCase() == key || r.nameAr == storeName) return r;
    }
    return null;
  }

  Future<void> _set(StoreOrder o, OrderStatus st) async {
    setState(() => _busy.add(o.id));
    try {
      await _backend.setOrderStatus(o.id, st);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(o.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: W.screenBg,
      body: StreamBuilder<UserProfile?>(
        stream: _profile,
        builder: (context, pSnap) {
          final me = pSnap.data;
          final r = _resolve(me?.storeName ?? '');
          final name = r?.label(s.ar) ?? ((me?.storeName.isNotEmpty ?? false) ? me!.storeName : s.t('My store', 'متجري'));
          return StreamBuilder<List<StoreOrder>>(
            stream: _orders,
            builder: (context, oSnap) {
              final orders = oSnap.data ?? const <StoreOrder>[];
              return ListView(
                padding: EdgeInsets.fromLTRB(18, top + 12, 18, 100),
                children: [
                  // Header
                  Row(children: [
                    StoreSquareBtn(
                      onTap: () => context.go('settings'),
                      child: Avatar(size: 28, label: me?.initials ?? 'W', tone: 'olive'),
                    ),
                    Expanded(
                      child: Center(
                        child: MonoLabel(s.t('Store dashboard · المتجر', 'لوحة المتجر'), spacing: 0.3),
                      ),
                    ),
                    StoreSquareBtn(
                      color: accent,
                      glow: accent,
                      onTap: () {
                        setState(() => _tab = 'menu');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: W.text,
                          content: Text(s.t('Adding new menu items is coming soon', 'إضافة أصناف جديدة قريباً')),
                        ));
                      },
                      child: const WIcon('plus', size: 18, strokeWidth: 1.8, color: Colors.white),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _Headline(name: name, accent: accent),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: W.success,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x2E1F8A5B), spreadRadius: 3)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.t('${r?.cuisine ?? 'Store'} · 2 branches · open till 23:00',
                            'فرعان · مفتوح حتى ٢٣:٠٠'),
                        overflow: TextOverflow.ellipsis,
                        style: W.sans(size: 12.5, color: W.text2),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  if (!oSnap.hasData)
                    const SizedBox(height: 92, child: Center(child: StoreSpinner()))
                  else
                    StoreKpis(orders: orders, rating: r?.rating),
                  const SizedBox(height: 24),
                  _tabs(s),
                  if (_searching && _tab == 'orders') ...[
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: W.sans(size: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: s.t('Search customer or item', 'ابحث عن عميل أو صنف'),
                        hintStyle: W.sans(size: 13.5, color: W.text3),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: WIcon('search', size: 14, color: W.text3),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 38),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: W.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: W.border, width: 0.5),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_tab == 'orders') ..._ordersTab(s, orders, oSnap.hasData),
                  if (_tab == 'menu') ..._menuTab(s, r),
                  if (_tab == 'branches') ...storeBranches(s, accent),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _tabs(AppState s) {
    final items = [
      ('orders', s.t('Orders', 'الطلبات')),
      ('menu', s.t('Menu', 'القائمة')),
      ('branches', s.t('Branches', 'الفروع')),
    ];
    return Row(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final (id, label) in items) ...[
              if (id != 'orders') const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _tab = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _tab == id ? W.text : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: _tab == id ? null : Border.all(color: W.border, width: 0.5),
                  ),
                  child: Text(label,
                      style: W.sans(size: 12.5, weight: FontWeight.w500, color: _tab == id ? Colors.white : W.text)),
                ),
              ),
            ],
          ]),
        ),
      ),
      GestureDetector(
        onTap: () => setState(() {
          _tab = 'orders';
          _searching = !_searching;
          if (!_searching) _query = '';
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            WIcon(_searching ? 'close' : 'search', size: 13, strokeWidth: 1.7, color: W.text2),
            const SizedBox(width: 4),
            Text(s.t('Search', 'بحث'), style: W.sans(size: 12, color: W.text2)),
          ]),
        ),
      ),
    ]);
  }

  List<Widget> _ordersTab(AppState s, List<StoreOrder> all, bool loaded) {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all.where((o) => o.customerName.toLowerCase().contains(q) || o.summary.toLowerCase().contains(q)).toList();
    if (!loaded) return const [];
    if (list.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: W.border2, width: 0.5),
          ),
          child: Text(
            q.isEmpty ? s.t('No orders yet today.', 'لا توجد طلبات اليوم بعد.') : s.t('No matching orders.', 'لا توجد طلبات مطابقة.'),
            textAlign: TextAlign.center,
            style: W.sans(size: 12.5, color: W.text2),
          ),
        ),
      ];
    }
    return [
      for (final o in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StoreOrderCard(
            key: ValueKey(o.id),
            order: o,
            busy: _busy.contains(o.id),
            onStatus: (st) => _set(o, st),
          ),
        ),
    ];
  }

  List<Widget> _menuTab(AppState s, Restaurant? r) {
    if (r == null || r.menu.isEmpty) {
      return [
        Text(s.t('No menu linked to this store yet.', 'لا توجد قائمة مرتبطة بهذا المتجر بعد.'),
            style: W.sans(size: 12.5, color: W.text2)),
      ];
    }
    final cats = <String, List<MenuItem>>{};
    for (final m in r.menu) {
      cats.putIfAbsent(m.category.isEmpty ? 'Menu' : m.category, () => []).add(m);
    }
    return [
      for (final e in cats.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            MonoLabel(e.key, size: 9.5, spacing: 0.3),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: W.border, width: 0.5),
              ),
              child: Column(children: [
                for (var j = 0; j < e.value.length; j++)
                  StoreMenuRow(
                    item: e.value[j],
                    on: !_off.contains(e.value[j].id),
                    last: j == e.value.length - 1,
                    onToggle: () => setState(() {
                      final id = e.value[j].id;
                      if (!_off.remove(id)) _off.add(id);
                    }),
                  ),
              ]),
            ),
          ]),
        ),
    ];
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.name, required this.accent});
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final head = words.length > 1 ? '${words.sublist(0, words.length - 1).join(' ')} ' : '';
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: head),
        TextSpan(text: words.last, style: TextStyle(color: accent)),
      ]),
      style: W.serif(size: 36, letterSpacing: -0.9),
    );
  }
}
