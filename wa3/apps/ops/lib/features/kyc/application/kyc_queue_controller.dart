import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wa3_core/wa3_core.dart';

import '../domain/kyc_repository.dart';

/// Pending KYC queue. Each change on the realtime list signals a heavier
/// re-read of who the documents belong to (driver/vehicle), coalesced so a
/// burst of submissions costs one round of reads.
class KycQueueController extends ChangeNotifier {
  KycQueueController(this._repo) {
    _labels = RefreshCoalescer(_readSubjects);
    _listen();
  }

  final KycRepository _repo;
  late final RefreshCoalescer _labels;
  StreamSubscription<dynamic>? _sub;
  List<ReviewDocument>? items;
  bool fromCache = false;
  Object? error;
  final subjects = <String, ReviewSubject>{};
  bool _disposed = false;

  void _listen() {
    _sub?.cancel();
    _sub = _repo.pending().listen((live) {
      items = live.value;
      fromCache = live.fromCache;
      error = null;
      _notify();
      _labels.signal();
    }, onError: (Object e) {
      error = e;
      _notify();
    });
  }

  Future<void> _readSubjects() async {
    final missing = (items ?? const <ReviewDocument>[]).where((d) => !subjects.containsKey(d.path)).toList();
    if (missing.isEmpty) return;
    await Future.wait(missing.map((d) async {
      try {
        subjects[d.path] = await _repo.subject(d);
      } catch (_) {
        // Label stays unknown; the row still shows ids.
      }
    }));
    _notify();
  }

  void retry() {
    error = null;
    items = null;
    _notify();
    _listen();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _labels.dispose();
    _sub?.cancel();
    super.dispose();
  }
}
