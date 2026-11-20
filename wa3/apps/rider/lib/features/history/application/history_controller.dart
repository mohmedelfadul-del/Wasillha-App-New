import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:wa3_core/wa3_core.dart';

import '../../trips/domain/trip_repository.dart';

/// Own trips, newest first, 20 per page.
class HistoryController extends ChangeNotifier {
  HistoryController(this._trips, {this.pageSize = 20});
  final TripRepository _trips;
  final int pageSize;

  final List<Trip> trips = [];
  Object? _cursor;
  bool hasMore = true;
  bool loading = false;
  Object? error;
  bool loadedOnce = false;
  bool _disposed = false;

  /// Drafts never sent (and their silent expiry) aren't trips to the rider.
  static bool visible(Trip t) => t.state != TripState.draft && t.cancellation?.reason != 'draft_expired';

  Future<void> refresh() async {
    trips.clear();
    _cursor = null;
    hasMore = true;
    loadedOnce = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    _notify();
    try {
      final page = await _trips.history(after: _cursor, limit: pageSize);
      trips.addAll(page.trips.where(visible));
      _cursor = page.cursor;
      hasMore = page.hasMore;
      loadedOnce = true;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
