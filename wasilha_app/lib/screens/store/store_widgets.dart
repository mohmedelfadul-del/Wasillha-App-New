import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// 40px rounded-square header button.
class StoreSquareBtn extends StatelessWidget {
  const StoreSquareBtn({super.key, required this.child, this.onTap, this.color = Colors.white, this.glow});
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            glow == null
                ? const BoxShadow(color: Color(0x0F140F1E), blurRadius: 14, offset: Offset(0, 4))
                : BoxShadow(color: glow!.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class StoreSpinner extends StatelessWidget {
  const StoreSpinner({super.key});
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: W.text3));
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, this.size = 140});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => PositionedDirectional(
        top: -30 - size * 0.25,
        end: -20 - size * 0.2,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.33), color.withValues(alpha: 0)],
                stops: const [0, 0.65],
              ),
            ),
          ),
        ),
      );
}

/// Revenue / orders / rating tiles, computed from today's orders.
class StoreKpis extends StatelessWidget {
  const StoreKpis({super.key, required this.orders, this.rating});
  final List<StoreOrder> orders;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    bool counts(StoreOrder o) => o.status != OrderStatus.declined;
    final today = orders.where((o) => _sameDay(o.createdAt, now) && counts(o)).toList();
    final prev = orders.where((o) => _sameDay(o.createdAt, yesterday) && counts(o)).toList();
    final revenue = today.fold<int>(0, (a, o) => a + o.total);
    final prevRevenue = prev.fold<int>(0, (a, o) => a + o.total);
    final active = orders
        .where((o) => o.status == OrderStatus.placed || o.status == OrderStatus.preparing || o.status == OrderStatus.courier)
        .length;
    final avg = today.isEmpty ? 0 : (revenue / today.length).round();
    final change = prevRevenue == 0 ? null : (revenue - prevRevenue) / prevRevenue * 100;

    Widget tile({required String label, required Widget value, required String sub}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: W.border, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MonoLabel(label, size: 9),
              const SizedBox(height: 6),
              value,
              const SizedBox(height: 4),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: W.sans(size: 10, color: W.text3)),
            ]),
          ),
        );

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 2,
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: W.text, borderRadius: BorderRadius.circular(18)),
            child: Stack(clipBehavior: Clip.none, children: [
              _Glow(color: accent),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MonoLabel(s.t('Today · Revenue', 'اليوم · الإيرادات'), size: 9, spacing: 0.28, color: const Color(0x8CFFFFFF)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(sdg(revenue), style: W.serif(size: 32, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('SDG', style: W.mono(size: 10, color: const Color(0x8CFFFFFF))),
                ]),
                const SizedBox(height: 6),
                Text(
                  change == null
                      ? s.t('Avg ${sdg(avg)} SDG / order', 'متوسط ${sdg(avg)} ج.س للطلب')
                      : s.t('${change >= 0 ? '↑' : '↓'} ${change.abs().round()}% vs yesterday',
                          '${change >= 0 ? '↑' : '↓'} ${change.abs().round()}٪ مقارنة بالأمس'),
                  style: W.sans(size: 10.5, color: const Color(0xB3FFFFFF)),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        tile(
          label: s.t('Orders', 'الطلبات'),
          value: Text('${today.length}', style: W.serif(size: 30)),
          sub: s.t('+ $active active', '+ $active نشط'),
        ),
        const SizedBox(width: 8),
        tile(
          label: s.t('Rating', 'تقييم'),
          value: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text((rating ?? 5).toStringAsFixed(1), style: W.serif(size: 30)),
              const SizedBox(width: 4),
              const WIcon('star', size: 12, color: W.gold),
            ]),
          ),
          sub: s.t('customer avg', 'متوسط العملاء'),
        ),
      ]),
    );
  }
}

