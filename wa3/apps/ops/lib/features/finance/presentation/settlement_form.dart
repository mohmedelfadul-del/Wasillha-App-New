import 'package:flutter/material.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/settlement_validation.dart';

/// Records cash the driver handed over. Whole SDG, ≤ owed, with a receipt
/// reference and an explicit confirmation.
class SettlementForm extends StatefulWidget {
  const SettlementForm({super.key, required this.owedMinor, required this.driverName, required this.onSubmit});
  final int owedMinor;
  final String driverName;
  final Future<void> Function(int amount, String reference) onSubmit;
  @override
  State<SettlementForm> createState() => _SettlementFormState();
}

class _SettlementFormState extends State<SettlementForm> {
  final _amount = TextEditingController();
  final _ref = TextEditingController();
  SettlementError? _amountError;
  bool _refMissing = false;

  @override
  void dispose() {
    _amount.dispose();
    _ref.dispose();
    super.dispose();
  }

  String _err(S s, SettlementError e) => switch (e) {
        SettlementError.required => s.t('أدخل المبلغ', 'Enter the amount'),
        SettlementError.wholeNumber => s.t('مبلغ صحيح بالجنيه دون كسور', 'A whole SDG amount, no fractions'),
        SettlementError.tooSmall => s.t('المبلغ يجب أن يكون ١ على الأقل', 'The amount must be at least 1'),
        SettlementError.nothingOwed => s.t('لا يوجد مبلغ مستحق على هذا السائق', 'This driver owes nothing'),
        SettlementError.overOwed => s.t('أكبر من المستحق (${moneyMinor(widget.owedMinor, ar: true)})', 'More than is owed (${moneyMinor(widget.owedMinor, ar: false)})'),
      };

  Future<void> _submit() async {
    final s = context.s;
    final e = validateSettlementAmount(_amount.text, widget.owedMinor);
    setState(() {
      _amountError = e;
      _refMissing = _ref.text.trim().isEmpty;
    });
    if (e != null || _refMissing) return;
    final amount = int.parse(_amount.text.trim().replaceAll(',', ''));
    final ok = await confirmAction(
      context,
      title: s.t('تسجيل تسوية؟', 'Record settlement?'),
      body: s.t(
        'استلام ${money(amount, ar: true)} من ${widget.driverName} — إيصال ${ltr(_ref.text.trim())}.\nيُضاف إلى السجل المالي ولا يمكن حذفه.',
        'Received ${money(amount, ar: false)} from ${widget.driverName} — receipt ${ltr(_ref.text.trim())}.\nIt is added to the ledger and cannot be deleted.',
      ),
      confirmLabel: s.t('تسجيل', 'Record'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    await widget.onSubmit(amount, _ref.text.trim());
    if (mounted) {
      _amount.clear();
      _ref.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final max = maxSettleUnits(widget.owedMinor);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: const Key('settle-amount'),
        controller: _amount,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: s.t('المبلغ المستلم (ج.س)', 'Amount received (SDG)'),
          helperText: s.t('حتى ${money(max, ar: true)}', 'Up to ${money(max, ar: false)}'),
          errorText: _amountError == null ? null : _err(s, _amountError!),
          errorMaxLines: 3,
          helperMaxLines: 2,
        ),
      ),
      const SizedBox(height: WSpace.md),
      TextField(
        key: const Key('settle-reference'),
        controller: _ref,
        maxLength: 120,
        decoration: InputDecoration(
          labelText: s.t('رقم الإيصال', 'Receipt reference'),
          errorText: _refMissing ? s.t('رقم الإيصال مطلوب', 'A receipt reference is required') : null,
        ),
      ),
      const SizedBox(height: WSpace.md),
      PrimaryAction(key: const Key('settle-submit'), label: s.t('تسجيل التسوية', 'Record settlement'), icon: Icons.receipt_long, onPressed: _submit),
    ]);
  }
}
