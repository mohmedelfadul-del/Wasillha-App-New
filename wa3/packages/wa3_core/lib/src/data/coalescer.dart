import 'dart:async';

/// Re-read on signal, coalescing bursts: at most one read in flight and at
/// most one pending. Used where a realtime signal triggers an authoritative
/// re-read (e.g. operations lists refreshed on change notifications).
class RefreshCoalescer {
  RefreshCoalescer(this._read);
  final Future<void> Function() _read;
  bool _inFlight = false;
  bool _pending = false;
  bool _disposed = false;

  void signal() {
    if (_disposed) return;
    if (_inFlight) {
      _pending = true;
      return;
    }
    _run();
  }

  Future<void> _run() async {
    _inFlight = true;
    try {
      await _read();
    } catch (_) {
      // The caller's read surfaces its own error state.
    } finally {
      _inFlight = false;
      if (_pending && !_disposed) {
        _pending = false;
        unawaited(_run());
      }
    }
  }

  bool get busy => _inFlight;
  void dispose() => _disposed = true;
}
