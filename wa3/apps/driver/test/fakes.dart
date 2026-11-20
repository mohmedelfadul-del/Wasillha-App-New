import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_driver/app/driver_app.dart';
import 'package:wasilha_driver/app/launcher.dart';
import 'package:wasilha_driver/app/live.dart';
import 'package:wasilha_driver/app/services.dart';
import 'package:wasilha_driver/app/settings_controller.dart';
import 'package:wasilha_driver/features/account/domain/driver_repository.dart';
import 'package:wasilha_driver/features/auth/domain/auth_repository.dart';
import 'package:wasilha_driver/features/documents/domain/document_repository.dart';
import 'package:wasilha_driver/features/earnings/domain/earnings_repository.dart';
import 'package:wasilha_driver/features/history/domain/history_repository.dart';
import 'package:wasilha_driver/features/location/application/location_service.dart';
import 'package:wasilha_driver/features/location/domain/location_port.dart';
import 'package:wasilha_driver/features/requests/domain/request_repository.dart';
import 'package:wasilha_driver/features/trip/domain/trip_repository.dart';
import 'package:wasilha_driver/features/vehicles/domain/vehicle_repository.dart';

/// A stream that replays its latest value to every new listener.
class Seeded<T> {
  Seeded([T? initial]) {
    if (initial != null) add(initial);
  }
  final _c = StreamController<T>.broadcast();
  T? _v;
  bool _has = false;
  T? get value => _v;
  void add(T v) {
    _v = v;
    _has = true;
    _c.add(v);
  }

  Stream<T> get stream async* {
    if (_has) yield _v as T;
    yield* _c.stream;
  }
}

class FakeAuth implements AuthRepository {
  @override
  String? currentUid = 'd1';
  final uid = Seeded<String?>('d1');
  @override
  Stream<String?> uidChanges() => uid.stream;
  @override
  Stream<VerifyEvent> verifyPhone(String e164, {int? resendToken}) => Stream.value(const CodeSent('vid', 1));
  @override
  Future<void> confirmCode(String verificationId, String smsCode) async {}
  @override
  Future<void> signOut() async {}
}

class FakeDriverRepo implements DriverRepository {
  final driver = Seeded<Live<DriverState?>>();
  ApiFailure? goOnlineFailure;
  int goOnlineCalls = 0;
  @override
  Stream<Live<DriverState?>> watchDriver(String uid) => driver.stream;
  @override
  Future<void> register({required String name, required IntentKey key}) async {}
  @override
  Future<void> setActiveVehicle({required String vehicleId, required IntentKey key}) async {}
  @override
  Future<void> goOnline() async {
    goOnlineCalls++;
    if (goOnlineFailure != null) throw goOnlineFailure!;
  }

  @override
  Future<void> goOffline() async {}
}

class FakeDocumentRepo implements DocumentRepository {
  final driverDocs = Seeded<Live<Map<DocumentType, ReviewDocument>>>(const Live({}));
  final uploads = <String>[];
  final submits = <({DocumentType type, String path, String? vehicleId})>[];
  int failUploads = 0;
  @override
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchDriverDocuments(String uid) => driverDocs.stream;
  @override
  Stream<Live<Map<DocumentType, ReviewDocument>>> watchVehicleDocuments(String vehicleId) => Stream.value(const Live({}));
  @override
  Stream<List<ReviewDocument>> watchAllVehicleDocuments(String uid) => Stream.value(const []);
  @override
  Future<void> upload({required String storagePath, required Uint8List bytes, required void Function(double) onProgress}) async {
    onProgress(0.5);
    if (failUploads > 0) {
      failUploads--;
      throw const ApiFailure('network', 'dropped');
    }
    uploads.add(storagePath);
    onProgress(1);
  }

  @override
  Future<void> submit({required DocumentType type, required String storagePath, String? vehicleId, required IntentKey key}) async =>
      submits.add((type: type, path: storagePath, vehicleId: vehicleId));
}

class FakePicker implements ImagePickerPort {
  Uint8List bytes = Uint8List.fromList(List.filled(1000, 1));
  @override
  Future<PickedImage?> pick(PickSource source) async => PickedImage(bytes);
}

class FakeVehicleRepo implements VehicleRepository {
  final vehicles = Seeded<Live<List<Vehicle>>>(const Live([]));
  @override
  Stream<Live<List<Vehicle>>> watchVehicles(String uid) => vehicles.stream;
  @override
  Future<String> add(NewVehicle v, {required IntentKey key}) async => 'v-new';
}

class FakeRequestRepo implements RequestRepository {
  final inbox = Seeded<Live<List<RequestCard>>>(const Live([]));
  final offers = <({String tripId, int price, int eta})>[];
  @override
  Stream<Live<List<RequestCard>>> watchInbox(String uid) => inbox.stream;
  @override
  Stream<Offer?> watchMyOffer({required String tripId, required String uid}) => Stream.value(null);
  @override
  Future<DateTime> submitOffer({required String tripId, required int price, required int etaMinutes, required IntentKey key}) async {
    offers.add((tripId: tripId, price: price, eta: etaMinutes));
    return DateTime.now().add(const Duration(seconds: 60));
  }
}

class FakeTripRepo implements TripRepository {
  final trip = Seeded<Live<Trip?>>();
  final calls = <({String command, int revision, String key})>[];
  final cash = <int>[];
  ApiFailure? stageFailure;
  @override
  Stream<Live<Trip?>> watchTrip(String tripId) => trip.stream;
  @override
  Future<void> stage(String command, {required String tripId, required int expectedRevision, required IntentKey key}) async {
    calls.add((command: command, revision: expectedRevision, key: key.value));
    if (stageFailure != null) throw stageFailure!;
  }

