import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../domain/audit_repository.dart';

class FirestoreAuditRepository implements AuditRepository {
  FirestoreAuditRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Stream<Live<List<AuditEntry>>> recent({int limit = 50}) => _db.collection('audit').orderBy('at', descending: true).limit(limit).live((d) {
        final m = d.data() ?? const <String, dynamic>{};
        return AuditEntry(
          id: d.id,
          actor: (m['actor'] ?? '').toString(),
          role: (m['role'] ?? '').toString(),
          action: (m['action'] ?? '').toString(),
          target: (m['target'] ?? '').toString(),
          data: m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : const {},
          at: millisToDate(m['at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });
}
