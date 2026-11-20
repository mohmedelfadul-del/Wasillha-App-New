import 'enums.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
int? _io(Object? v) => (v as num?)?.toInt();
double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
String _s(Object? v) => (v ?? '').toString();
Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
  factory GeoPoint.fromJson(Object? j) => GeoPoint(_d(_m(j)['lat']), _d(_m(j)['lng']));
}

class Place {
  const Place({required this.point, required this.label});
  final GeoPoint point;
  final String label;
  Map<String, dynamic> toJson() => {...point.toJson(), 'label': label};
  factory Place.fromJson(Object? j) => Place(point: GeoPoint.fromJson(j), label: _s(_m(j)['label']));
}

class Quote {
  const Quote({required this.referenceFare, required this.minFare, required this.maxFare});
  final int referenceFare;
  final int minFare;
  final int maxFare;
  factory Quote.fromJson(Object? j) {
    final m = _m(j);
    return Quote(referenceFare: _i(m['referenceFare']), minFare: _i(m['minFare']), maxFare: _i(m['maxFare']));
  }
  bool contains(int fare) => fare >= minFare && fare <= maxFare;
}

class RouteInfo {
  const RouteInfo({required this.distanceMeters, required this.durationSeconds, this.polyline, required this.estimated});
  final int distanceMeters;
  final int durationSeconds;
  final String? polyline;

  /// True when the server used a straight-line estimate instead of real routing.
  final bool estimated;
  factory RouteInfo.fromJson(Object? j) {
    final m = _m(j);
    return RouteInfo(
      distanceMeters: _i(m['distanceMeters']),
      durationSeconds: _i(m['durationSeconds']),
      polyline: m['polyline'] as String?,
      estimated: m['source'] == 'estimate',
    );
  }
}

class DriverSnapshot {
  const DriverSnapshot({required this.name, this.phone, this.ratingAvg});
  final String name;
  final String? phone;
  final double? ratingAvg;
  factory DriverSnapshot.fromJson(Object? j) {
    final m = _m(j);
    return DriverSnapshot(name: _s(m['name']), phone: m['phone'] as String?, ratingAvg: (m['ratingAvg'] as num?)?.toDouble());
  }
}

class VehicleSnapshot {
  const VehicleSnapshot({required this.category, required this.make, required this.model, required this.color, required this.plate});
  final Category category;
  final String make, model, color, plate;
  String get title => '$color $make $model'.trim();
  factory VehicleSnapshot.fromJson(Object? j) {
    final m = _m(j);
    return VehicleSnapshot(
      category: Category.parse(m['category']),
      make: _s(m['make']),
      model: _s(m['model']),
      color: _s(m['color']),
      plate: _s(m['plate']),
    );
  }
}

class Rating {
  const Rating({required this.stars, this.comment});
  final int stars;
  final String? comment;
  static Rating? fromJson(Object? j) => j == null ? null : Rating(stars: _i(_m(j)['stars']), comment: _m(j)['comment'] as String?);
}

class Cancellation {
  const Cancellation({required this.actor, required this.reason, this.note, required this.at});
  final String actor;
  final String reason;
  final String? note;
  final DateTime at;
  static Cancellation? fromJson(Object? j) {
    if (j == null) return null;
    final m = _m(j);
    return Cancellation(actor: _s(m['actor']), reason: _s(m['reason']), note: m['note'] as String?, at: DateTime.fromMillisecondsSinceEpoch(_i(m['at'])));
  }
}

/// Authoritative trip snapshot as stored by the server (trips/{id}).
class Trip {
  Trip({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.state,
    required this.revision,
    required this.category,
    required this.pickup,
    required this.dropoff,
    required this.route,
    required this.quote,
    required this.currency,
    this.proposedFare,
    this.fare,
    this.amountDue,
    this.driverId,
    this.driver,
    this.vehicle,
    this.expiresAt,
    required this.offerCount,
    this.cashAmount,
    this.cancellation,
    this.riderRating,
    this.driverRating,
    this.disputeCaseId,
    required this.timestamps,
    required this.stuck,
    required this.locationStale,
    required this.createdAt,
  });

