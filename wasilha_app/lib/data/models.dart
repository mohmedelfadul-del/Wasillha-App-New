import 'dart:math' as math;

/// Services offered by Wasilha. Rates are SDG; fares are
/// `base + perKm * distance`, rounded to the nearest 50.
enum ServiceType {
  raksha('Raksha', 'ركشة', 'raksha', 600, 280),
  moto('Motor', 'موتر', 'bike', 700, 320),
  car('Car', 'عربية', 'car', 1200, 520),
  delivery('Delivery', 'توصيل', 'bag', 900, 300),
  food('Food', 'أكل', 'bowl', 500, 200),
  parcel('Parcel', 'طرد', 'gift', 1000, 350);

  const ServiceType(this.label, this.labelAr, this.icon, this.base, this.perKm);
  final String label;
  final String labelAr;
  final String icon;
  final int base;
  final int perKm;

  int fareFor(double km) {
    final raw = base + perKm * km;
    return ((raw / 50).round() * 50).clamp(base, 1 << 31);
  }

  String title(bool ar) => ar ? labelAr : label;

  static ServiceType parse(String? s) =>
      ServiceType.values.firstWhere((e) => e.name == s, orElse: () => ServiceType.car);
}

class Place {
  const Place({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.area = '',
    required this.lat,
    required this.lng,
    this.kind = 'other',
  });

  final String id;
  final String name;
  final String nameAr;
  final String area;
  final double lat;
  final double lng;

  /// home | work | other
  final String kind;

  String label(bool ar) => ar && nameAr.isNotEmpty ? nameAr : name;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'nameAr': nameAr,
        'area': area,
        'lat': lat,
        'lng': lng,
        'kind': kind,
      };

  factory Place.fromMap(Map<String, dynamic> m) => Place(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        nameAr: (m['nameAr'] ?? '') as String,
        area: (m['area'] ?? '') as String,
        lat: (m['lat'] as num?)?.toDouble() ?? 15.5007,
        lng: (m['lng'] as num?)?.toDouble() ?? 32.5599,
        kind: (m['kind'] ?? 'other') as String,
      );

  double kmTo(Place o) => haversineKm(lat, lng, o.lat, o.lng);
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

enum TripStatus { requested, accepted, arriving, inProgress, completed, cancelled }

TripStatus parseTripStatus(String? s) =>
    TripStatus.values.firstWhere((e) => e.name == s, orElse: () => TripStatus.requested);

