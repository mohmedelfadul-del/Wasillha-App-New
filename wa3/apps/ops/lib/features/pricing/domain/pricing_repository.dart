import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

class Zone {
  const Zone({required this.id, required this.name, required this.active});
  final String id;
  final String name;
  final bool active;
}

/// Stored pricing (pricing/{zoneId}__{category}). Whole currency units.
class PricingRecord {
  const PricingRecord({
    required this.baseFare,
    required this.perKm,
    required this.perMinute,
    required this.minFare,
    required this.maxFare,
    required this.belowReferencePct,
    required this.aboveReferencePct,
    required this.commissionBps,
    required this.enabled,
    this.version = 0,
    this.updatedBy,
    this.updatedAt,
  });
  final int baseFare, perKm, perMinute, minFare, maxFare, commissionBps;
  final double belowReferencePct, aboveReferencePct;
  final bool enabled;
  final int version;
  final String? updatedBy;
  final DateTime? updatedAt;

  Map<String, dynamic> toConfig() => {
        'baseFare': baseFare,
        'perKm': perKm,
        'perMinute': perMinute,
        'minFare': minFare,
        'maxFare': maxFare,
        'belowReferencePct': belowReferencePct,
        'aboveReferencePct': aboveReferencePct,
        'commissionBps': commissionBps,
      };
}

abstract class PricingRepository {
  Stream<Live<List<Zone>>> zones();
  Stream<Live<PricingRecord?>> watch(String zoneId, Category category);

  /// Returns the new version.
  Future<int> update({required String zoneId, required Category category, required PricingRecord config, required String reason, required IntentKey key});
}