  @override
  Future<void> recordCash({required String tripId, required int amount, required int expectedRevision, required IntentKey key}) async => cash.add(amount);
  @override
  Future<void> cancel({required String tripId, required String reason, String? note, required int expectedRevision, required IntentKey key}) async =>
      calls.add((command: 'cancelTrip:$reason', revision: expectedRevision, key: key.value));
  @override
  Future<void> rateRider({required String tripId, required int stars, String? comment, required IntentKey key}) async {}
}

class FakeEarningsRepo implements EarningsRepository {
  DriverMoney money = const DriverMoney(collectedMinor: 0, commissionMinor: 0, earnedMinor: 0, settledMinor: 0, owedMinor: 0);
  TodaySummary today = const TodaySummary(completedTrips: 3, collectedMinor: 450000, commissionMinor: 45000);
  @override
  Future<DriverMoney> myEarnings() async => money;
  @override
  Stream<Live<TodaySummary>> watchToday(String uid, DateTime startOfDay) => Stream.value(Live(today));
}

class FakeHistoryRepo implements HistoryRepository {
  @override
  Future<TripPage> page(String uid, {Object? after}) async => const TripPage(trips: [], cursor: null, hasMore: false);
}

class FakeLocationSource implements LocationSource {
  LocationAccess access = LocationAccess.granted;
  final fixesCtl = StreamController<Fix>.broadcast();
  @override
  Future<LocationAccess> check() async => access;
  @override
  Future<LocationAccess> request() async => access;
  @override
  Stream<Fix> fixes() => fixesCtl.stream;
  @override
  Future<void> openAppSettings() async {}
  @override
  Future<void> openLocationSettings() async {}
}

class FakeSink implements PresenceSink {
  final writes = <({String uid, Fix fix})>[];
  @override
  Future<void> write(String uid, Fix fix) async => writes.add((uid: uid, fix: fix));
}

class FakeLauncher implements Launcher {
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class Fakes {
  final auth = FakeAuth();
  final driver = FakeDriverRepo();
  final documents = FakeDocumentRepo();
  final picker = FakePicker();
  final vehicles = FakeVehicleRepo();
  final requests = FakeRequestRepo();
  final trips = FakeTripRepo();
  final earnings = FakeEarningsRepo();
  final history = FakeHistoryRepo();
  final locationSource = FakeLocationSource();
  final sink = FakeSink();
  final launcher = FakeLauncher();
  late final location = LocationService(source: locationSource, sink: sink);

  AppServices services({String lang = 'ar'}) => AppServices(
        auth: auth,
        driver: driver,
        documents: documents,
        picker: picker,
        vehicles: vehicles,
        requests: requests,
        trips: trips,
        earnings: earnings,
        history: history,
        location: location,
        launcher: launcher,
        settings: SettingsController(lang: lang, theme: ThemeMode.light),
      );
}

/// Pumps [home] inside the real app shell (theme, strings, direction).
Future<void> pumpHome(WidgetTester t, Widget home, {required AppServices services, Size? size, double textScale = 1}) async {
  if (size != null) {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }
  if (textScale != 1) {
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await t.pumpWidget(DriverApp(services: services, home: home));
  await t.pump();
}

// ── Builders ──────────────────────────────────────────────

DriverState driverState({DriverStatus status = DriverStatus.approved, bool online = false, String? vehicle = 'v1', String? trip, String? offlineReason}) => DriverState(
      profile: DriverProfile(
        uid: 'd1',
        name: 'Ahmed Ali',
        phone: '+249912345678',
        status: status,
        online: online,
        activeVehicleId: vehicle,
        activeCategory: vehicle == null ? null : Category.economy,
        activeTripId: trip,
        completedTrips: 12,
        ratingAvg: 4.8,
        offlineReason: offlineReason,
      ),
      ratingCount: 10,
    );

Trip trip({TripState state = TripState.driverEnRoute, int revision = 4, int fare = 1500, Map<String, dynamic> extra = const {}}) => Trip.fromJson('t1', {
      'riderId': 'r1',
      'riderName': 'Fatima Hassan Abdelrahman',
      'riderPhone': '+249911111111',
      'state': state.name,
      'revision': revision,
      'category': 'economy',
      'pickup': {'lat': 15.5, 'lng': 32.5, 'label': 'Al Riyadh, Street 15, near the big mosque'},
      'dropoff': {'lat': 15.6, 'lng': 32.55, 'label': 'Khartoum Airport, Departures'},
      'route': {'distanceMeters': 7200, 'durationSeconds': 900},
      'quote': {'referenceFare': 1500, 'minFare': 1200, 'maxFare': 1900},
      'fare': fare,
      'amountDue': state == TripState.paymentPending ? fare : null,
      'driverId': 'd1',
      'offerCount': 1,
      'timestamps': {},
      'flags': {},
      'createdAt': DateTime(2026, 11, 20, 9).millisecondsSinceEpoch,
      ...extra,
    });

RequestCard requestCard({String id = 'r1', int proposed = 1500, int min = 1200, int max = 1900, double distanceKm = 5, Duration expiresIn = const Duration(seconds: 120)}) =>
    RequestCard.fromJson(id, {
      'category': 'economy',
      'pickup': {'lat': 15.5, 'lng': 32.5, 'label': 'Al Amarat Street 1'},
      'dropoffLabel': 'Bahri, Shambat',
      'distanceToPickupKm': distanceKm,
      'tripDistanceMeters': 8400,
      'proposedFare': proposed,
      'minFare': min,
      'maxFare': max,
      'currency': 'SDG',
      'expiresAt': DateTime.now().add(expiresIn).millisecondsSinceEpoch,
    });
