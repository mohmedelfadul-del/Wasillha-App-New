import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/pricing_repository.dart';

class FirestorePricingRepository implements PricingRepository {
  FirestorePricingRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;
  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

  @override
  Stream<Live<List<Zone>>> zones() => _db.collection('zones').live((d) {
        final m = d.data() ?? const <String, dynamic>{};
        return Zone(id: d.id, name: (m['name'] ?? d.id).toString(), active: m['active'] != false);
      });

  @override
  Stream<Live<PricingRecord?>> watch(String zoneId, Category category) => _db.collection('pricing').doc('${zoneId}__${category.name}').live((d) {
        final m = d.data() ?? const <String, dynamic>{};
        return PricingRecord(
          baseFare: _i(m['baseFare']),
          perKm: _i(m['perKm']),
          perMinute: _i(m['perMinute']),
          minFare: _i(m['minFare']),
          maxFare: _i(m['maxFare']),
          belowReferencePct: _d(m['belowReferencePct']),
          aboveReferencePct: _d(m['aboveReferencePct']),
          commissionBps: _i(m['commissionBps']),
          enabled: m['enabled'] != false,
          version: _i(m['version']),
          updatedBy: m['updatedBy'] as String?,
          updatedAt: millisToDate(m['updatedAt']),
        );
      });

  @override
  Future<int> update({required String zoneId, required Category category, required PricingRecord config, required String reason, required IntentKey key}) async {
    final r = await _api.updatePricing(zoneId: zoneId, category: category.name, config: config.toConfig(), enabled: config.enabled, reason: reason, key: key);
    return (r['version'] as num?)?.toInt() ?? 0;
  }
}
