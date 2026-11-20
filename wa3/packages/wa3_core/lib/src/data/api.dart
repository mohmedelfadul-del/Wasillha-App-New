import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

/// A failure reported by the server (or the network), with the contract's
/// error code so the UI can explain exactly what happened.
class ApiFailure implements Exception {
  const ApiFailure(this.code, this.message, [this.details = const {}]);
  final String code;
  final String message;
  final Map<String, dynamic> details;

  bool get isNetwork => code == 'network';
  bool get isStale => code == 'stale_revision';
  @override
  String toString() => '$code: $message';
}

/// Idempotency key for one user intent (one tap). Retries of the same intent
/// reuse the key; a new tap creates a new key.
class IntentKey {
  IntentKey._(this.value);
  final String value;
  static final _rng = Random.secure();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
  factory IntentKey.generate() => IntentKey._(List.generate(24, (_) => _chars[_rng.nextInt(_chars.length)]).join());
}

/// Typed client for every backend command. Mutating commands carry an
/// idempotency key and (for trip transitions) the expected revision.
class WasilhaApi {
  WasilhaApi({FirebaseFunctions? functions}) : _fns = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirebaseFunctions _fns;

  static const _retryable = {'unavailable', 'deadline-exceeded', 'internal', 'network'};

  /// Calls [name]. Network-level failures are retried twice with the SAME key,
  /// so a retry after a dropped response can never act twice.
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data, {IntentKey? key, bool mutating = true}) async {
    final payload = {...data, if (mutating) 'idempotencyKey': (key ?? IntentKey.generate()).value};
    ApiFailure? last;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await _fns.httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 20))).call<dynamic>(payload);
        final d = res.data;
        return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
      } on FirebaseFunctionsException catch (e) {
        last = _map(e);
        if (!_retryable.contains(e.code) || !mutating && attempt > 0) break;
      } on TimeoutException {
        last = const ApiFailure('network', 'The connection timed out');
      } catch (e) {
        last = ApiFailure('network', e.toString());
      }
      await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
    }
    throw last!;
  }

  ApiFailure _map(FirebaseFunctionsException e) {
    final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : <String, dynamic>{};
    final code = (details['code'] as String?) ?? (e.code == 'unavailable' ? 'network' : e.code);
    return ApiFailure(code, e.message ?? code, details);
  }

  // ── Rider ────────────────────────────────────────────────
  Future<void> registerRider({required String name, required String lang, IntentKey? key}) =>
      call('registerRider', {'name': name, 'lang': lang}, key: key);

  Future<Map<String, dynamic>> createDraft({required Map<String, dynamic> pickup, required Map<String, dynamic> dropoff, required String category, IntentKey? key}) =>
      call('createDraft', {'pickup': pickup, 'dropoff': dropoff, 'category': category}, key: key);

  Future<Map<String, dynamic>> confirmRequest({required String tripId, required int proposedFare, required int expectedRevision, IntentKey? key}) =>
      call('confirmRequest', {'tripId': tripId, 'proposedFare': proposedFare, 'expectedRevision': expectedRevision}, key: key);

  Future<Map<String, dynamic>> acceptOffer({required String tripId, required String offerId, required int expectedRevision, IntentKey? key}) =>
      call('acceptOffer', {'tripId': tripId, 'offerId': offerId, 'expectedRevision': expectedRevision}, key: key);

  Future<Map<String, dynamic>> cancelTrip({required String tripId, required String reason, String? note, required int expectedRevision, IntentKey? key}) =>
      call('cancelTrip', {'tripId': tripId, 'reason': reason, 'note': ?note, 'expectedRevision': expectedRevision}, key: key);

  Future<void> rateTrip({required String tripId, required int stars, String? comment, IntentKey? key}) =>
      call('rateTrip', {'tripId': tripId, 'stars': stars, 'comment': ?comment}, key: key);

  Future<Map<String, dynamic>> disputeTrip({required String tripId, required String reason, required int expectedRevision, IntentKey? key}) =>
      call('disputeTrip', {'tripId': tripId, 'reason': reason, 'expectedRevision': expectedRevision}, key: key);

  Future<Map<String, dynamic>> reportSafety({required String tripId, required String description, IntentKey? key}) =>
      call('reportSafety', {'tripId': tripId, 'description': description}, key: key);

  Future<String> shareTrip({required String tripId, IntentKey? key}) async =>
      (await call('shareTrip', {'tripId': tripId}, key: key))['token'] as String;

  Future<List<Map<String, dynamic>>> placesSearch({required String query, required double lat, required double lng, required String lang}) async {
    final r = await call('placesSearch', {'query': query, 'near': {'lat': lat, 'lng': lng}, 'lang': lang}, mutating: false);
    return ((r['results'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<String> placeLabel({required double lat, required double lng, required String lang}) async =>
      (await call('placeLabel', {'point': {'lat': lat, 'lng': lng}, 'lang': lang}, mutating: false))['label'] as String;

  // ── Driver ───────────────────────────────────────────────
  Future<void> registerDriver({required String name, IntentKey? key}) => call('registerDriver', {'name': name}, key: key);

  Future<void> submitDocument({required String type, required String storagePath, String? vehicleId, IntentKey? key}) =>
      call('submitDocument', {'type': type, 'storagePath': storagePath, 'vehicleId': ?vehicleId}, key: key);

  Future<String> addVehicle({required String category, required String make, required String model, required String color, required String plate, required int year, IntentKey? key}) async =>
      (await call('addVehicle', {'category': category, 'make': make, 'model': model, 'color': color, 'plate': plate, 'year': year}, key: key))['vehicleId'] as String;

  Future<void> setActiveVehicle({required String vehicleId, IntentKey? key}) => call('setActiveVehicle', {'vehicleId': vehicleId}, key: key);
  Future<Map<String, dynamic>> goOnline() => call('goOnline', {}, mutating: false);
  Future<void> goOffline() => call('goOffline', {}, mutating: false);

  Future<Map<String, dynamic>> submitOffer({required String tripId, required int price, required int etaMinutes, IntentKey? key}) =>
      call('submitOffer', {'tripId': tripId, 'price': price, 'etaMinutes': etaMinutes}, key: key);

  /// Driver stage transitions: ackAssignment | markArrived | startTrip | finishTrip.
  Future<Map<String, dynamic>> stage(String command, {required String tripId, required int expectedRevision, IntentKey? key}) =>
      call(command, {'tripId': tripId, 'expectedRevision': expectedRevision}, key: key);

  Future<Map<String, dynamic>> recordCash({required String tripId, required int amount, required int expectedRevision, IntentKey? key}) =>
      call('recordCash', {'tripId': tripId, 'amount': amount, 'expectedRevision': expectedRevision}, key: key);

  Future<Map<String, dynamic>> myEarnings() => call('myEarnings', {}, mutating: false);

  // ── Operations ───────────────────────────────────────────
  Future<void> claimReview({required String path, IntentKey? key}) => call('claimReview', {'path': path}, key: key);
  Future<void> decideReview({required String path, required String decision, String? reason, IntentKey? key}) =>
      call('decideReview', {'path': path, 'decision': decision, 'reason': ?reason}, key: key);
  Future<Map<String, dynamic>> opsCancelTrip({required String tripId, required String reason, required String note, required int expectedRevision, IntentKey? key}) =>
      call('opsCancelTrip', {'tripId': tripId, 'reason': reason, 'note': note, 'expectedRevision': expectedRevision}, key: key);
  Future<Map<String, dynamic>> resolveDispute({required String tripId, required String resolution, required int expectedRevision, IntentKey? key}) =>
      call('resolveDispute', {'tripId': tripId, 'resolution': resolution, 'expectedRevision': expectedRevision}, key: key);
  Future<void> claimCase({required String caseId, IntentKey? key}) => call('claimCase', {'caseId': caseId}, key: key);
  Future<void> closeCase({required String caseId, required String resolution, IntentKey? key}) =>
      call('closeCase', {'caseId': caseId, 'resolution': resolution}, key: key);
  Future<Map<String, dynamic>> updatePricing({required String zoneId, required String category, required Map<String, dynamic> config, required bool enabled, required String reason, IntentKey? key}) =>
      call('updatePricing', {'zoneId': zoneId, 'category': category, 'config': config, 'enabled': enabled, 'reason': reason}, key: key);
  Future<Map<String, dynamic>> recordSettlement({required String driverId, required int amount, required String reference, IntentKey? key}) =>
      call('recordSettlement', {'driverId': driverId, 'amount': amount, 'reference': reference}, key: key);
  Future<void> recordAdjustment({required String driverId, required int amount, required int sign, required String reason, IntentKey? key}) =>
      call('recordAdjustment', {'driverId': driverId, 'amount': amount, 'sign': sign, 'reason': reason}, key: key);
  Future<Map<String, dynamic>> driverMoney({required String driverId}) => call('driverMoney', {'driverId': driverId}, mutating: false);
}
