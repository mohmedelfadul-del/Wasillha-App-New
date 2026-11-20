import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';

class CaseRecord {
  const CaseRecord(this.c, {this.resolution, this.resolvedBy, this.updatedAt, this.subjectDriverId});
  final SupportCase c;
  final String? resolution;
  final String? resolvedBy;
  final DateTime? updatedAt;
  final String? subjectDriverId;

  bool get urgent => c.priority == 'urgent';
  bool get open => c.status == 'open' || c.status == 'inProgress';
}

abstract class CasesRepository {
  /// Cases with status open or inProgress, oldest first.
  Stream<Live<List<CaseRecord>>> open({int limit = 300});
  Stream<Live<CaseRecord?>> watch(String id);
  Future<void> claim(String caseId, IntentKey key);
  Future<void> close(String caseId, String resolution, IntentKey key);
}
