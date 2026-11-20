import 'package:wa3_core/wa3_core.dart';

enum SettlementError { required, wholeNumber, tooSmall, nothingOwed, overOwed }

/// Settlement amount in whole SDG: positive, whole, and not more than owed
/// (server: assertSettlementAllowed). [owedMinor] is in minor units.
SettlementError? validateSettlementAmount(String text, int owedMinor) {
  final t = text.trim().replaceAll(',', '');
  if (owedMinor <= 0) return SettlementError.nothingOwed;
  if (t.isEmpty) return SettlementError.required;
  if (!RegExp(r'^\d+$').hasMatch(t)) return SettlementError.wholeNumber;
  final units = int.parse(t);
  if (units < 1) return SettlementError.tooSmall;
  if (units * Tunables.minorPerUnit > owedMinor) return SettlementError.overOwed;
  return null;
}

/// Whole units a driver can settle at most.
int maxSettleUnits(int owedMinor) => owedMinor <= 0 ? 0 : owedMinor ~/ Tunables.minorPerUnit;
