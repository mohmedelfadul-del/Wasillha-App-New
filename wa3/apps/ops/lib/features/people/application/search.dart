import 'package:wa3_core/wa3_core.dart';

import '../../trips/domain/trips_repository.dart';
import '../domain/people_repository.dart';

class SearchResults {
  const SearchResults({this.trip, this.riders = const [], this.drivers = const [], this.failures = const []});
  final TripRecord? trip;
  final List<RiderRecord> riders;
  final List<DriverProfile> drivers;

  /// Lookups that failed (e.g. permission denied); other results still show.
  final List<ApiFailure> failures;
  bool get isEmpty => trip == null && riders.isEmpty && drivers.isEmpty;
}

final _idPattern = RegExp(r'^[A-Za-z0-9_-]{4,128}$');

/// Exact lookups only (Firestore equality): trip id, rider/driver id, phone.
Future<SearchResults> searchEverything(String raw, {required PeopleRepository people, required TripsRepository trips}) async {
  final q = raw.trim();
  final failures = <ApiFailure>[];
  Future<T?> attempt<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on ApiFailure catch (e) {
      failures.add(e);
      return null;
    }
  }

  final phone = normalizePhone(q);
  final phones = phone == null ? const <String>[] : {phone, if (!phone.startsWith('+')) '+$phone'}.toList();
  final isId = _idPattern.hasMatch(q);

  final results = await Future.wait<Object?>([
    if (isId) attempt<TripRecord?>(() => trips.get(q)) else Future.value(null),
    if (isId) attempt<RiderRecord?>(() => people.rider(q)) else Future.value(null),
    if (isId) attempt<DriverProfile?>(() => people.driver(q)) else Future.value(null),
    for (final p in phones) attempt(() => people.ridersByPhone(p)),
    for (final p in phones) attempt(() => people.driversByPhone(p)),
  ]);

  final riders = <String, RiderRecord>{};
  final drivers = <String, DriverProfile>{};
  if (results[1] is RiderRecord) riders[(results[1] as RiderRecord).uid] = results[1] as RiderRecord;
  if (results[2] is DriverProfile) drivers[(results[2] as DriverProfile).uid] = results[2] as DriverProfile;
  for (final r in results.skip(3)) {
    if (r is List<RiderRecord>) {
      for (final x in r) {
        riders[x.uid] = x;
      }
    }
    if (r is List<DriverProfile>) {
      for (final x in r) {
        drivers[x.uid] = x;
      }
    }
  }
  return SearchResults(trip: results[0] as TripRecord?, riders: riders.values.toList(), drivers: drivers.values.toList(), failures: failures);
}