  final String id;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final TripState state;
  final int revision;
  final Category category;
  final Place pickup;
  final Place dropoff;
  final RouteInfo route;
  final Quote quote;
  final String currency;
  final int? proposedFare;
  final int? fare;
  final int? amountDue;
  final String? driverId;
  final DriverSnapshot? driver;
  final VehicleSnapshot? vehicle;
  final DateTime? expiresAt;
  final int offerCount;
  final int? cashAmount;
  final Cancellation? cancellation;
  final Rating? riderRating;
  final Rating? driverRating;
  final String? disputeCaseId;
  final Map<TripState, DateTime> timestamps;
  final bool stuck;
  final bool locationStale;
  final DateTime createdAt;

  DateTime? stamp(TripState s) => timestamps[s];

  factory Trip.fromJson(String id, Map<String, dynamic> m) {
    final ts = <TripState, DateTime>{};
    _m(m['timestamps']).forEach((k, v) => ts[TripState.parse(k)] = DateTime.fromMillisecondsSinceEpoch(_i(v)));
    final flags = _m(m['flags']);
    final exp = _io(m['expiresAt']);
    return Trip(
      id: id,
      riderId: _s(m['riderId']),
      riderName: _s(m['riderName']),
      riderPhone: _s(m['riderPhone']),
      state: TripState.parse(m['state']),
      revision: _i(m['revision']),
      category: Category.parse(m['category']),
      pickup: Place.fromJson(m['pickup']),
      dropoff: Place.fromJson(m['dropoff']),
      route: RouteInfo.fromJson(m['route']),
      quote: Quote.fromJson(m['quote']),
      currency: _s(m['currency']).isEmpty ? Tunables.currency : _s(m['currency']),
      proposedFare: _io(m['proposedFare']),
      fare: _io(m['fare']),
      amountDue: _io(m['amountDue']),
      driverId: m['driverId'] as String?,
      driver: m['driver'] == null ? null : DriverSnapshot.fromJson(m['driver']),
      vehicle: m['vehicle'] == null ? null : VehicleSnapshot.fromJson(m['vehicle']),
      expiresAt: exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp),
      offerCount: _i(m['offerCount']),
      cashAmount: _io(_m(m['cash'])['amount']),
      cancellation: Cancellation.fromJson(m['cancellation']),
      riderRating: Rating.fromJson(m['riderRating']),
      driverRating: Rating.fromJson(m['driverRating']),
      disputeCaseId: _m(m['dispute'])['caseId'] as String?,
      timestamps: ts,
      stuck: flags['stuck'] == true,
      locationStale: flags['locationStale'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_i(m['createdAt'])),
    );
  }
}

/// A driver's offer on an open request (trips/{id}/offers/{driverUid}).
class Offer {
  const Offer({required this.id, required this.price, required this.etaMinutes, required this.status, required this.expiresAt, required this.driver, required this.vehicle});
  final String id;
  final int price;
  final int etaMinutes;
  final OfferStatus status;
  final DateTime expiresAt;
  final DriverSnapshot driver;
  final VehicleSnapshot vehicle;

  bool isLive(DateTime now) => status == OfferStatus.active && expiresAt.isAfter(now);

  factory Offer.fromJson(String id, Map<String, dynamic> m) => Offer(
        id: id,
        price: _i(m['price']),
        etaMinutes: _i(m['etaMinutes']),
        status: OfferStatus.parse(m['status']),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(_i(m['expiresAt'])),
        driver: DriverSnapshot.fromJson(m['driver']),
        vehicle: VehicleSnapshot.fromJson(m['vehicle']),
      );
}

