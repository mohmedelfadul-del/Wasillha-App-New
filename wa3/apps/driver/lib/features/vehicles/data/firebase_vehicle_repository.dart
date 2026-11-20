import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/vehicle_repository.dart';

class FirebaseVehicleRepository implements VehicleRepository {
  FirebaseVehicleRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  @override
  Stream<Live<List<Vehicle>>> watchVehicles(String uid) => _db
      .collection('vehicles')
      .where('driverId', isEqualTo: uid)
      .snapshots(includeMetadataChanges: true)
      .map((q) => Live(q.docs.map((d) => Vehicle.fromJson(d.id, d.data())).toList(), fromCache: q.metadata.isFromCache));

  @override
  Future<String> add(NewVehicle v, {required IntentKey key}) => _api.addVehicle(
        category: v.category.name,
        make: v.make,
        model: v.model,
        color: v.color,
        plate: v.plate,
        year: v.year,
        key: key,
      );
}
