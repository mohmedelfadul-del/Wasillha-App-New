import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/document_repository.dart';

class FirebaseDocumentRepository implements DocumentRepository {
  FirebaseDocumentRepository(this._db, this._storage, this._api);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final WasilhaApi _api;

  Stream<Live<Map<DocumentType, ReviewDocument>>> _watch(CollectionReference<Map<String, dynamic>> col) =>
      col.snapshots(includeMetadataChanges: true).map((q) => Live(
            {for (final d in q.docs) DocumentType.parse(d.id): ReviewDocument.fromJson(d.reference.path, d.data())},
            fromCache: q.metadata.isFromCache,
          ));

  @override
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchDriverDocuments(String uid) =>
      _watch(_db.collection('drivers').doc(uid).collection('documents'));

  @override
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchVehicleDocuments(String vehicleId) =>
      _watch(_db.collection('vehicles').doc(vehicleId).collection('documents'));

  @override
  Stream<List<ReviewDocument>> watchAllVehicleDocuments(String uid) => switchCombine<String, List<ReviewDocument>>(
        _db.collection('vehicles').where('driverId', isEqualTo: uid).snapshots().map((q) => q.docs.map((d) => d.id).toList()),
        (id) => watchVehicleDocuments(id).map((l) => l.data.values.toList()),
      ).map((m) => m.values.expand((e) => e).toList());

  @override
  Future<void> upload({required String storagePath, required Uint8List bytes, required void Function(double) onProgress}) async {
    final task = _storage.ref(storagePath).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});
    try {
      await task;
    } on FirebaseException catch (e) {
      throw ApiFailure(e.code == 'unauthorized' ? 'permission_denied' : 'network', e.message ?? e.code);
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> submit({required DocumentType type, required String storagePath, String? vehicleId, required IntentKey key}) =>
      _api.submitDocument(type: type.name, storagePath: storagePath, vehicleId: vehicleId, key: key);
}
