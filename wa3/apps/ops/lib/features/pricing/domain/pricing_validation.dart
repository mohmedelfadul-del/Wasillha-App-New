import 'pricing_repository.dart';

/// Form fields. Percentages are entered as percent (20 = 20 %).
enum PricingField { baseFare, perKm, perMinute, minFare, maxFare, belowPct, abovePct, commissionPct }

enum PricingError { required, wholeNumber, minAboveMax, belowRange, aboveRange, commissionRange, commissionPrecision, notANumber }

const wholeFields = [PricingField.baseFare, PricingField.perKm, PricingField.perMinute, PricingField.minFare, PricingField.maxFare];

/// Mirrors the server's validatePricingConfig (backend/functions/src/domain/pricing.ts):
/// whole non-negative fares, minFare ≤ maxFare, below in [0, 1), above in [0, 5],
/// commissionBps whole and ≤ 5000 (50 %).
({PricingRecord? value, Map<PricingField, PricingError> errors}) validatePricing(Map<PricingField, String> input, {required bool enabled}) {
  final errors = <PricingField, PricingError>{};
  final whole = <PricingField, int>{};
  for (final f in wholeFields) {
    final t = (input[f] ?? '').trim().replaceAll(',', '');
    if (t.isEmpty) {
      errors[f] = PricingError.required;
    } else if (!RegExp(r'^\d+$').hasMatch(t)) {
      errors[f] = PricingError.wholeNumber;
    } else {
      whole[f] = int.parse(t);
    }
  }
  if (whole[PricingField.minFare] != null && whole[PricingField.maxFare] != null && whole[PricingField.minFare]! > whole[PricingField.maxFare]!) {
    errors[PricingField.minFare] = PricingError.minAboveMax;
  }

  double? pct(PricingField f) {
    final t = (input[f] ?? '').trim();
    if (t.isEmpty) {
      errors[f] = PricingError.required;
      return null;
    }
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite) {
      errors[f] = PricingError.notANumber;
      return null;
    }
    return v;
  }

  final below = pct(PricingField.belowPct);
  if (below != null && !(below >= 0 && below < 100)) errors[PricingField.belowPct] = PricingError.belowRange;
  final above = pct(PricingField.abovePct);
  if (above != null && !(above >= 0 && above <= 500)) errors[PricingField.abovePct] = PricingError.aboveRange;
  final commission = pct(PricingField.commissionPct);
  int? bps;
  if (commission != null) {
    final raw = commission * 100;
    if ((raw - raw.round()).abs() > 1e-6) {
      errors[PricingField.commissionPct] = PricingError.commissionPrecision;
    } else {
      bps = raw.round();
      if (bps < 0 || bps > 5000) errors[PricingField.commissionPct] = PricingError.commissionRange;
    }
  }
  if (errors.isNotEmpty) return (value: null, errors: errors);
  return (
    value: PricingRecord(
      baseFare: whole[PricingField.baseFare]!,
      perKm: whole[PricingField.perKm]!,
      perMinute: whole[PricingField.perMinute]!,
      minFare: whole[PricingField.minFare]!,
      maxFare: whole[PricingField.maxFare]!,
      belowReferencePct: _frac(below!),
      aboveReferencePct: _frac(above!),
      commissionBps: bps!,
      enabled: enabled,
    ),
    errors: errors,
  );
}

double _frac(double percent) => double.parse((percent / 100).toStringAsFixed(6));

/// Percent text for a stored fraction (0.2 → "20").
String pctText(double fraction) {
  final p = fraction * 100;
  return (p - p.round()).abs() < 1e-9 ? p.round().toString() : double.parse(p.toStringAsFixed(4)).toString();
}

String bpsText(int bps) => bps % 100 == 0 ? '${bps ~/ 100}' : (bps / 100).toString();