/// One order with its status pill and the next action.
class StoreOrderCard extends StatelessWidget {
  const StoreOrderCard({super.key, required this.order, required this.busy, required this.onStatus});
  final StoreOrder order;
  final bool busy;
  final ValueChanged<OrderStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final o = order;
    final (label, bg, fg) = switch (o.status) {
      OrderStatus.placed => (s.t('New', 'جديد'), accent, Colors.white),
      OrderStatus.preparing => (s.t('Preparing', 'تحضير'), W.text, Colors.white),
      OrderStatus.courier => (s.t('Courier', 'مع الكابتن'), W.gold, W.text),
      OrderStatus.delivered => (s.t('Delivered', 'اكتمل'), W.surface2, W.text2),
      OrderStatus.declined => (s.t('Declined', 'مرفوض'), W.surface2, W.danger),
    };
    final faded = o.status == OrderStatus.declined;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: faded ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: W.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('#${o.shortNo}', style: W.mono(size: 11, weight: FontWeight.w600, letterSpacing: 0.14)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
              child: MonoLabel(label, size: 9, color: fg, spacing: 0.2),
            ),
            const Spacer(),
            Text(timeAgo(o.createdAt, ar: s.ar).toUpperCase(), style: W.mono(size: 10)),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.customerName, style: W.sans(size: 13.5, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(o.summary, style: W.sans(size: 11.5, color: W.text2, height: 1.45)),
                if (o.courierName != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const WIcon('bike', size: 11, color: W.text3),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${s.t('COURIER', 'الكابتن')} · ${o.courierName!.toUpperCase()}',
                        overflow: TextOverflow.ellipsis,
                        style: W.mono(size: 10, letterSpacing: 0.12),
                      ),
                    ),
                  ]),
                ],
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(sdg(o.total), style: W.serif(size: 22)),
              const SizedBox(height: 2),
              MonoLabel(s.t('SDG', 'ج.س'), size: 9, spacing: 0.2),
            ]),
          ]),
          ..._actions(s, accent),
        ]),
      ),
    );
  }

  List<Widget> _actions(AppState s, Color accent) {
    Widget btn(String text, {required Color bg, required Color fg, required VoidCallback onTap, bool outline = false, String? icon}) =>
        GestureDetector(
          onTap: busy ? null : onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: outline ? Border.all(color: W.border, width: 0.5) : null,
            ),
            child: busy && !outline
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(
                      child: Text(text,
                          overflow: TextOverflow.ellipsis,
                          style: W.sans(size: 12.5, weight: outline ? FontWeight.w400 : FontWeight.w500, color: fg)),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      WIcon(icon, size: 14, strokeWidth: 1.8, color: fg),
                    ],
                  ]),
          ),
        );

    switch (order.status) {
      case OrderStatus.placed:
        return [
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: btn(s.t('Decline', 'رفض'),
                  bg: Colors.white, fg: W.text, outline: true, onTap: () => onStatus(OrderStatus.declined)),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: btn(s.t('Accept · start preparing', 'قبول · بدء التحضير'),
                  bg: accent, fg: Colors.white, icon: 'arrow', onTap: () => onStatus(OrderStatus.preparing)),
            ),
          ]),
        ];
      case OrderStatus.preparing:
        return [
          const SizedBox(height: 14),
          btn(s.t('Ready · request courier', 'جاهز · طلب كابتن'),
              bg: W.text, fg: Colors.white, onTap: () => onStatus(OrderStatus.courier)),
        ];
      case OrderStatus.courier:
        return [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF5DC), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const WIcon('nav', size: 13, strokeWidth: 1.8, color: Color(0xFF9A7A0E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.t('Courier en route to the customer', 'الكابتن في الطريق إلى العميل'),
                    style: W.sans(size: 11.5, color: const Color(0xFF7E6212))),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          btn(s.t('Mark delivered', 'تم التوصيل'),
              bg: Colors.white, fg: W.text, outline: true, icon: 'check', onTap: () => onStatus(OrderStatus.delivered)),
        ];
      case OrderStatus.delivered:
      case OrderStatus.declined:
        return const [];
    }
  }
}

/// Menu item with an availability switch.
class StoreMenuRow extends StatelessWidget {
  const StoreMenuRow({super.key, required this.item, required this.on, required this.last, required this.onToggle});
  final MenuItem item;
  final bool on;
  final bool last;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: on ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: W.border, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: W.surface2, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label(s.ar), style: W.sans(size: 13.5, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${sdg(item.price)} ${s.t('SDG', 'ج.س')}', style: W.mono(size: 11, letterSpacing: 0.04)),
            ]),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: on ? W.success : const Color(0xFFD6D2C9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Static branch cards from the design.
List<Widget> storeBranches(AppState s, Color accent) {
  final branches = [
    (s.t('Riyadh District', 'حي الرياض'), s.t('Block 32 · open till 23:00', 'بلوك ٣٢ · مفتوح حتى ٢٣:٠٠'), 6, 28, true),
    (s.t('Africa Road', 'شارع أفريقيا'), s.t('Tower B · open till 22:00', 'برج ب · مفتوح حتى ٢٢:٠٠'), 4, 14, false),
  ];
  return [
    for (final (name, addr, staff, orders, primary) in branches)
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary ? W.text : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: W.border, width: 0.5),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          if (primary) _Glow(color: accent, size: 150),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, style: W.serif(size: 22, color: primary ? Colors.white : W.text))),
              if (primary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                  child: MonoLabel(s.t('Main', 'الرئيسي'), size: 9, color: Colors.white, spacing: 0.2),
                ),
            ]),
            const SizedBox(height: 4),
            Text(addr, style: W.sans(size: 12, color: (primary ? Colors.white : W.text).withValues(alpha: 0.65))),
            const SizedBox(height: 14),
            Row(children: [
              for (final (l, v) in [(s.t('Staff', 'الموظفون'), staff), (s.t('Orders · today', 'طلبات اليوم'), orders)]) ...[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  MonoLabel(l, size: 9, color: (primary ? Colors.white : W.text).withValues(alpha: 0.55)),
                  const SizedBox(height: 2),
                  Text('$v', style: W.serif(size: 22, color: primary ? Colors.white : W.text)),
                ]),
                const SizedBox(width: 22),
              ],
            ]),
          ]),
        ]),
      ),
  ];
}
