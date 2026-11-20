import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/data_errors.dart';
import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/people_repository.dart';

class FirestorePeopleRepository implements PeopleRepository {
  FirestorePeopleRepository(this._db);
  final FirebaseFirestore _db;

  static RiderRecord _rider(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return RiderRecord(uid: d.id, name: (m['name'] ?? '').toString(), phone: (m['phone'] ?? '').toString(), lang: m['lang'] as String?, createdAt: millisToDate(m['createdAt']));
  }

  static DriverProfile _driver(DocumentSnapshot<Json> d) => DriverProfile.fromJson(d.id, d.data() ?? const {});

  @override
  Future<List<RiderRecord>> ridersByPhone(String phone) =>
      guarded(() async => (await _db.collection('riders').where('phone', isEqualTo: phone).limit(10).get()).docs.map(_rider).toList());

  @override
  Future<List<DriverProfile>> driversByPhone(String phone) =>
      guarded(() async => (await _db.collection('drivers').where('phone', isEqualTo: phone).limit(10).get()).docs.map(_driver).toList());

  @override
  Future<RiderRecord?> rider(String uid) => guarded(() async {
        final d = await _db.collection('riders').doc(uid).get();
        return d.exists ? _rider(d) : null;
      });

  @override
  Future<DriverProfile?> driver(String uid) => guarded(() async {
        final d = await _db.collection('drivers').doc(uid).get();
        return d.exists ? _driver(d) : null;
      });

  @override
  Stream<Live<RiderRecord?>> watchRider(String uid) => _db.collection('riders').doc(uid).live(_rider);

  @override
  Stream<Live<DriverProfile?>> watchDriver(String uid) => _db.collection('drivers').doc(uid).live(_driver);

  @override
  Stream<Live<List<ReviewDocument>>> driverDocuments(String uid) =>
      _db.collection('drivers').doc(uid).collection('documents').live((d) => ReviewDocument.fromJson(d.reference.path, d.data() ?? const {}));

  @override
  Stream<Live<List<Vehicle>>> vehicles(String driverId) =>
      _db.collection('vehicles').where('driverId', isEqualTo: driverId).live((d) => Vehicle.fromJson(d.id, d.data() ?? const {}));
}
