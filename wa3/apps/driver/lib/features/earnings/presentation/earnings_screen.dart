import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/format.dart';
import '../../../app/services.dart';
import '../../../app/widgets/info_row.dart';
import '../domain/earnings_labels.dart';

/// myEarnings: derived totals (never a stored balance) and ledger history.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late Future<DriverMoney> _money = context.services.earnings.myEarnings();

  Future<void> _reload() async {
    final f = context.services.earnings.myEarnings();
    setState(() => _money = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('الأرباح', 'Earnings')), actions: [
        IconButton(onPressed: _reload, tooltip: s.t('تحديث', 'Refresh'), icon: const Icon(Icons.refresh)),
      ]),
      body: FutureBuilder<DriverMoney>(
        future: _money,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return WStateView.loading();
          if (snap.hasError) return WStateView.error(context, snap.error!, onRetry: _reload);
          return RefreshIndicator(onRefresh: _reload, child: EarningsView(money: snap.data!));
        },
      ),
    );
  }
}

class EarningsView extends StatelessWidget {
  const EarningsView({super.key, required this.money});
  final DriverMoney money;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = EarningsLabels(s);
    String m(int v) => moneyMinor(v, ar: s.ar);
    final owed = money.owedMinor;
    return ListView(padding: const EdgeInsets.all(WSpace.lg), children: [
      Section(children: [
        InfoRow(label: l.collected, value: m(money.collectedMinor)),
        Text(l.collectedHint, style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: WSpace.xl),
        InfoRow(label: l.commission, value: m(money.commissionMinor)),
        Text(l.commissionHint, style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: WSpace.xl),
        InfoRow(label: l.net, value: m(money.earnedMinor), emphasis: true),
        Text(l.netHint, style: Theme.of(context).textTheme.bodySmall),
      ]),
      const SizedBox(height: WSpace.md),
      Section(children: [
        InfoRow(label: l.settled, value: m(money.settledMinor)),
        const Divider(height: WSpace.xl),
        if (owed > 0) ...[
          InfoRow(label: l.owed, value: m(owed), emphasis: true),
          const SizedBox(height: WSpace.xs),
          StatusBadge(tone: Tone.warning, label: s.t('سلّم هذا المبلغ لمكتب الشركة.', 'Hand this amount to the company office.')),
        ] else if (owed < 0)
          InfoRow(label: l.credit, value: m(-owed), emphasis: true)
        else
          StatusBadge(tone: Tone.success, label: l.owedNone),
      ]),
      const SizedBox(height: WSpace.xl),
      Text(s.t('السجل', 'History'), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: WSpace.sm),
      if (money.entries.isEmpty)
        WStateView.empty(icon: Icons.receipt_long_outlined, title: s.t('لا توجد حركات بعد', 'No entries yet'), body: s.t('تظهر هنا كل رحلة مكتملة وكل دفعة.', 'Every completed trip and payment appears here.'))
      else
        for (final e in money.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.entry(e)),
            subtitle: Text([
              dateTime(e.createdAt),
              if (e.reason != null && e.reason!.isNotEmpty) e.reason!,
            ].join(' · ')),
            trailing: Text(m(e.amountMinor), style: Theme.of(context).textTheme.titleSmall),
          ),
    ]);
  }
}
