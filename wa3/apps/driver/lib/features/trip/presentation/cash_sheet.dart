import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wa3_core/wa3_core.dart';

/// Validates a whole-number cash amount; the server accepts 0..3× the fare.
String? validateCash(S s, String text, int fare) {
  final v = int.tryParse(text.trim());
  if (v == null) return s.t('اكتب المبلغ بالأرقام (بدون كسور).', 'Enter the amount as a whole number.');
  final max = fare * 3 < 1 ? 1 : fare * 3;
  if (v < 0 || v > max) return '${s.t('المبلغ يجب أن يكون بين', 'The amount must be between')} ${money(0, ar: s.ar)} – ${money(max, ar: s.ar)}';
  return null;
}

Future<void> showCashSheet(BuildContext context, {required Trip trip, required Future<void> Function(int amount) onRecord}) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => CashSheet(trip: trip, onRecord: onRecord));

/// Records cash received. Prefilled with the fare; a different amount needs
/// confirmation (the server opens a review case for mismatches).
class CashSheet extends StatefulWidget {
  const CashSheet({super.key, required this.trip, required this.onRecord});
  final Trip trip;
  final Future<void> Function(int amount) onRecord;
  @override
  State<CashSheet> createState() => _CashSheetState();
}

class _CashSheetState extends State<CashSheet> {
  late final int _fare = widget.trip.amountDue ?? widget.trip.fare ?? 0;
  late final _amount = TextEditingController(text: '$_fare');
  String? _invalid;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    final s = context.s;
    final err = validateCash(s, _amount.text, _fare);
    setState(() => _invalid = err);
    if (err != null) return;
    final amount = int.parse(_amount.text.trim());
    if (amount != _fare) {
      final ok = await confirmAction(
        context,
        title: s.t('المبلغ يختلف عن الأجرة', 'Amount differs from the fare'),
        body: '${s.t('الأجرة المتفق عليها', 'Agreed fare')} ${money(_fare, ar: s.ar)} · ${s.t('ستسجّل', 'You’ll record')} ${money(amount, ar: s.ar)}. '
            '${s.t('سيراجع فريقنا الفرق.', 'Our team will review the difference.')}',
        confirmLabel: s.t('سجّل هذا المبلغ', 'Record this amount'),
      );
      if (!ok) return;
    }
    await widget.onRecord(amount);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(WSpace.lg, 0, WSpace.lg, MediaQuery.viewInsetsOf(context).bottom + WSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(s.t('كم استلمت نقداً؟', 'How much cash did you receive?'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WSpace.xs),
          Text('${s.t('الأجرة المتفق عليها', 'Agreed fare')}: ${money(_fare, ar: s.ar)}'),
          const SizedBox(height: WSpace.lg),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s.t('المبلغ المستلم', 'Amount received'), suffixText: s.currency, errorText: _invalid),
            ),
          ),
          const SizedBox(height: WSpace.xl),
          PrimaryAction(label: s.t('تسجيل المبلغ النقدي', 'Record cash'), large: true, onPressed: _record),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        ]),
      ),
    );
  }
}
