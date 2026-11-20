import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/driver_repository.dart';

class FirebaseDriverRepository implements DriverRepository {
  FirebaseDriverRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Stream<Live<DriverState?>> watchDriver(String uid) =>
      _db.collection('drivers').doc(uid).snapshots(includeMetadataChanges: true).map((s) {
        final m = s.data();
        if (m == null) return Live<DriverState?>(null, fromCache: s.metadata.isFromCache);
        final u = m['updatedAt'];
        return Live<DriverState?>(
          DriverState(
            profile: DriverProfile.fromJson(uid, m),
            ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
            updatedAt: u is num ? DateTime.fromMillisecondsSinceEpoch(u.toInt()) : null,
          ),
          fromCache: s.metadata.isFromCache,
        );
      });

  @override
  Future<void> register({required String name, required IntentKey key}) => _api.registerDriver(name: name, key: key);

  @override
  Future<void> setActiveVehicle({required String vehicleId, required IntentKey key}) => _api.setActiveVehicle(vehicleId: vehicleId, key: key);

  @override
  Future<void> goOnline() => _api.goOnline();

  @override
  Future<void> goOffline() => _api.goOffline();
}