/// Sanitized request card in the driver's inbox (inbox/{uid}/requests/{tripId}).
class RequestCard {
  const RequestCard({
    required this.tripId,
    required this.category,
    required this.pickup,
    required this.dropoffLabel,
    required this.distanceToPickupKm,
    required this.tripDistanceMeters,
    required this.proposedFare,
    required this.minFare,
    required this.maxFare,
    required this.currency,
    required this.expiresAt,
  });
  final String tripId;
  final Category category;
  final Place pickup;
  final String dropoffLabel;
  final double distanceToPickupKm;
  final int tripDistanceMeters;
  final int proposedFare;
  final int minFare;
  final int maxFare;
  final String currency;
  final DateTime expiresAt;

  factory RequestCard.fromJson(String id, Map<String, dynamic> m) => RequestCard(
        tripId: id,
        category: Category.parse(m['category']),
        pickup: Place.fromJson(m['pickup']),
        dropoffLabel: _s(m['dropoffLabel']),
        distanceToPickupKm: _d(m['distanceToPickupKm']),
        tripDistanceMeters: _i(m['tripDistanceMeters']),
        proposedFare: _i(m['proposedFare']),
        minFare: _i(m['minFare']),
        maxFare: _i(m['maxFare']),
        currency: _s(m['currency']),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(_i(m['expiresAt'])),
      );
}

class DriverProfile {
  const DriverProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.status,
    required this.online,
    this.activeVehicleId,
    this.activeCategory,
    this.activeTripId,
    this.zoneId,
    this.ratingAvg,
    required this.completedTrips,
    this.offlineReason,
  });
  final String uid;
  final String name;
  final String phone;
  final DriverStatus status;
  final bool online;
  final String? activeVehicleId;
  final Category? activeCategory;
  final String? activeTripId;
  final String? zoneId;
  final double? ratingAvg;
  final int completedTrips;
  final String? offlineReason;

  factory DriverProfile.fromJson(String uid, Map<String, dynamic> m) {
    final count = _i(m['ratingCount']);
    return DriverProfile(
      uid: uid,
      name: _s(m['name']),
      phone: _s(m['phone']),
      status: DriverStatus.parse(m['status']),
      online: m['online'] == true,
      activeVehicleId: m['activeVehicleId'] as String?,
      activeCategory: m['activeCategory'] == null ? null : Category.parse(m['activeCategory']),
      activeTripId: m['activeTripId'] as String?,
      zoneId: m['zoneId'] as String?,
      ratingAvg: count == 0 ? null : _d(m['ratingSum']) / count,
      completedTrips: _i(m['completedTrips']),
      offlineReason: m['offlineReason'] as String?,
    );
  }
}

class Vehicle {
  const Vehicle({required this.id, required this.category, required this.make, required this.model, required this.color, required this.plate, required this.year, required this.status});
  final String id;
  final Category category;
  final String make, model, color, plate;
  final int year;

  /// pending | approved | changesRequested
  final String status;
  bool get approved => status == 'approved';
  factory Vehicle.fromJson(String id, Map<String, dynamic> m) => Vehicle(
        id: id,
        category: Category.parse(m['category']),
        make: _s(m['make']),
        model: _s(m['model']),
        color: _s(m['color']),
        plate: _s(m['plate']),
        year: _i(m['year']),
        status: _s(m['status']),
      );
}

/// A KYC document (drivers/{uid}/documents/{type} or vehicles/{id}/documents/{type}).
class ReviewDocument {
  const ReviewDocument({
    required this.path,
    required this.type,
    required this.status,
    this.reason,
    required this.storagePath,
    required this.driverId,
    this.vehicleId,
    required this.submittedAt,
    this.claimedBy,
    this.claimedAt,
    this.decidedBy,
    this.decidedAt,
  });
  final String path;
  final DocumentType type;
  final ReviewStatus status;
  final String? reason;
  final String storagePath;
  final String driverId;
  final String? vehicleId;
  final DateTime submittedAt;
  final String? claimedBy;
  final DateTime? claimedAt;
  final String? decidedBy;
  final DateTime? decidedAt;

