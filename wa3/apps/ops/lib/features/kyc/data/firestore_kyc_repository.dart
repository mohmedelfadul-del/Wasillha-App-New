import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/data_errors.dart';
import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/kyc_repository.dart';

class FirestoreKycRepository implements KycRepository {
  FirestoreKycRepository(this._db, this._storage, this._api);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final WasilhaApi _api;
  final _subjects = <String, Future<ReviewSubject>>{};

  static ReviewDocument _doc(DocumentSnapshot<Json> d) => ReviewDocument.fromJson(d.reference.path, d.data() ?? const {});

  @override
  Stream<Live<List<ReviewDocument>>> pending({int limit = 100}) =>
      _db.collectionGroup('documents').where('status', isEqualTo: 'pending').orderBy('submittedAt').limit(limit).live(_doc);

  @override
  Stream<Live<ReviewDocument?>> watch(String path) => _db.doc(path).live(_doc);

  @override
  Future<ReviewSubject> subject(ReviewDocument d) {
    final key = '${d.driverId}/${d.vehicleId ?? ''}';
    return _subjects[key] ??= guarded(() async {
      final driver = await _db.collection('drivers').doc(d.driverId).get();
      Json? v;
      if (d.vehicleId != null) v = (await _db.collection('vehicles').doc(d.vehicleId).get()).data();
      final vehicle = v == null ? null : Vehicle.fromJson(d.vehicleId!, v);
      return ReviewSubject(
        driverName: (driver.data()?['name'] as String?) ?? d.driverId,
        driverPhone: driver.data()?['phone'] as String?,
        vehicleTitle: vehicle == null ? null : '${vehicle.color} ${vehicle.make} ${vehicle.model} ${vehicle.year}'.trim(),
        plate: vehicle?.plate,
      );
    }).catchError((Object e) {
      _subjects.remove(key);
      throw e;
    });
  }

  @override
  Future<String> downloadUrl(String storagePath) => guarded(() => _storage.ref(storagePath).getDownloadURL());

  @override
  Future<void> claim(String path, IntentKey key) => _api.claimReview(path: path, key: key);

  @override
  Future<void> decide(String path, Decision decision, String? reason, IntentKey key) =>
      _api.decideReview(path: path, decision: decision.name, reason: reason, key: key);
}
