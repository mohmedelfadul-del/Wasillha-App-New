import 'package:wa3_core/wa3_core.dart';

/// Unambiguous money wording: who holds the money and who owes whom.
class EarningsLabels {
  const EarningsLabels(this.s);
  final S s;
  String get collected => s.t('استلمت من الركاب', 'You collected');
  String get collectedHint => s.t('النقود التي دفعها لك الركاب.', 'Cash riders paid you.');
  String get commission => s.t('عمولة الشركة', 'Company commission');
  String get commissionHint => s.t('حصة الشركة من تلك الرحلات.', 'The company’s share of those trips.');
  String get net => s.t('صافي ربحك', 'Your net earnings');
  String get netHint => s.t('ما استلمته ناقص العمولة.', 'What you collected minus the commission.');
  String get settled => s.t('دفعت للشركة', 'You paid the company');
  String get owed => s.t('ما زلت مديناً به', 'You still owe');
  String get owedNone => s.t('لا تدين للشركة بشيء', 'You owe the company nothing');
  String get credit => s.t('رصيد لصالحك لدى الشركة', 'The company owes you');

  String entry(LedgerEntry e) => switch (e.kind) {
        LedgerKind.cash_collected => s.t('نقود استلمتها من راكب', 'Cash you collected from a rider'),
        LedgerKind.commission_due => s.t('عمولة مستحقة للشركة', 'Commission you owe the company'),
        LedgerKind.settlement => s.t('دفعة سلّمتها للشركة', 'Payment you made to the company'),
        LedgerKind.adjustment => e.sign < 0
            ? s.t('تسوية: تُنقص ما تدين به', 'Adjustment: reduces what you owe')
            : s.t('تسوية: تزيد ما تدين به', 'Adjustment: increases what you owe'),
      };
}
