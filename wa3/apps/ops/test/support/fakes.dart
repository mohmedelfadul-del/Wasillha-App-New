import 'dart:async';

import 'package:wa3_core/wa3_core.dart';
import 'package:wasilha_ops/app/live.dart';
import 'package:wasilha_ops/app/services.dart';
import 'package:wasilha_ops/features/audit/domain/audit_repository.dart';
import 'package:wasilha_ops/features/auth/domain/auth_repository.dart';
import 'package:wasilha_ops/features/cases/domain/cases_repository.dart';
import 'package:wasilha_ops/features/cockpit/domain/cockpit_repository.dart';
import 'package:wasilha_ops/features/finance/domain/finance_repository.dart';
import 'package:wasilha_ops/features/kyc/domain/kyc_repository.dart';
import 'package:wasilha_ops/features/people/domain/people_repository.dart';
import 'package:wasilha_ops/features/pricing/domain/pricing_repository.dart';
import 'package:wasilha_ops/features/trips/domain/trips_repository.dart';

final testNow = DateTime(2026, 11, 20, 12, 0);

StaffSession staff(StaffRole? role, {String uid = 'me-uid', bool isStaff = true, bool mfa = true}) =>
    StaffSession(uid: uid, email: '$uid@example.com', staff: isStaff, role: role, secondFactor: mfa, hasEnrolledTotp: mfa);

class FakeAuth implements AuthRepository {
  FakeAuth(this.initial);
  final StaffSession? initial;
  final _c = StreamController<StaffSession?>.broadcast();
  bool signedOut = false;

  @override
  Stream<StaffSession?> sessions() async* {
    yield initial;
    yield* _c.stream;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _c.add(null);
  }

  @override
  Future<SignInOutcome> signIn(String email, String password) async => const SignedIn();
  @override
  Future<void> resolveTotp(MfaChallenge challenge, String code) async {}
  @override
  Future<TotpEnrollment> startTotpEnrollment() async => const TotpEnrollment(secretKey: 'JBSWY3DPEHPK3PXP', otpauthUri: 'otpauth://totp/x', handle: 0);
  @override
  Future<void> completeTotpEnrollment(TotpEnrollment enrollment, String code) async {}
  @override
  Future<void> refresh() async {}
}

class FakeCockpit implements CockpitRepository {
  FakeCockpit(this.byKind);
  final Map<QueueKind, QueueSummary> byKind;
  @override
  Stream<Live<QueueSummary>> watch(QueueKind kind) => Stream.value(Live(byKind[kind] ?? QueueSummary(kind: kind, count: 0)));
}

ReviewDocument reviewDoc({
  String path = 'drivers/d1/documents/driving_license',
  DocumentType type = DocumentType.driving_license,
  ReviewStatus status = ReviewStatus.pending,
  String? claimedBy,
  DateTime? claimedAt,
  String? decidedBy,
  DateTime? decidedAt,
  String? reason,
  DateTime? submittedAt,
  String? vehicleId,
}) =>
    ReviewDocument(
      path: path,
      type: type,
      status: status,
      reason: reason,
      storagePath: 'drivers/d1/license.jpg',
      driverId: 'd1',
      vehicleId: vehicleId,
      submittedAt: submittedAt ?? testNow.subtract(const Duration(hours: 3)),
      claimedBy: claimedBy,
      claimedAt: claimedAt,
      decidedBy: decidedBy,
      decidedAt: decidedAt,
    );

class FakeKyc implements KycRepository {
  FakeKyc([this.items = const []]);
  final List<ReviewDocument> items;
  final calls = <String>[];
  @override
  Stream<Live<List<ReviewDocument>>> pending({int limit = 100}) => Stream.value(Live(items));
  @override
  Stream<Live<ReviewDocument?>> watch(String path) => Stream.value(Live(items.where((d) => d.path == path).firstOrNull));
  @override
  Future<ReviewSubject> subject(ReviewDocument d) async =>
      const ReviewSubject(driverName: 'محمد عبدالله الطيب إبراهيم', driverPhone: '+249912345678', vehicleTitle: 'أبيض تويوتا كورولا 2015', plate: 'خ ٣ ١٢٣٤٥');
  @override
  Future<String> downloadUrl(String storagePath) => Completer<String>().future;
  @override
  Future<void> claim(String path, IntentKey key) async => calls.add('claim $path');
  @override
  Future<void> decide(String path, Decision decision, String? reason, IntentKey key) async => calls.add('decide ${decision.name} $reason');
}

