import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/cadence_policy.dart';
import '../domain/location_port.dart';

/// Streams GPS and writes presence on the [CadencePolicy] cadence while the
/// driver is online or on a trip. A 1 s tick re-evaluates the policy so the
/// stationary heartbeat goes out even when the GPS stream is quiet.
class LocationService extends ChangeNotifier {
  LocationService({required this.source, required this.sink, this.policy = const CadencePolicy(), DateTime Function()? clock, this.tick = const Duration(seconds: 1)})
      : _clock = clock ?? DateTime.now;
  final LocationSource source;
  final PresenceSink sink;
  final CadencePolicy policy;
  final Duration tick;
  final DateTime Function() _clock;

  LocationAccess? access;
  bool running = false;
  Fix? lastFix;
  DateTime? lastWriteAt;

  /// The last presence write failed (offline, rules).
  bool writeFailing = false;

  String? _uid;
  Fix? _lastSent;
  StreamSubscription<Fix>? _sub;
  Timer? _timer;
  bool _writing = false;
  Completer<void>? _firstWrite;

  Future<LocationAccess> refreshAccess() async {
    access = await source.check();
    notifyListeners();
    return access!;
  }

  Future<LocationAccess> requestAccess() async {
    access = await source.request();
    notifyListeners();
    return access!;
  }

  void start(String uid) {
    if (running && _uid == uid) return;
    stop();
    _uid = uid;
    running = true;
    _firstWrite = Completer<void>();
    _sub = source.fixes().listen((f) {
      lastFix = f;
      _evaluate();
    }, onError: (_) {
      writeFailing = true;
      notifyListeners();
    });
    _timer = Timer.periodic(tick, (_) => _evaluate());
    notifyListeners();
  }

  /// Completes true once a presence write has succeeded since [start].
  Future<bool> waitForFirstWrite(Duration timeout) async {
    final c = _firstWrite;
    if (c == null) return false;
    try {
      await c.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _evaluate() async {
    final fix = lastFix, uid = _uid;
    if (!running || fix == null || uid == null || _writing) return;
    final now = _clock();
    if (!policy.shouldSend(now: now, fix: fix, lastSent: _lastSent, lastSentAt: lastWriteAt)) return;
    _writing = true;
    try {
      await sink.write(uid, fix);
      _lastSent = fix;
      lastWriteAt = now;
      writeFailing = false;
      if (!(_firstWrite?.isCompleted ?? true)) _firstWrite!.complete();
    } catch (_) {
      writeFailing = true;
    } finally {
      _writing = false;
    }
    if (running) notifyListeners();
  }

  void stop() {
    _sub?.cancel();
    _timer?.cancel();
    _sub = null;
    _timer = null;
    final wasRunning = running;
    running = false;
    _lastSent = null;
    lastWriteAt = null;
    _uid = null;
    if (wasRunning) notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
