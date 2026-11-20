import 'package:wa3_core/wa3_core.dart';

class TripPage {
  const TripPage({required this.trips, required this.cursor, required this.hasMore});
  final List<Trip> trips;

  /// Opaque position for the next page.
  final Object? cursor;
  final bool hasMore;
}

const historyPageSize = 20;

abstract class HistoryRepository {
  /// trips where driverId == uid order by createdAt desc, [historyPageSize] per page.
  Future<TripPage> page(String uid, {Object? after});
}
