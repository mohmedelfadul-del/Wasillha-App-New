import '../../../app/live.dart';

enum QueueKind { kycPending, urgentSafety, openCases, flaggedTrips }

/// One work queue: how much is waiting, the oldest item's age and who owns it.
class QueueSummary {
  const QueueSummary({
    required this.kind,
    required this.count,
    this.countIsLowerBound = false,
    this.oldestAt,
    this.oldestOwner,
    this.unowned = 0,
    this.stuck = 0,
    this.stale = 0,
  });
  final QueueKind kind;
  final int count;

  /// True when [count] was capped by a page limit ("50+").
  final bool countIsLowerBound;
  final DateTime? oldestAt;

  /// uid holding the oldest item (claim / case owner), null when unowned.
  final String? oldestOwner;
  final int unowned;

  /// Flagged trips only.
  final int stuck, stale;
}

abstract class CockpitRepository {
  Stream<Live<QueueSummary>> watch(QueueKind kind);
}
