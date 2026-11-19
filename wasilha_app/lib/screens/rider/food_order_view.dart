import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/nav.dart';
import '../../data/backend.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/w_icon.dart';

/// Success state after checkout: live status of the order from `myOrders()`.
class FoodOrderView extends StatefulWidget {
  const FoodOrderView({super.key, required this.orderId, required this.restaurant});
  final String orderId;
  final Restaurant restaurant;

  @override
  State<FoodOrderView> createState() => _FoodOrderViewState();
}

class _FoodOrderViewState extends State<FoodOrderView> {
  late final Stream<List<StoreOrder>> _orders = context.read<WasilhaBackend>().myOrders();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final accent = s.accent;
    final top = MediaQuery.paddingOf(context).top;
    return StreamBuilder<List<StoreOrder>>(
      stream: _orders,
      builder: (context, snap) {
        StoreOrder? o;
        for (final x in snap.data ?? const <StoreOrder>[]) {
          if (x.id == widget.orderId) o = x;
        }
        final status = o?.status ?? OrderStatus.placed;
        final steps = [
          (OrderStatus.placed, s.t('Order received', 'تم استلام الطلب'), s.t('Sent to ${widget.restaurant.name}', 'أُرسل إلى ${widget.restaurant.label(true)}'), 'receipt'),
          (OrderStatus.preparing, s.t('Preparing', 'قيد التحضير'), s.t('The kitchen is on it', 'المطبخ يجهّز طلبك'), 'bowl'),
          (OrderStatus.courier, s.t('Courier on the way', 'الكابتن في الطريق'),
              o?.courierName != null ? s.t('${o!.courierName} is bringing your order', '${o.courierName} في طريقه إليك') : s.t('Heading to you', 'في الطريق إليك'), 'bike'),
          (OrderStatus.delivered, s.t('Delivered', 'تم التوصيل'), s.t('Enjoy your meal', 'بالهناء والشفاء'), 'check'),
        ];
        final declined = status == OrderStatus.declined;
        final cur = declined ? -1 : steps.indexWhere((e) => e.$1 == status);
        final headline = switch (status) {
          OrderStatus.placed => s.t('Order placed', 'تم الطلب'),
          OrderStatus.preparing => s.t('Being prepared', 'قيد التحضير'),
          OrderStatus.courier => s.t('On its way', 'في الطريق'),
          OrderStatus.delivered => s.t('Delivered', 'تم التوصيل'),
          OrderStatus.declined => s.t('Order declined', 'تم رفض الطلب'),
        };
        return ListView(
          padding: EdgeInsets.fromLTRB(20, top + 20, 20, 40),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: declined ? W.danger : accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (declined ? W.danger : accent).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
                ),
                child: WIcon(declined ? 'close' : 'check', size: 30, strokeWidth: 2, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: MonoLabel(o == null ? s.t('Order', 'الطلب') : '${s.t('Order', 'الطلب')} #${o.shortNo}')),
            const SizedBox(height: 6),
            Text(headline, textAlign: TextAlign.center, style: W.serif(size: 40)),
            const SizedBox(height: 6),
            Text(
              declined
                  ? s.t('The restaurant could not take your order.', 'لم يتمكن المطعم من قبول طلبك.')
                  : s.t('${widget.restaurant.name} · about ${widget.restaurant.etaMin} min', '${widget.restaurant.label(true)} · حوالي ${widget.restaurant.etaMin} د'),
              textAlign: TextAlign.center,
              style: W.sans(size: 13, color: W.text2),
            ),
            const SizedBox(height: 24),
            if (!declined)
              WCard(
                child: Column(children: [
                  for (var i = 0; i < steps.length; i++)
                    _Step(
                      title: steps[i].$2,
                      sub: steps[i].$3,
                      icon: steps[i].$4,
                      state: i < cur ? 1 : (i == cur ? 2 : 0),
                      last: i == steps.length - 1,
                    ),
                ]),
              ),
            if (o != null) ...[
              const SizedBox(height: 14),
              WCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(children: [
                  for (final l in o.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Text('${l.qty}×', style: W.mono(size: 12, color: W.text2, letterSpacing: 0.02)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.name, style: W.sans(size: 13))),
                        Text(sdg(l.price * l.qty), style: W.mono(size: 12, color: W.text, letterSpacing: 0.02)),
                      ]),
                    ),
                  const Divider(color: W.border, thickness: 0.5),
                  Row(children: [
                    Expanded(child: Text(s.t('Total incl. delivery', 'الإجمالي شامل التوصيل'), style: W.sans(size: 13, weight: FontWeight.w500))),
                    Text('${sdg(o.total)} ${s.t('SDG', 'ج.س')}', style: W.serif(size: 20)),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            Btn(s.t('Back to home', 'العودة للرئيسية'), full: true, variant: BtnVariant.dark, icon: 'home', onTap: () => context.root('home')),
          ],
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.sub, required this.icon, required this.state, required this.last});
  final String title;
  final String sub;
  final String icon;

  /// 0 upcoming · 1 done · 2 current
  final int state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<AppState>().accent;
    final color = state == 2 ? accent : (state == 1 ? W.success : W.surface2);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)),
            child: WIcon(state == 1 ? 'check' : icon, size: 16, strokeWidth: 1.8, color: state == 0 ? W.text3 : Colors.white),
          ),
          if (!last)
            Expanded(
              child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: state == 1 ? W.success : W.border2),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: W.sans(size: 14, weight: FontWeight.w500, color: state == 0 ? W.text3 : W.text)),
              const SizedBox(height: 2),
              Text(sub, style: W.sans(size: 12, color: state == 0 ? W.text3 : W.text2)),
            ]),
          ),
        ),
      ]),
    );
  }
}
