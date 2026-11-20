import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../../../app/live.dart';
import '../domain/stage_action.dart';
import '../domain/trip_repository.dart';

/// Renders trips/{id} as the server reports it and drives the stage commands.
/// On driverAssigned it acknowledges once by itself (idempotent server-side).
class ActiveTripController extends ChangeNotifier {
  ActiveTripController({required this.repo, required this.tripId}) {
    _sub = repo.watchTrip(tripId).listen(_onTrip, onError: (Object e) {
      loadError = e;
      notifyListeners();
    });
  }
  final TripRepository repo;
  final String tripId;
  StreamSubscription<Live<Trip?>>? _sub;

  Live<Trip?>? live;
  Object? loadError;

  /// The automatic acknowledgement failed; [retryAck] tries again.
  ApiFailure? ackError;
  bool acking = false;
  IntentKey? _ackKey;
  int? _ackedRevision;

  Trip? get trip => live?.data;
  bool get loading => live == null && loadError == null;

  void _onTrip(Live<Trip?> l) {
    live = l;
    loadError = null;
    final t = l.data;
    if (t != null && t.state == TripState.driverAssigned && !acking && _ackedRevision != t.revision && ackError == null) {
      unawaited(_ack(t));
    }
    if (t != null && t.state != TripState.driverAssigned) ackError = null;
    notifyListeners();
  }

  Future<void> _ack(Trip t) async {
    acking = true;
    _ackedRevision = t.revision;
    _ackKey ??= IntentKey.generate();
    notifyListeners();
    try {
      await repo.stage('ackAssignment', tripId: tripId, expectedRevision: t.revision, key: _ackKey!);
    } on ApiFailure catch (e) {
      // A stale revision means a new snapshot is coming: ack again from it.
      if (e.isStale) {
        _ackedRevision = null;
        _ackKey = null;
      } else {
        ackError = e;
      }
    } finally {
      acking = false;
      notifyListeners();
    }
  }

  Future<void> retryAck() async {
    final t = trip;
    if (t == null || t.state != TripState.driverAssigned) return;
    ackError = null;
    await _ack(t);
  }

  /// The stage command for the rendered state (not recordCash: that needs an amount).
  Future<void> runStage(StageCommand c) async {
    final t = trip;
    if (t == null || stageCommandFor(t.state) != c || c == StageCommand.recordCash) return;
    await repo.stage(c.name, tripId: tripId, expectedRevision: t.revision, key: IntentKey.generate());
  }

  Future<void> recordCash(int amount) async {
    final t = trip!;
    await repo.recordCash(tripId: tripId, amount: amount, expectedRevision: t.revision, key: IntentKey.generate());
  }

  Future<void> cancel(String reason, String? note) async {
    final t = trip!;
    await repo.cancel(tripId: tripId, reason: reason, note: note, expectedRevision: t.revision, key: IntentKey.generate());
  }

  Future<void> rate(int stars, String? comment) => repo.rateRider(tripId: tripId, stars: stars, comment: comment, key: IntentKey.generate());

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
