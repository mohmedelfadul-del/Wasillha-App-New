import '../../../app/live.dart';

class AuditEntry {
  const AuditEntry({required this.id, required this.actor, required this.role, required this.action, required this.target, required this.data, required this.at});
  final String id;
  final String actor;
  final String role;
  final String action;
  final String target;
  final Map<String, dynamic> data;
  final DateTime at;
}

abstract class AuditRepository {
  /// Newest first. Read-only: the audit log is immutable.
  Stream<Live<List<AuditEntry>>> recent({int limit = 50});
}
