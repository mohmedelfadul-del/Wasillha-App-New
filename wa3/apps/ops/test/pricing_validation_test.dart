import 'package:flutter_test/flutter_test.dart';
import 'package:wasilha_ops/features/pricing/domain/pricing_validation.dart';

Map<PricingField, String> input({String min = '1500', String max = '60000', String below = '20', String above = '100', String commission = '15'}) => {
      PricingField.baseFare: '1000',
      PricingField.perKm: '350',
      PricingField.perMinute: '25',
      PricingField.minFare: min,
      PricingField.maxFare: max,
      PricingField.belowPct: below,
      PricingField.abovePct: above,
      PricingField.commissionPct: commission,
    };

void main() {
  test('valid config converts percent to the server units', () {
    final r = validatePricing(input(), enabled: true);
    expect(r.errors, isEmpty);
    expect(r.value!.belowReferencePct, 0.2);
    expect(r.value!.aboveReferencePct, 1.0);
    expect(r.value!.commissionBps, 1500);
    expect(r.value!.toConfig()['minFare'], 1500);
  });

  test('mirrors server bounds', () {
    expect(validatePricing(input(min: '70000'), enabled: true).errors[PricingField.minFare], PricingError.minAboveMax);
    expect(validatePricing(input(below: '100'), enabled: true).errors[PricingField.belowPct], PricingError.belowRange);
    expect(validatePricing(input(above: '501'), enabled: true).errors[PricingField.abovePct], PricingError.aboveRange);
    expect(validatePricing(input(commission: '50.01'), enabled: true).errors[PricingField.commissionPct], PricingError.commissionRange);
    expect(validatePricing(input(commission: '12.345'), enabled: true).errors[PricingField.commissionPct], PricingError.commissionPrecision);
    expect(validatePricing(input(min: '1500.5'), enabled: true).errors[PricingField.minFare], PricingError.wholeNumber);
    expect(validatePricing(input(min: ''), enabled: true).errors[PricingField.minFare], PricingError.required);
    expect(validatePricing(input(commission: '12.5'), enabled: true).value!.commissionBps, 1250);
  });

  test('round-trips stored values for display', () {
    expect(pctText(0.15), '15');
    expect(bpsText(1250), '12.5');
    expect(bpsText(1500), '15');
  });
}
