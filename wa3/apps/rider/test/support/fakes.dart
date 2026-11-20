import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_rider/app/app.dart';
import 'package:wasilha_rider/app/deps.dart';
import 'package:wasilha_rider/features/auth/domain/auth_repository.dart';
import 'package:wasilha_rider/features/common/domain/live.dart';
import 'package:wasilha_rider/features/common/presentation/map_surface.dart';
import 'package:wasilha_rider/features/location/domain/location_service.dart';
import 'package:wasilha_rider/features/places/domain/places_repository.dart';
import 'package:wasilha_rider/features/profile/domain/profile_repository.dart';
import 'package:wasilha_rider/features/settings/application/settings_controller.dart';
import 'package:wasilha_rider/features/trips/domain/trip_repository.dart';

/// A stream that replays its latest value to new listeners.
class Feed<T> {
  Feed([T? initial]) {
    if (initial != null) add(initial);
  }
  final _c = StreamController<T>.broadcast();
  T? _last;
  bool _has = false;
  Object? _error;

  void add(T v) {
    _last = v;
    _has = true;
    _error = null;
    _c.add(v);
  }

  void addError(Object e) {
    _error = e;
    _c.addError(e);
  }

  Stream<T> get stream => Stream<T>.multi((m) {
        if (_error != null) {
          m.addError(_error!);
        } else if (_has) {
          m.add(_last as T);
        }
        final sub = _c.stream.listen(m.add, onError: m.addError);
        m.onCancel = sub.cancel;
      });
}

class FakeAuth implements AuthRepository {
  final uidFeed = Feed<String?>();
  String? currentUid = 'rider-1';
  final List<String> verifications = [];
  void Function(String e164, void Function(PhoneEvent) onEvent)? onStart;
  AuthFailure? codeFailure;

  @override
  String? get uid => currentUid;
  @override
  String? get phoneNumber => '+249912345678';
  @override
  Stream<String?> uidChanges() => uidFeed.stream;
  @override
  Future<void> startVerification(String e164, {required String lang, int? resendToken, required void Function(PhoneEvent) onEvent}) async {
    verifications.add(e164);
    (onStart ?? (_, cb) => cb(const CodeSent('ver-1', 7)))(e164, onEvent);
  }

  @override
  Future<void> confirmCode(String verificationId, String code) async {
    if (codeFailure != null) throw codeFailure!;
  }

  @override
  Future<void> signOut() async => currentUid = null;
}

class FakeProfile implements ProfileRepository {
  final feed = Feed<Live<RiderProfile?>>(const Live(RiderProfile(name: 'Amna', phone: '+249912345678', lang: 'ar')));
  final registered = <String>[];
  @override
  Stream<Live<RiderProfile?>> watch() => feed.stream;
  @override
  Future<void> register({required String name, required String lang, required IntentKey key}) async => registered.add(name);
}

class FakePlaces implements PlacesRepository {
  List<PlaceSuggestion> results = const [];
  @override
  Future<List<PlaceSuggestion>> search(String query, {required GeoPoint near, required String lang}) async => results;
  @override
  Future<String> label(GeoPoint point, {required String lang}) async => 'Street 15, Khartoum';
}

class FakeLocation implements LocationService {
  LocationResult result = const LocationResult(LocationStatus.granted, GeoPoint(15.59, 32.53));
  @override
  Future<LocationResult> locate({bool request = true}) async => result;
  @override
  Future<void> openAppSettings() async {}
  @override
  Future<void> openLocationSettings() async {}
}

class FakeTrips implements TripRepository {
  final trips = <String, Feed<Live<Trip?>>>{};
  final active = Feed<Live<List<Trip>>>(const Live(<Trip>[]));
  final offers = <String, Feed<Live<List<Offer>>>>{};
  final presence = <String, Feed<DriverPosition?>>{};
  final calls = <String>[];
  final args = <String, Map<String, Object?>>{};
  DraftResult Function()? draft;
  ApiFailure? failWith;

  Feed<Live<Trip?>> trip(String id) => trips.putIfAbsent(id, Feed.new);
  Feed<Live<List<Offer>>> offersOf(String id) => offers.putIfAbsent(id, Feed.new);
  Feed<DriverPosition?> presenceOf(String id) => presence.putIfAbsent(id, Feed.new);

  Future<void> _record(String name, Map<String, Object?> a) async {
    calls.add(name);
    args[name] = a;
    if (failWith != null) throw failWith!;
  }

  @override
  Stream<Live<Trip?>> watchTrip(String tripId) => trip(tripId).stream;
  @override
  Stream<Live<List<Trip>>> watchActiveTrips() => active.stream;
  @override
  Stream<Live<List<Offer>>> watchOffers(String tripId) => offersOf(tripId).stream;
  @override
  Stream<DriverPosition?> watchDriverPosition(String driverId) => presenceOf(driverId).stream;
  @override
  Future<TripPage> history({Object? after, int limit = 20}) async => const TripPage(trips: [], cursor: null, hasMore: false);

  @override
  Future<DraftResult> createDraft({required Place pickup, required Place dropoff, required Category category, required IntentKey key}) async {
    await _record('createDraft', {'category': category.name, 'pickup': pickup.label, 'dropoff': dropoff.label});
    return (draft ?? () => sampleDraft())();
  }

