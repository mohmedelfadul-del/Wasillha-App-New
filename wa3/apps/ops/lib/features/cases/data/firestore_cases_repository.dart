import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/cases_repository.dart';

class FirestoreCasesRepository implements CasesRepository {
  FirestoreCasesRepository(this._db, this._api);
  final FirebaseFirestore _db;
  final WasilhaApi _api;

  static CaseRecord _case(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return CaseRecord(
      SupportCase.fromJson(d.id, m),
      resolution: m['resolution'] as String?,
      resolvedBy: m['resolvedBy'] as String?,
      updatedAt: millisToDate(m['updatedAt']),
      subjectDriverId: m['subjectDriverId'] as String?,
    );
  }

  @override
  Stream<Live<List<CaseRecord>>> open({int limit = 300}) =>
      _db.collection('cases').where('status', whereIn: ['open', 'inProgress']).orderBy('createdAt').limit(limit).live(_case);

  @override
  Stream<Live<CaseRecord?>> watch(String id) => _db.collection('cases').doc(id).live(_case);

  @override
  Future<void> claim(String caseId, IntentKey key) => _api.claimCase(caseId: caseId, key: key);

  @override
  Future<void> close(String caseId, String resolution, IntentKey key) => _api.closeCase(caseId: caseId, resolution: resolution, key: key);
}
