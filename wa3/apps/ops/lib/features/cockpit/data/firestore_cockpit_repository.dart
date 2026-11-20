import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/data_errors.dart';
import '../../../app/firestore_x.dart';
import '../../../app/live.dart';
import '../../kyc/domain/kyc_repository.dart';
import '../../trips/data/firestore_trips_repository.dart' show tripRecordOf;
import '../../trips/domain/trips_repository.dart';
import '../domain/cockpit_repository.dart';

/// Queues from the indexed queries. Drivers owing commission is not cheaply
/// queryable (derived from the ledger), so it is not a cockpit queue.
class FirestoreCockpitRepository implements CockpitRepository {
  FirestoreCockpitRepository(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;
  final FirebaseFirestore _db;
  final DateTime Function() _now;
  static const _page = 50;
  static const _casePage = 300;

  @override
  Stream<Live<QueueSummary>> watch(QueueKind kind) => switch (kind) {
        QueueKind.kycPending => _kyc(),
        QueueKind.urgentSafety => _cases(urgentSafety: true),
        QueueKind.openCases => _cases(urgentSafety: false),
        QueueKind.flaggedTrips => _trips(),
      };

  /// The page stream gives the oldest items; a total count is re-read on each
  /// change signal, coalesced so a burst of submissions costs one aggregate read.
  Stream<Live<QueueSummary>> _kyc() {
    final q = _db.collectionGroup('documents').where('status', isEqualTo: 'pending').orderBy('submittedAt');
    late final StreamController<Live<QueueSummary>> c;
    StreamSubscription<QuerySnapshot<Json>>? sub;
    RefreshCoalescer? counter;
    QuerySnapshot<Json>? last;
    int? total;

    void emit() {
      final s = last;
      if (s == null || c.isClosed) return;
      final now = _now();
      final docs = s.docs.map((d) => ReviewDocument.fromJson(d.reference.path, d.data())).toList();
      String? holder(ReviewDocument d) => claimStateOf(d, '', now) == ClaimState.other ? d.claimedBy : null;
      c.add(Live(
        QueueSummary(
          kind: QueueKind.kycPending,
          count: total ?? docs.length,
          countIsLowerBound: total == null && docs.length >= _page,
          oldestAt: docs.isEmpty ? null : docs.first.submittedAt,
          oldestOwner: docs.isEmpty ? null : holder(docs.first),
          unowned: docs.where((d) => holder(d) == null).length,
        ),
        fromCache: s.metadata.isFromCache,
      ));
    }

    c = StreamController<Live<QueueSummary>>(
      onListen: () {
        counter = RefreshCoalescer(() async {
          try {
            total = (await q.count().get()).count;
          } catch (_) {
            total = null; // fall back to the page count ("50+")
          }
          emit();
        });
        sub = q.limit(_page).snapshots(includeMetadataChanges: true).listen((s) {
          final changed = last == null || s.docChanges.isNotEmpty;
          last = s;
          emit();
          if (changed) counter!.signal();
        }, onError: (Object e) => c.addError(toFailure(e)));
      },
      onCancel: () async {
        counter?.dispose();
        await sub?.cancel();
      },
    );
    return c.stream;
  }

  Stream<Live<QueueSummary>> _cases({required bool urgentSafety}) {
    final kind = urgentSafety ? QueueKind.urgentSafety : QueueKind.openCases;
    return _db
        .collection('cases')
        .where('status', whereIn: ['open', 'inProgress'])
        .orderBy('createdAt')
        .limit(_casePage)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final all = s.docs.map((d) => SupportCase.fromJson(d.id, d.data())).toList();
      final mine = all.where((c) => (c.type == CaseType.safety && c.priority == 'urgent') == urgentSafety).toList();
      return Live(
        QueueSummary(
          kind: kind,
          count: mine.length,
          countIsLowerBound: s.docs.length >= _casePage,
          oldestAt: mine.isEmpty ? null : mine.first.createdAt,
          oldestOwner: mine.isEmpty ? null : mine.first.ownerId,
          unowned: mine.where((c) => c.ownerId == null).length,
        ),
        fromCache: s.metadata.isFromCache,
      );
    }).mapFailures();
  }

  Stream<Live<QueueSummary>> _trips() {
    return _db
        .collection('trips')
        .where('state', whereIn: liveStates.map((s) => s.name).toList())
        .orderBy('updatedAt')
        .limit(300)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      final flagged = s.docs.map(tripRecordOf).where((t) => t.flagged).toList()..sort((a, b) => a.stateSince.compareTo(b.stateSince));
      return Live(
        QueueSummary(
          kind: QueueKind.flaggedTrips,
          count: flagged.length,
          countIsLowerBound: s.docs.length >= 300,
          oldestAt: flagged.isEmpty ? null : flagged.first.stateSince,
          stuck: flagged.where((t) => t.trip.stuck).length,
          stale: flagged.where((t) => t.trip.locationStale).length,
        ),
        fromCache: s.metadata.isFromCache,
      );
    }).mapFailures();
  }
}