  factory ReviewDocument.fromJson(String path, Map<String, dynamic> m) {
    DateTime? t(Object? v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(_i(v));
    return ReviewDocument(
      path: path,
      type: DocumentType.parse(m['type']),
      status: ReviewStatus.parse(m['status']),
      reason: m['reason'] as String?,
      storagePath: _s(m['storagePath']),
      driverId: _s(m['driverId']),
      vehicleId: m['vehicleId'] as String?,
      submittedAt: t(m['submittedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      claimedBy: m['claimedBy'] as String?,
      claimedAt: t(m['claimedAt']),
      decidedBy: m['decidedBy'] as String?,
      decidedAt: t(m['decidedAt']),
    );
  }
}

/// Derived money view (never a stored balance). All amounts in minor units.
class DriverMoney {
  const DriverMoney({required this.collectedMinor, required this.commissionMinor, required this.earnedMinor, required this.settledMinor, required this.owedMinor, this.entries = const []});
  final int collectedMinor, commissionMinor, earnedMinor, settledMinor, owedMinor;
  final List<LedgerEntry> entries;
  factory DriverMoney.fromJson(Object? j) {
    final m = _m(j);
    return DriverMoney(
      collectedMinor: _i(m['collectedMinor']),
      commissionMinor: _i(m['commissionMinor']),
      earnedMinor: _i(m['earnedMinor']),
      settledMinor: _i(m['settledMinor']),
      owedMinor: _i(m['owedMinor']),
      entries: ((m['entries'] as List?) ?? const []).map((e) => LedgerEntry.fromJson(_m(e))).toList(),
    );
  }
}

class LedgerEntry {
  const LedgerEntry({required this.kind, required this.amountMinor, this.sign = 1, this.tripId, this.reason, required this.createdAt});
  final LedgerKind kind;
  final int amountMinor;
  final int sign;
  final String? tripId;
  final String? reason;
  final DateTime createdAt;
  factory LedgerEntry.fromJson(Map<String, dynamic> m) => LedgerEntry(
        kind: LedgerKind.values.firstWhere((k) => k.name == m['kind'], orElse: () => LedgerKind.adjustment),
        amountMinor: _i(m['amountMinor']),
        sign: _i(m['sign'] ?? 1),
        tripId: m['tripId'] as String?,
        reason: m['reason'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(_i(m['createdAt'])),
      );
}

class SupportCase {
  const SupportCase({required this.id, required this.type, required this.status, required this.priority, this.tripId, this.ownerId, required this.description, required this.createdAt, this.reporterRole});
  final String id;
  final CaseType type;
  final String status; // open | inProgress | resolved
  final String priority; // urgent | normal
  final String? tripId;
  final String? ownerId;
  final String description;
  final DateTime createdAt;
  final String? reporterRole;
  factory SupportCase.fromJson(String id, Map<String, dynamic> m) => SupportCase(
        id: id,
        type: CaseType.values.firstWhere((t) => t.name == m['type'], orElse: () => CaseType.support),
        status: _s(m['status']),
        priority: _s(m['priority']),
        tripId: m['tripId'] as String?,
        ownerId: m['ownerId'] as String?,
        description: _s(m['description']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(_i(m['createdAt'])),
        reporterRole: m['reporterRole'] as String?,
      );
}

/// Driver position (presence/{uid}). `updatedAt` is server time.
class DriverPosition {
  const DriverPosition({required this.point, required this.updatedAt, this.heading});
  final GeoPoint point;
  final DateTime updatedAt;
  final double? heading;
  bool isStale(DateTime now) => now.difference(updatedAt).inSeconds > Tunables.locationStaleSeconds;
  factory DriverPosition.fromJson(Map<String, dynamic> m) {
    final u = m['updatedAt'];
    // Server timestamp (Firestore Timestamp) — or millis from tooling.
    final at = u is num
        ? DateTime.fromMillisecondsSinceEpoch(u.toInt())
        : (u as dynamic)?.toDate() as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DriverPosition(point: GeoPoint.fromJson(m), updatedAt: at, heading: (m['heading'] as num?)?.toDouble());
  }
}
