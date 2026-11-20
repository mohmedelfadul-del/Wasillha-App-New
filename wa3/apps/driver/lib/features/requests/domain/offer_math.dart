import 'package:wa3_core/wa3_core.dart';

/// Assumed average city speed for the prefilled pickup ETA.
const etaSpeedKmh = 25.0;

/// ETA to pickup in minutes from the straight distance: ≈ km / 25 km/h,
/// at least 1 and at most 60 (the server's bound).
int etaMinutesFor(double distanceKm) => (distanceKm / etaSpeedKmh * 60).ceil().clamp(1, 60);

/// A round stepper increment: about a tenth of the allowed range.
int priceStep(int min, int max) {
  final raw = (max - min) / 10;
  const nice = [1000, 500, 250, 100, 50, 25, 10, 5, 1];
  return nice.firstWhere((n) => n <= raw, orElse: () => 1);
}

/// Live requests only: drops cards whose time is up.
List<RequestCard> liveRequests(List<RequestCard> cards, DateTime now) =>
    cards.where((c) => c.expiresAt.isAfter(now)).toList()..sort((a, b) => a.distanceToPickupKm.compareTo(b.distanceToPickupKm));

/// The offer the driver is composing. Price stays within the rider's quote bounds.
class OfferDraft {
  OfferDraft.forCard(RequestCard card)
      : min = card.minFare,
        max = card.maxFare,
        step = priceStep(card.minFare, card.maxFare),
        price = card.proposedFare.clamp(card.minFare, card.maxFare),
        eta = etaMinutesFor(card.distanceToPickupKm);
  final int min, max, step;
  int price;
  int eta;

  bool get canRaise => price < max;
  bool get canLower => price > min;
  bool get canRaiseEta => eta < 60;
  bool get canLowerEta => eta > 1;
  void raise() => price = (price + step).clamp(min, max);
  void lower() => price = (price - step).clamp(min, max);
  void raiseEta() => eta = (eta + 1).clamp(1, 60);
  void lowerEta() => eta = (eta - 1).clamp(1, 60);
}
