import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../common/data/firestore_errors.dart';
import '../../common/domain/live.dart';
import '../domain/profile_repository.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._db, this._auth, this._api);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final WasilhaApi _api;

  @override
  Stream<Live<RiderProfile?>> watch() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.error(const ApiFailure('permission_denied', 'Not signed in'));
    return _db
        .collection('riders')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .map((d) => Live(d.exists ? RiderProfile.fromJson(d.data()!) : null, fromCache: d.metadata.isFromCache))
        .transform(mapFirestoreErrors());
  }

  @override
  Future<void> register({required String name, required String lang, required IntentKey key}) =>
      _api.registerRider(name: name, lang: lang, key: key);
}
