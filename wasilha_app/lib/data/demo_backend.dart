import 'dart:async';
import 'dart:math' as math;

import 'backend.dart';
import 'catalog.dart';
import 'models.dart';

/// In-memory backend. Simulates a small fleet of drivers who bid on rider
/// requests and then drive the trip through its states, and a rider who
/// occasionally posts requests while you are a driver. Any 6-digit OTP works.
class DemoBackend implements WasilhaBackend {
  DemoBackend() {
    _seed();
  }

  final _rng = math.Random();
  final _changes = StreamController<void>.broadcast();
  void _emit() => _changes.add(null);

  /// Emits [read] now and whenever demo state changes.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36) + _rng.nextInt(999).toString();

  // ── State ─────────────────────────────────────────────────
  String? _uid;
  String? _pendingPhone;
  UserProfile? _me;
  final Map<String, Trip> _trips = {};
  final Map<String, List<Bid>> _bids = {};
  final List<WalletTxn> _txns = [];
  final List<AppNotification> _notes = [];
  final List<Place> _saved = [];
  final Map<String, StoreOrder> _orders = {};
  final List<Timer> _timers = [];
  Timer? _riderSim;

  static final _fleet = [
    Bid(driverId: 'd1', driverName: 'Mostafa Ibrahim', vehicle: 'Toyota Corolla · White', plate: 'KH 4721', rating: 4.92, trips: 1840, amount: 0, etaMin: 3),
    Bid(driverId: 'd2', driverName: 'Babiker Hassan', vehicle: 'Hyundai Accent · Silver', plate: 'KH 1186', rating: 4.85, trips: 960, amount: 0, etaMin: 5),
    Bid(driverId: 'd3', driverName: 'Osman Yousif', vehicle: 'Bajaj RE · Green', plate: 'OM 3307', rating: 4.97, trips: 2310, amount: 0, etaMin: 2),
    Bid(driverId: 'd4', driverName: 'Tariq Elamin', vehicle: 'Kia Picanto · Red', plate: 'KN 5590', rating: 4.78, trips: 510, amount: 0, etaMin: 6),
  ];

  void _seed() {
    final now = DateTime.now();
    _saved.addAll([
      Catalog.defaultPickup.copyAsKind('home', 'Home'),
      Catalog.places.firstWhere((p) => p.id == 'africa-rd'),
      Catalog.places.firstWhere((p) => p.id == 'afra'),
    ]);
    _txns.addAll([
      WalletTxn(id: 't1', title: 'Top-up · Bankak', amount: 20000, kind: 'topup', createdAt: now.subtract(const Duration(days: 3))),
      WalletTxn(id: 't2', title: 'Ride · Afra Mall', amount: -2400, kind: 'ride', createdAt: now.subtract(const Duration(days: 2))),
      WalletTxn(id: 't3', title: 'Papa Fool · breakfast', amount: -1850, kind: 'food', createdAt: now.subtract(const Duration(days: 1, hours: 4))),
      WalletTxn(id: 't4', title: 'Raksha · Amarat St 15', amount: -1200, kind: 'ride', createdAt: now.subtract(const Duration(hours: 20))),
      WalletTxn(id: 't5', title: 'Referral bonus', amount: 1500, kind: 'refund', createdAt: now.subtract(const Duration(hours: 6))),
    ]);
    _notes.addAll([
      AppNotification(id: 'n1', title: 'Your driver is rated 4.9★', body: 'Mostafa completed your last trip to Afra Mall.', kind: 'trip', createdAt: now.subtract(const Duration(hours: 2))),
      AppNotification(id: 'n2', title: '20% off raksha this weekend', body: 'Cheapest way across town — auto-applied at checkout.', kind: 'promo', createdAt: now.subtract(const Duration(hours: 9))),
      AppNotification(id: 'n3', title: 'Wallet topped up', body: '20,000 SDG added via Bankak.', kind: 'wallet', createdAt: now.subtract(const Duration(days: 3)), read: true),
      AppNotification(id: 'n4', title: 'Safety check-in', body: 'Share your live trip with two trusted contacts.', kind: 'safety', createdAt: now.subtract(const Duration(days: 4)), read: true),
    ]);
    final past = [
      ('afra', ServiceType.car, 2400, 2),
      ('uofk', ServiceType.raksha, 1200, 3),
      ('airport', ServiceType.car, 3800, 6),
      ('souq-omdurman', ServiceType.moto, 1650, 9),
    ];
    for (final (placeId, svc, fare, daysAgo) in past) {
      final id = _id();
      final d = _fleet[_rng.nextInt(_fleet.length)];
      _trips[id] = Trip(
        id: id,
        riderId: 'demo-user',
        service: svc,
        pickup: Catalog.defaultPickup,
        dropoff: Catalog.places.firstWhere((p) => p.id == placeId),
        offeredFare: fare,
        finalFare: fare,
        status: TripStatus.completed,
        driverId: d.driverId,
        driverName: d.driverName,
        driverVehicle: d.vehicle,
        driverPlate: d.plate,
        driverRating: d.rating,
        createdAt: now.subtract(Duration(days: daysAgo, hours: 3)),
        rating: 5,
      );
    }
    // Two demo store orders.
    for (final o in [
      StoreOrder(id: 'o1', storeId: 'solitaire', customerId: 'c1', customerName: 'Ahmed H.', lines: const [OrderLine(name: 'Cappuccino', qty: 2, price: 900), OrderLine(name: 'Butter croissant', qty: 1, price: 850)], total: 3650, status: OrderStatus.preparing, createdAt: now.subtract(const Duration(minutes: 4))),
      StoreOrder(id: 'o2', storeId: 'solitaire', customerId: 'c2', customerName: 'Layla M.', lines: const [OrderLine(name: 'Iced latte', qty: 1, price: 1100), OrderLine(name: 'Cake slice', qty: 1, price: 1200)], total: 2400, status: OrderStatus.courier, courierName: 'Babiker H.', createdAt: now.subtract(const Duration(minutes: 8))),
      StoreOrder(id: 'o3', storeId: 'solitaire', customerId: 'c3', customerName: 'Omar M.', lines: const [OrderLine(name: 'Espresso', qty: 3, price: 600), OrderLine(name: 'Halloumi sandwich', qty: 2, price: 1640)], total: 4180, createdAt: now.subtract(const Duration(minutes: 1))),
    ]) {
      _orders[o.id] = o;
    }
  }