  @override
  Future<void> confirmRequest({required String tripId, required int proposedFare, required int expectedRevision, required IntentKey key}) =>
      _record('confirmRequest', {'tripId': tripId, 'fare': proposedFare, 'revision': expectedRevision});
  @override
  Future<void> acceptOffer({required String tripId, required String offerId, required int expectedRevision, required IntentKey key}) =>
      _record('acceptOffer', {'tripId': tripId, 'offerId': offerId, 'revision': expectedRevision});
  @override
  Future<void> cancelTrip({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key}) =>
      _record('cancelTrip', {'tripId': tripId, 'reason': reason, 'revision': expectedRevision});
  @override
  Future<void> rateTrip({required String tripId, required int stars, String? comment, required IntentKey key}) =>
      _record('rateTrip', {'stars': stars, 'comment': comment});
  @override
  Future<void> disputeTrip({required String tripId, required String reason, required int expectedRevision, required IntentKey key}) =>
      _record('disputeTrip', {'reason': reason, 'revision': expectedRevision});
  @override
  Future<void> reportSafety({required String tripId, required String description, required IntentKey key}) =>
      _record('reportSafety', {'description': description});
  @override
  Future<Uri> shareLink({required String tripId, required IntentKey key}) async {
    await _record('shareTrip', {'tripId': tripId});
    return Uri.parse('https://example.test/sharedTrip?t=tok');
  }
}

class FakeDeps {
  final auth = FakeAuth();
  final profile = FakeProfile();
  final trips = FakeTrips();
  final places = FakePlaces();
  final location = FakeLocation();
  final settings = SettingsController();
  final maps = <MapSpec>[];

  Widget map(BuildContext context, MapSpec spec) {
    maps.add(spec);
    return Semantics(label: spec.semanticLabel, child: const ColoredBox(color: Color(0xFFDDDDDD), child: SizedBox.expand()));
  }
}

/// Pumps [home] inside the real app shell (theme, strings, direction) with fakes.
Future<FakeDeps> pumpRider(WidgetTester tester, Widget home, {FakeDeps? deps, String lang = 'en'}) async {
  final d = deps ?? FakeDeps();
  await d.settings.setLang(lang);
  await tester.pumpWidget(RiderDeps(
    auth: d.auth,
    profile: d.profile,
    trips: d.trips,
    places: d.places,
    location: d.location,
    map: d.map,
    settings: d.settings,
    child: RiderShell(settings: d.settings, home: home),
  ));
  await tester.pump();
  return d;
}

/// 320×640 logical pixels at 200 % text.
void smallScreenLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

// ── Builders ─────────────────────────────────────────────

DraftResult sampleDraft({int min = 1500, int ref = 2000, int max = 3000, String? polyline, bool estimated = true}) => DraftResult(
      tripId: 'trip-new',
      revision: 1,
      quote: Quote(referenceFare: ref, minFare: min, maxFare: max),
      route: RouteInfo(distanceMeters: 5400, durationSeconds: 900, polyline: polyline, estimated: estimated),
    );

Trip makeTrip({
  String id = 'trip-1',
  TripState state = TripState.searching,
  int revision = 3,
  DateTime? expiresAt,
  int? proposedFare = 2000,
  int? fare,
  String? driverId,
  String? cancelReason,
  String cancelActor = 'system',
  Map<String, int>? timestamps,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return Trip.fromJson(id, {
    'riderId': 'rider-1',
    'riderName': 'Amna',
    'riderPhone': '+249912345678',
    'state': state.name,
    'revision': revision,
    'category': 'economy',
    'pickup': {'lat': 15.59, 'lng': 32.53, 'label': 'Riyadh, Khartoum'},
    'dropoff': {'lat': 15.61, 'lng': 32.55, 'label': 'Airport Road'},
    'route': {'distanceMeters': 5400, 'durationSeconds': 900, 'polyline': null, 'source': 'estimate'},
    'quote': {'referenceFare': 2000, 'minFare': 1500, 'maxFare': 3000},
    'currency': 'SDG',
    'proposedFare': proposedFare,
    'fare': fare,
    'driverId': driverId,
    if (driverId != null) 'driver': {'name': 'Osman Ali', 'phone': '+249911111111', 'ratingAvg': 4.8},
    if (driverId != null) 'vehicle': {'category': 'economy', 'make': 'Toyota', 'model': 'Corolla', 'color': 'White', 'plate': 'KH 1234'},
    'expiresAt': (expiresAt ?? DateTime.now().add(const Duration(minutes: 4))).millisecondsSinceEpoch,
    'offerCount': 0,
    if (cancelReason != null) 'cancellation': {'actor': cancelActor, 'reason': cancelReason, 'note': null, 'at': now},
    'timestamps': timestamps ?? {state.name: now},
    'flags': {'stuck': false, 'locationStale': false},
    'createdAt': now,
  });
}

Offer makeOffer(String id, {required int price, String name = 'Driver', int eta = 4, Duration expiresIn = const Duration(seconds: 45), OfferStatus status = OfferStatus.active}) =>
    Offer(
      id: id,
      price: price,
      etaMinutes: eta,
      status: status,
      expiresAt: DateTime.now().add(expiresIn),
      driver: DriverSnapshot(name: name, ratingAvg: 4.6),
      vehicle: const VehicleSnapshot(category: Category.economy, make: 'Hyundai', model: 'Accent', color: 'Silver', plate: 'KH 777'),
    );

/// Scrolls the screen's main scrollable (text fields have their own) until [f] shows.
Future<void> scrollTo(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