class Trip {
  Trip({
    required this.id,
    required this.riderId,
    this.riderName = '',
    required this.service,
    required this.pickup,
    required this.dropoff,
    required this.offeredFare,
    this.finalFare,
    this.status = TripStatus.requested,
    this.driverId,
    this.driverName,
    this.driverVehicle,
    this.driverPlate,
    this.driverRating,
    this.driverLat,
    this.driverLng,
    DateTime? createdAt,
    this.rating,
    this.tip = 0,
    this.payment = 'wallet',
    this.note = '',
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String riderId;
  final String riderName;
  final ServiceType service;
  final Place pickup;
  final Place dropoff;
  final int offeredFare;
  final int? finalFare;
  final TripStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverVehicle;
  final String? driverPlate;
  final double? driverRating;
  final double? driverLat;
  final double? driverLng;
  final DateTime createdAt;
  final int? rating;
  final int tip;

  /// wallet | cash
  final String payment;
  final String note;

  int get fare => finalFare ?? offeredFare;
  double get distanceKm => pickup.kmTo(dropoff);
  int get etaMin => (distanceKm / 0.45).round().clamp(3, 120); // ~27 km/h city average
  bool get isActive =>
      status != TripStatus.completed && status != TripStatus.cancelled;

  Trip copyWith({
    TripStatus? status,
    int? finalFare,
    String? driverId,
    String? driverName,
    String? driverVehicle,
    String? driverPlate,
    double? driverRating,
    double? driverLat,
    double? driverLng,
    int? rating,
    int? tip,
  }) =>
      Trip(
        id: id,
        riderId: riderId,
        riderName: riderName,
        service: service,
        pickup: pickup,
        dropoff: dropoff,
        offeredFare: offeredFare,
        finalFare: finalFare ?? this.finalFare,
        status: status ?? this.status,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        driverVehicle: driverVehicle ?? this.driverVehicle,
        driverPlate: driverPlate ?? this.driverPlate,
        driverRating: driverRating ?? this.driverRating,
        driverLat: driverLat ?? this.driverLat,
        driverLng: driverLng ?? this.driverLng,
        createdAt: createdAt,
        rating: rating ?? this.rating,
        tip: tip ?? this.tip,
        payment: payment,
        note: note,
      );

  Map<String, dynamic> toMap() => {
        'riderId': riderId,
        'riderName': riderName,
        'service': service.name,
        'pickup': pickup.toMap(),
        'dropoff': dropoff.toMap(),
        'offeredFare': offeredFare,
        'finalFare': finalFare,
        'status': status.name,
        'driverId': driverId,
        'driverName': driverName,
        'driverVehicle': driverVehicle,
        'driverPlate': driverPlate,
        'driverRating': driverRating,
        'driverLat': driverLat,
        'driverLng': driverLng,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'rating': rating,
        'tip': tip,
        'payment': payment,
        'note': note,
      };

  factory Trip.fromMap(String id, Map<String, dynamic> m) => Trip(
        id: id,
        riderId: (m['riderId'] ?? '') as String,
        riderName: (m['riderName'] ?? '') as String,
        service: ServiceType.parse(m['service'] as String?),
        pickup: Place.fromMap(Map<String, dynamic>.from(m['pickup'] as Map? ?? {})),
        dropoff: Place.fromMap(Map<String, dynamic>.from(m['dropoff'] as Map? ?? {})),
        offeredFare: (m['offeredFare'] as num?)?.toInt() ?? 0,
        finalFare: (m['finalFare'] as num?)?.toInt(),
        status: parseTripStatus(m['status'] as String?),
        driverId: m['driverId'] as String?,
        driverName: m['driverName'] as String?,
        driverVehicle: m['driverVehicle'] as String?,
        driverPlate: m['driverPlate'] as String?,
        driverRating: (m['driverRating'] as num?)?.toDouble(),
        driverLat: (m['driverLat'] as num?)?.toDouble(),
        driverLng: (m['driverLng'] as num?)?.toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
        rating: (m['rating'] as num?)?.toInt(),
        tip: (m['tip'] as num?)?.toInt() ?? 0,
        payment: (m['payment'] ?? 'wallet') as String,
        note: (m['note'] ?? '') as String,
      );
}

/// A driver's counter-offer on a trip.
class Bid {
  Bid({
    required this.driverId,
    required this.driverName,
    required this.vehicle,
    required this.plate,
    required this.rating,
    required this.trips,
    required this.amount,
    required this.etaMin,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String driverId;
  final String driverName;
  final String vehicle;
  final String plate;
  final double rating;
  final int trips;
  final int amount;
  final int etaMin;
  final DateTime createdAt;

  String get initials {
    final parts = driverName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'driverName': driverName,
        'vehicle': vehicle,
        'plate': plate,
        'rating': rating,
        'trips': trips,
        'amount': amount,
        'etaMin': etaMin,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Bid.fromMap(Map<String, dynamic> m) => Bid(
        driverId: (m['driverId'] ?? '') as String,
        driverName: (m['driverName'] ?? '') as String,
        vehicle: (m['vehicle'] ?? '') as String,
        plate: (m['plate'] ?? '') as String,
        rating: (m['rating'] as num?)?.toDouble() ?? 5,
        trips: (m['trips'] as num?)?.toInt() ?? 0,
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        etaMin: (m['etaMin'] as num?)?.toInt() ?? 5,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
      );
}

class WalletTxn {
  WalletTxn({
    required this.id,
    required this.title,
    required this.amount,
    required this.kind,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;

  /// Positive = money in, negative = money out.
  final int amount;

  /// ride | topup | food | parcel | refund | tip
  final String kind;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'kind': kind,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory WalletTxn.fromMap(String id, Map<String, dynamic> m) => WalletTxn(
        id: id,
        title: (m['title'] ?? '') as String,
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        kind: (m['kind'] ?? 'ride') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.kind = 'info',
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;

  /// trip | promo | wallet | safety | info
  final String kind;
  final DateTime createdAt;
  final bool read;

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'kind': kind,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'read': read,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) => AppNotification(
        id: id,
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        kind: (m['kind'] ?? 'info') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
        read: (m['read'] ?? false) as bool,
      );
}

enum UserRole { rider, driver, store }

class UserProfile {
  UserProfile({
    required this.uid,
    this.name = '',
    this.phone = '',
    this.role = UserRole.rider,
    this.balance = 0,
    this.rating = 5.0,
    this.trips = 0,
    this.online = false,
    this.vehicle = '',
    this.plate = '',
    this.storeName = '',
  });

  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final int balance;
  final double rating;
  final int trips;

  /// Driver availability.
  final bool online;
  final String vehicle;
  final String plate;
  final String storeName;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final s = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return s.isEmpty ? 'W' : s;
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role.name,
        'balance': balance,
        'rating': rating,
        'trips': trips,
        'online': online,
        'vehicle': vehicle,
        'plate': plate,
        'storeName': storeName,
      };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) => UserProfile(
        uid: uid,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        role: UserRole.values.firstWhere((r) => r.name == m['role'], orElse: () => UserRole.rider),
        balance: (m['balance'] as num?)?.toInt() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        trips: (m['trips'] as num?)?.toInt() ?? 0,
        online: (m['online'] ?? false) as bool,
        vehicle: (m['vehicle'] ?? '') as String,
        plate: (m['plate'] ?? '') as String,
        storeName: (m['storeName'] ?? '') as String,
      );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.price,
    this.desc = '',
    this.category = '',
  });
  final String id;
  final String name;
  final String nameAr;
  final int price;
  final String desc;
  final String category;

  String label(bool ar) => ar && nameAr.isNotEmpty ? nameAr : name;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.cuisine,
    required this.rating,
    required this.etaMin,
    required this.deliveryFee,
    required this.place,
    required this.menu,
  });
  final String id;
  final String name;
  final String nameAr;
  final String cuisine;
  final double rating;
  final int etaMin;
  final int deliveryFee;
  final Place place;
  final List<MenuItem> menu;

  String label(bool ar) => ar && nameAr.isNotEmpty ? nameAr : name;
}

class OrderLine {
  const OrderLine({required this.name, required this.qty, required this.price});
  final String name;
  final int qty;
  final int price;

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'price': price};
  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        name: (m['name'] ?? '') as String,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
        price: (m['price'] as num?)?.toInt() ?? 0,
      );
}