  void _later(Duration d, void Function() f) => _timers.add(Timer(d, f));

  @override
  bool get isDemo => true;

  // ── Auth ──────────────────────────────────────────────────
  @override
  String? get uid => _uid;

  @override
  Stream<UserProfile?> profile() => _watch(() => _me);

  @override
  Future<void> sendCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _pendingPhone = phone;
  }

  @override
  Future<void> verifyCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw BackendException('Enter the 6-digit code');
    _uid = 'demo-user';
    _me = UserProfile(
      uid: _uid!,
      name: 'Ahmed Hassan',
      phone: _pendingPhone ?? '+249 91 234 5678',
      balance: _txns.fold(0, (s, t) => s + t.amount),
      rating: 4.9,
      trips: 4,
      vehicle: 'Toyota Corolla · White',
      plate: 'KH 2026',
      storeName: 'Solitaire Café',
    );
    _emit();
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _me = null;
    _riderSim?.cancel();
    _emit();
  }

  @override
  Future<void> updateProfile({String? name, UserRole? role, String? vehicle, String? plate, String? storeName}) async {
    final m = _me;
    if (m == null) return;
    _me = UserProfile(
      uid: m.uid,
      name: name ?? m.name,
      phone: m.phone,
      role: role ?? m.role,
      balance: m.balance,
      rating: m.rating,
      trips: m.trips,
      online: m.online,
      vehicle: vehicle ?? m.vehicle,
      plate: plate ?? m.plate,
      storeName: storeName ?? m.storeName,
    );
    _emit();
  }

  void _adjustBalance(int delta, {bool online = false, bool keepOnline = true}) {
    final m = _me!;
    _me = UserProfile(
      uid: m.uid, name: m.name, phone: m.phone, role: m.role,
      balance: m.balance + delta, rating: m.rating, trips: m.trips,
      online: keepOnline ? m.online : online, vehicle: m.vehicle, plate: m.plate, storeName: m.storeName,
    );
  }

  // ── Rider ─────────────────────────────────────────────────
  @override
  Future<String> requestTrip({
    required ServiceType service,
    required Place pickup,
    required Place dropoff,
    required int offeredFare,
    String payment = 'wallet',
    String note = '',
  }) async {
    final id = _id();
    _trips[id] = Trip(
      id: id,
      riderId: _uid ?? 'demo-user',
      riderName: _me?.name ?? '',
      service: service,
      pickup: pickup,
      dropoff: dropoff,
      offeredFare: offeredFare,
      payment: payment,
      note: note,
    );
    _bids[id] = [];
    _emit();
    // Drivers respond with bids around the offered fare.
    final order = [..._fleet]..shuffle(_rng);
    for (var i = 0; i < 3; i++) {
      final d = order[i];
      _later(Duration(milliseconds: 1600 + i * 1700 + _rng.nextInt(700)), () {
        final t = _trips[id];
        if (t == null || t.status != TripStatus.requested) return;
        final factor = [1.0, 1.08, 0.96, 1.15][_rng.nextInt(4)];
        _bids[id]!.add(Bid(
          driverId: d.driverId,
          driverName: d.driverName,
          vehicle: d.vehicle,
          plate: d.plate,
          rating: d.rating,
          trips: d.trips,
          amount: ((offeredFare * factor) / 50).round() * 50,
          etaMin: d.etaMin + _rng.nextInt(3),
        ));
        _emit();
      });
    }
    return id;
  }

  @override
  Stream<Trip?> watchTrip(String tripId) => _watch(() => _trips[tripId]);

  @override
  Stream<List<Bid>> watchBids(String tripId) =>
      _watch(() => List<Bid>.unmodifiable(_bids[tripId] ?? const []));

  @override
  Future<void> acceptBid(String tripId, Bid bid) async {
    final t = _trips[tripId];
    if (t == null) return;
    // Start the driver ~1.2 km away and move toward pickup.
    var lat = t.pickup.lat + 0.011;
    var lng = t.pickup.lng - 0.006;
    _trips[tripId] = t.copyWith(
      status: TripStatus.accepted,
      finalFare: bid.amount,
      driverId: bid.driverId,
      driverName: bid.driverName,
      driverVehicle: bid.vehicle,
      driverPlate: bid.plate,
      driverRating: bid.rating,
      driverLat: lat,
      driverLng: lng,
    );
    _emit();
    _later(const Duration(seconds: 3), () => _setStatus(tripId, TripStatus.arriving));
    var step = 0;
    late Timer mover;
    mover = Timer.periodic(const Duration(seconds: 1), (_) {
      final cur = _trips[tripId];
      if (cur == null || !cur.isActive) return mover.cancel();
      step++;
      final target = cur.status == TripStatus.inProgress ? cur.dropoff : cur.pickup;
      lat += (target.lat - lat) * 0.18;
      lng += (target.lng - lng) * 0.18;
      _trips[tripId] = cur.copyWith(driverLat: lat, driverLng: lng);
      if (step == 12 && cur.status == TripStatus.arriving) {
        _trips[tripId] = _trips[tripId]!.copyWith(status: TripStatus.inProgress);
      }
      if (step == 26 && cur.status == TripStatus.inProgress) {
        _trips[tripId] = _trips[tripId]!.copyWith(status: TripStatus.completed);
        _notify('Trip complete', 'You arrived at ${cur.dropoff.name}. Rate ${cur.driverName}.', 'trip');
        mover.cancel();
      }
      _emit();
    });
    _timers.add(mover);
  }

  void _setStatus(String id, TripStatus s) {
    final t = _trips[id];
    if (t == null || !t.isActive) return;
    if (s.index <= t.status.index && s != TripStatus.cancelled) return;
    _trips[id] = t.copyWith(status: s);
    _emit();
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    final t = _trips[tripId];
    if (t == null) return;
    _trips[tripId] = t.copyWith(status: TripStatus.cancelled);
    _emit();
  }

  @override
  Future<void> completeAndRate(String tripId, {required int stars, int tip = 0}) async {
    final t = _trips[tripId];
    if (t == null) return;
    final charged = t.rating == null; // charge once
    _trips[tripId] = t.copyWith(status: TripStatus.completed, rating: stars, tip: tip);
    if (charged && t.payment == 'wallet' && _me != null) {
      final total = t.fare + tip;
      _txns.insert(0, WalletTxn(id: _id(), title: '${t.service.label} · ${t.dropoff.name}', amount: -total, kind: 'ride'));
      _adjustBalance(-total);
    }
    _emit();
  }

  @override
  Stream<List<Trip>> myTrips() => _watch(() {
        final l = _trips.values.where((t) => t.riderId == (_uid ?? 'demo-user')).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  // ── Driver ────────────────────────────────────────────────
  @override
  Future<void> setOnline(bool online) async {
    if (_me == null) return;
    _adjustBalance(0, online: online, keepOnline: false);
    _riderSim?.cancel();
    if (online) {
      _spawnRiderRequest();
      _riderSim = Timer.periodic(const Duration(seconds: 25), (_) => _spawnRiderRequest());
    }
    _emit();
  }

  static const _riders = ['Sara Ali', 'Hiba Osman', 'Khalid Musa', 'Amna Idris', 'Yasir Bashir'];

  void _spawnRiderRequest() {
    final open = _trips.values.where((t) => t.riderId.startsWith('sim-') && t.status == TripStatus.requested);
    if (open.length >= 3) return;
    final places = [...Catalog.places]..shuffle(_rng);
    final from = places[0], to = places[1];
    final svc = [ServiceType.car, ServiceType.raksha, ServiceType.delivery, ServiceType.moto][_rng.nextInt(4)];
    final id = _id();
    _trips[id] = Trip(
      id: id,
      riderId: 'sim-$id',
      riderName: _riders[_rng.nextInt(_riders.length)],
      service: svc,
      pickup: from,
      dropoff: to,
      offeredFare: svc.fareFor(from.kmTo(to)),
    );
    _bids[id] = [];
    _emit();
  }

  @override
  Stream<List<Trip>> openRequests() => _watch(() {
        final l = _trips.values
            .where((t) => t.status == TripStatus.requested && t.riderId != _uid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  @override
  Future<void> placeBid(String tripId, {required int amount, required int etaMin}) async {
    final t = _trips[tripId];
    final m = _me;
    if (t == null || m == null) return;
    _bids[tripId] = [
      ...(_bids[tripId] ?? []).where((b) => b.driverId != m.uid),
      Bid(driverId: m.uid, driverName: m.name, vehicle: m.vehicle, plate: m.plate, rating: m.rating, trips: m.trips, amount: amount, etaMin: etaMin),
    ];
    _emit();
    // Simulated rider accepts the driver's bid shortly after.
    _later(Duration(milliseconds: 2500 + _rng.nextInt(1500)), () {
      final cur = _trips[tripId];
      if (cur == null || cur.status != TripStatus.requested) return;
      _trips[tripId] = cur.copyWith(
        status: TripStatus.accepted,
        finalFare: amount,
        driverId: m.uid,
        driverName: m.name,
        driverVehicle: m.vehicle,
        driverPlate: m.plate,
        driverRating: m.rating,
      );
      _notify('Offer accepted', '${cur.riderName} accepted $amount SDG — head to ${cur.pickup.name}.', 'trip');
      _emit();
    });
  }

  @override
  Stream<Trip?> driverActiveTrip() => _watch(() {
        for (final t in _trips.values) {
          if (t.driverId == _uid && t.isActive) return t;
        }
        return null;
      });

  @override
  Future<void> setTripStatus(String tripId, TripStatus status) async {
    final t = _trips[tripId];
    if (t == null) return;
    _trips[tripId] = t.copyWith(status: status);
    if (status == TripStatus.completed && t.driverId == _uid && _me != null) {
      final m = _me!;
      _me = UserProfile(uid: m.uid, name: m.name, phone: m.phone, role: m.role, balance: m.balance, rating: m.rating, trips: m.trips + 1, online: m.online, vehicle: m.vehicle, plate: m.plate, storeName: m.storeName);
    }
    _emit();
  }

  @override
  Stream<List<Trip>> driverTrips() => _watch(() {
        final l = _trips.values.where((t) => t.driverId == _uid).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  @override
  Future<void> updateDriverLocation(String tripId, double lat, double lng) async {
    final t = _trips[tripId];
    if (t == null) return;
    _trips[tripId] = t.copyWith(driverLat: lat, driverLng: lng);
    _emit();
  }

  // ── Chat ──────────────────────────────────────────────────
  final Map<String, List<ChatMessage>> _chats = {};

  static const _driverReplies = [
    'On my way 👍',
    'I\'m near the main gate.',
    'Okay, see you in a few minutes.',
    'تمام، أنا قريب.',
  ];

  @override
  Stream<List<ChatMessage>> chat(String tripId) => _watch(() => List.unmodifiable(_chats[tripId] ?? const []));

  @override
  Future<void> sendMessage(String tripId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final me = _uid ?? 'demo-user';
    (_chats[tripId] ??= []).add(ChatMessage(id: _id(), senderId: me, text: t));
    _emit();
    // The simulated other party answers.
    final trip = _trips[tripId];
    if (trip == null) return;
    final other = trip.riderId == me ? (trip.driverId ?? 'driver') : trip.riderId;
    _later(Duration(milliseconds: 1500 + _rng.nextInt(1500)), () {
      final reply = trip.riderId == me
          ? _driverReplies[_rng.nextInt(_driverReplies.length)]
          : 'Thanks! I\'m waiting outside.';
      (_chats[tripId] ??= []).add(ChatMessage(id: _id(), senderId: other, text: reply));
      _emit();
    });
  }

  @override
  Future<void> registerPushToken(String token) async {}

  // ── Wallet ────────────────────────────────────────────────
  @override
  Stream<List<WalletTxn>> transactions() => _watch(() {
        final l = [..._txns]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  @override
  Future<void> topUp(int amount, String method) async {
    if (amount <= 0) throw BackendException('Enter an amount');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _txns.insert(0, WalletTxn(id: _id(), title: 'Top-up · $method', amount: amount, kind: 'topup'));
    _adjustBalance(amount);
    _notify('Wallet topped up', '$amount SDG added via $method.', 'wallet');
    _emit();
  }

  // ── Account ───────────────────────────────────────────────
  void _notify(String title, String body, String kind) =>
      _notes.insert(0, AppNotification(id: _id(), title: title, body: body, kind: kind));

  @override
  Stream<List<AppNotification>> notifications() => _watch(() => List.unmodifiable(_notes));

  @override
  Future<void> markNotificationsRead() async {
    for (var i = 0; i < _notes.length; i++) {
      final n = _notes[i];
      _notes[i] = AppNotification(id: n.id, title: n.title, body: n.body, kind: n.kind, createdAt: n.createdAt, read: true);
    }
    _emit();
  }

  @override
  Stream<List<Place>> savedPlaces() => _watch(() => List.unmodifiable(_saved));

  @override
  Future<void> savePlace(Place place) async {
    _saved.removeWhere((p) => p.id == place.id);
    _saved.add(place);
    _emit();
  }

  @override
  Future<void> deletePlace(String id) async {
    _saved.removeWhere((p) => p.id == id);
    _emit();
  }

  // ── Food & store ──────────────────────────────────────────
  @override
  Future<String> placeFoodOrder({required Restaurant restaurant, required List<OrderLine> lines, required int total}) async {
    final m = _me;
    if (m == null) throw BackendException('Sign in first');
    if (m.balance < total) throw BackendException('Insufficient wallet balance — top up first');
    final id = _id();
    _orders[id] = StoreOrder(id: id, storeId: restaurant.id, customerId: m.uid, customerName: m.name, lines: lines, total: total);
    _txns.insert(0, WalletTxn(id: _id(), title: '${restaurant.name} · order', amount: -total, kind: 'food'));
    _adjustBalance(-total);
    _later(const Duration(seconds: 4), () => setOrderStatus(id, OrderStatus.preparing));
    _later(const Duration(seconds: 12), () => setOrderStatus(id, OrderStatus.courier));
    _emit();
    return id;
  }

  @override
  Stream<List<StoreOrder>> myOrders() => _watch(() {
        final l = _orders.values.where((o) => o.customerId == _uid).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  @override
  Stream<List<StoreOrder>> storeOrders() => _watch(() {
        final l = _orders.values.where((o) => o.storeId == 'solitaire').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return l;
      });

  @override
  Future<void> setOrderStatus(String orderId, OrderStatus status) async {
    final o = _orders[orderId];
    if (o == null) return;
    _orders[orderId] = StoreOrder(
      id: o.id, storeId: o.storeId, customerId: o.customerId, customerName: o.customerName,
      lines: o.lines, total: o.total, status: status, createdAt: o.createdAt,
      courierName: status == OrderStatus.courier ? (o.courierName ?? 'Mostafa I.') : o.courierName,
    );
    _emit();
  }
}

extension on Place {
  Place copyAsKind(String kind, String name) =>
      Place(id: id, name: name, nameAr: kind == 'home' ? 'البيت' : nameAr, area: this.name, lat: lat, lng: lng, kind: kind);
}
