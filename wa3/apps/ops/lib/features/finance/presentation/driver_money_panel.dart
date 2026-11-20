import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/routes.dart';
import '../../../app/sections.dart';
import '../../../app/services.dart';
import '../../../app/widgets/failure.dart';
import '../../../app/widgets/fields.dart';
import '../../../app/widgets/stale_notice.dart';
import '../../auth/application/session_controller.dart';
import '../application/settlement_controller.dart';
import '../domain/finance_repository.dart';
import 'settlement_form.dart';

class DriverMoneyPanel extends StatefulWidget {
  const DriverMoneyPanel({super.key, required this.driver});
  final DriverProfile driver;
  @override
  State<DriverMoneyPanel> createState() => _DriverMoneyPanelState();
}

class _DriverMoneyPanelState extends State<DriverMoneyPanel> {
  SettlementController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c ??= SettlementController(context.services.finance, widget.driver.uid);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _settle(int amount, String reference) async {
    final s = context.s;
    try {
      final owed = await _c!.settle(amount: amount, reference: reference);
      if (mounted) showSuccess(context, s.t('سُجّلت التسوية. المتبقي: ', 'Settlement recorded. Still owed: ') + moneyMinor(owed, ar: s.ar));
    } catch (e) {
      if (mounted) showOpsFailure(context, e, myUid: context.myUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final d = widget.driver;
    return ListenableBuilder(
      listenable: _c!,
      builder: (context, _) {
        final c = _c!;
        final m = c.money;
        String mm(int v) => moneyMinor(v, ar: s.ar);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: WSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Semantics(header: true, child: Text(d.name, style: Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed: () => openDriver(context, d.uid), child: Text(s.t('ملف السائق', 'Driver profile'))),
          ]),
          Text('${ltr(d.phone)} · ${ltr(d.uid)}', style: Theme.of(context).textTheme.bodySmall),
          SectionTitle(s.t('الرصيد (محسوب من السجل)', 'Balance (derived from the ledger)')),
          if (c.moneyError != null) ...[
            WBanner(tone: Tone.error, text: describeFailure(s, c.moneyError is ApiFailure ? c.moneyError as ApiFailure : ApiFailure('internal', '${c.moneyError}'))),
            Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: c.refreshMoney, child: Text(s.retry))),
          ] else if (m == null)
            Semantics(label: s.loading, child: const LinearProgressIndicator())
          else ...[
            Field(s.t('النقد المحصّل من الركاب', 'Cash collected from riders'), mm(m.collectedMinor)),
            Field(s.t('العمولة المستحقة', 'Commission charged'), mm(m.commissionMinor)),
            Field(s.t('المسدَّد', 'Settled'), mm(m.settledMinor)),
            const SizedBox(height: WSpace.xs),
            Wrap(spacing: WSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(s.t('المتبقي على السائق:', 'Still owed:')),
              Text(mm(m.owedMinor), key: const Key('owed'), style: Theme.of(context).textTheme.headlineMedium),
              StatusBadge(tone: m.owedMinor > 0 ? Tone.warning : Tone.success, label: m.owedMinor > 0 ? s.t('مستحق', 'Owed') : s.t('لا شيء مستحق', 'Nothing owed')),
            ]),
            if (Can.recordSettlement(context.role) && m.owedMinor > 0) ...[
              SectionTitle(s.t('تسجيل تسوية نقدية', 'Record a cash settlement')),
              SettlementForm(owedMinor: m.owedMinor, driverName: d.name, onSubmit: _settle),
            ],
          ],
          SectionTitle(s.t('السجل المالي (الأحدث أولاً)', 'Ledger (newest first)')),
          StaleNotice(fromCache: c.ledgerFromCache),
          if (c.ledgerError != null) ...[
            WBanner(tone: Tone.error, text: describeFailure(s, c.ledgerError is ApiFailure ? c.ledgerError as ApiFailure : ApiFailure('internal', '${c.ledgerError}'))),
            Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: c.retryLedger, child: Text(s.retry))),
          ] else if (c.ledger == null)
            Semantics(label: s.loading, child: const LinearProgressIndicator())
          else if (c.ledger!.isEmpty)
            Text(s.t('لا توجد قيود.', 'No entries.'))
          else
            for (final e in c.ledger!) _LedgerLine(record: e),
        ]);
      },
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({required this.record});
  final LedgerRecord record;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final e = record.entry;
    final kind = switch (e.kind) {
      LedgerKind.cash_collected => s.t('نقد محصّل', 'Cash collected'),
      LedgerKind.commission_due => s.t('عمولة مستحقة', 'Commission due'),
      LedgerKind.settlement => s.t('تسوية', 'Settlement'),
      LedgerKind.adjustment => e.sign < 0 ? s.t('تعديل (تخفيض)', 'Adjustment (decrease)') : s.t('تعديل (زيادة)', 'Adjustment (increase)'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WSpace.xs),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: WSpace.sm, children: [
          Text(kind, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(moneyMinor(e.amountMinor, ar: s.ar)),
          Text(dateTime(e.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ]),
        if (e.reason != null) Text(e.kind == LedgerKind.settlement ? '${s.t('إيصال', 'Receipt')}: ${ltr(e.reason!)}' : e.reason!, style: Theme.of(context).textTheme.bodySmall),
        if (e.tripId != null)
          InkWell(
            onTap: () => openTrip(context, e.tripId!),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${s.t('الرحلة', 'Trip')} ${ltr(shortId(e.tripId!))}', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          ),
        const Divider(),
      ]),
    );
  }
}