TripRecord tripRecord(String id, TripState state, {bool stuck = false, bool stale = false, Duration inState = const Duration(minutes: 12)}) {
  final since = testNow.subtract(inState);
  final t = Trip.fromJson(id, {
    'riderId': 'r-$id',
    'riderName': 'سارة أحمد',
    'riderPhone': '+249911111111',
    'state': state.name,
    'revision': 4,
    'category': 'economy',
    'pickup': {'lat': 15.5, 'lng': 32.5, 'label': 'السوق العربي'},
    'dropoff': {'lat': 15.6, 'lng': 32.6, 'label': 'بحري'},
    'route': {'distanceMeters': 7000, 'durationSeconds': 900},
    'quote': {'referenceFare': 2000, 'minFare': 1600, 'maxFare': 4000},
    'driverId': 'd-$id',
    'driver': {'name': 'عثمان', 'phone': '+249922222222'},
    'vehicle': {'category': 'economy', 'make': 'Toyota', 'model': 'Corolla', 'color': 'White', 'plate': 'KH 1234'},
    'timestamps': {'searching': since.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch, state.name: since.millisecondsSinceEpoch},
    'flags': {'stuck': stuck, 'locationStale': stale},
    'createdAt': since.subtract(const Duration(minutes: 6)).millisecondsSinceEpoch,
  });
  return TripRecord(t, updatedAt: since);
}

class FakeTrips implements TripsRepository {
  FakeTrips([this.items = const []]);
  final List<TripRecord> items;
  @override
  Stream<Live<List<TripRecord>>> live({int limit = 300}) => Stream.value(Live(items));
  @override
  Stream<Live<TripRecord?>> watch(String id) => Stream.value(Live(items.where((t) => t.trip.id == id).firstOrNull));
  @override
  Future<TripRecord?> get(String id) async => items.where((t) => t.trip.id == id).firstOrNull;
  @override
  Stream<Live<List<TripRecord>>> recentForRider(String riderId, {int limit = 20}) => Stream.value(const Live([]));
  @override
  Stream<Live<List<TripRecord>>> recentForDriver(String driverId, {int limit = 20}) => Stream.value(const Live([]));
  @override
  Future<void> opsCancel({required String tripId, required String reason, required String note, required int expectedRevision, required IntentKey key}) async {}
  @override
  Future<void> resolveDispute({required String tripId, required String resolution, required int expectedRevision, required IntentKey key}) async {}
}

class FakeCases implements CasesRepository {
  @override
  Stream<Live<List<CaseRecord>>> open({int limit = 300}) => Stream.value(const Live([]));
  @override
  Stream<Live<CaseRecord?>> watch(String id) => Stream.value(const Live(null));
  @override
  Future<void> claim(String caseId, IntentKey key) async {}
  @override
  Future<void> close(String caseId, String resolution, IntentKey key) async {}
}

class FakePeople implements PeopleRepository {
  @override
  Future<List<RiderRecord>> ridersByPhone(String phone) async => const [];
  @override
  Future<List<DriverProfile>> driversByPhone(String phone) async => const [];
  @override
  Future<RiderRecord?> rider(String uid) async => null;
  @override
  Future<DriverProfile?> driver(String uid) async => null;
  @override
  Stream<Live<RiderRecord?>> watchRider(String uid) => Stream.value(const Live(null));
  @override
  Stream<Live<DriverProfile?>> watchDriver(String uid) => Stream.value(const Live(null));
  @override
  Stream<Live<List<ReviewDocument>>> driverDocuments(String uid) => Stream.value(const Live([]));
  @override
  Stream<Live<List<Vehicle>>> vehicles(String driverId) => Stream.value(const Live([]));
}

class FakePricing implements PricingRepository {
  @override
  Stream<Live<List<Zone>>> zones() => Stream.value(const Live([Zone(id: 'khartoum', name: 'Khartoum', active: true)]));
  @override
  Stream<Live<PricingRecord?>> watch(String zoneId, Category category) => Stream.value(const Live(null));
  @override
  Future<int> update({required String zoneId, required Category category, required PricingRecord config, required String reason, required IntentKey key}) async => 1;
}

class FakeFinance implements FinanceRepository {
  @override
  Future<DriverMoney> driverMoney(String driverId) async => const DriverMoney(collectedMinor: 0, commissionMinor: 0, earnedMinor: 0, settledMinor: 0, owedMinor: 0);
  @override
  Stream<Live<List<LedgerRecord>>> ledger(String driverId, {int limit = 50}) => Stream.value(const Live([]));
  @override
  Future<int> recordSettlement({required String driverId, required int amount, required String reference, required IntentKey key}) async => 0;
}

class FakeAudit implements AuditRepository {
  @override
  Stream<Live<List<AuditEntry>>> recent({int limit = 50}) => Stream.value(const Live([]));
}

OpsServices fakeServices({StaffSession? session, CockpitRepository? cockpit, KycRepository? kyc, TripsRepository? trips, FakeAuth? auth}) => OpsServices(
      auth: auth ?? FakeAuth(session),
      cockpit: cockpit ?? FakeCockpit(const {}),
      kyc: kyc ?? FakeKyc(),
      trips: trips ?? FakeTrips(),
      cases: FakeCases(),
      people: FakePeople(),
      pricing: FakePricing(),
      finance: FakeFinance(),
      audit: FakeAudit(),
      now: () => testNow,
    );