enum OrderStatus { placed, preparing, courier, delivered, declined }

/// Food / store order.
class StoreOrder {
  StoreOrder({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.lines,
    required this.total,
    this.status = OrderStatus.placed,
    this.courierName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String storeId;
  final String customerId;
  final String customerName;
  final List<OrderLine> lines;
  final int total;
  final OrderStatus status;
  final String? courierName;
  final DateTime createdAt;

  String get summary => lines.map((l) => '${l.qty}× ${l.name}').join(' · ');
  int get shortNo => 5000 + (id.hashCode.abs() % 1000);

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'customerId': customerId,
        'customerName': customerName,
        'lines': lines.map((l) => l.toMap()).toList(),
        'total': total,
        'status': status.name,
        'courierName': courierName,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory StoreOrder.fromMap(String id, Map<String, dynamic> m) => StoreOrder(
        id: id,
        storeId: (m['storeId'] ?? '') as String,
        customerId: (m['customerId'] ?? '') as String,
        customerName: (m['customerName'] ?? '') as String,
        lines: ((m['lines'] as List?) ?? [])
            .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (m['total'] as num?)?.toInt() ?? 0,
        status: OrderStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => OrderStatus.placed),
        courierName: m['courierName'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
      );
}

/// One message in a trip's rider ↔ driver chat.
class ChatMessage {
  ChatMessage({required this.id, required this.senderId, required this.text, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderId: (m['senderId'] ?? '') as String,
        text: (m['text'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num?)?.toInt() ?? 0),
      );
}
