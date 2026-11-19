import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'backend.dart';
import 'models.dart';

/// Firestore layout
///   users/{uid}                       UserProfile
///   users/{uid}/transactions/{id}     WalletTxn
///   users/{uid}/notifications/{id}    AppNotification
///   users/{uid}/places/{id}           Place
///   trips/{id}                        Trip
///   trips/{id}/bids/{driverId}        Bid
///   orders/{id}                       StoreOrder
/// See firestore.rules in the project root.
class FirebaseBackend implements WasilhaBackend {
  FirebaseBackend({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  String? _verificationId;
  int? _resendToken;

  @override
  bool get isDemo => false;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _trips => _db.collection('trips');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  DocumentReference<Map<String, dynamic>> _me() {
    final u = uid;
    if (u == null) throw BackendException('Not signed in');
    return _users.doc(u);
  }

  // ── Auth ──────────────────────────────────────────────────
  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Stream<UserProfile?> profile() => _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(null);
        return _users.doc(user.uid).snapshots().map(
              (s) => s.exists ? UserProfile.fromMap(user.uid, s.data()!) : UserProfile(uid: user.uid, phone: user.phoneNumber ?? ''),
            );
      });

  @override
  Future<void> sendCode(String phone) {
    final done = Completer<void>();
    _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        // Android instant verification / auto-retrieval.
        await _auth.signInWithCredential(cred);
        await _ensureUserDoc();
        if (!done.isCompleted) done.complete();
      },
      verificationFailed: (e) {
        if (!done.isCompleted) done.completeError(BackendException(e.message ?? 'Verification failed'));
      },
      codeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
        if (!done.isCompleted) done.complete();
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
    return done.future;
  }

  @override
  Future<void> verifyCode(String code) async {
    if (_auth.currentUser != null) return _ensureUserDoc(); // auto-verified
    final id = _verificationId;
    if (id == null) throw BackendException('Request a code first');
    try {
      await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
    } on FirebaseAuthException catch (e) {
      throw BackendException(e.code == 'invalid-verification-code' ? 'Wrong code — try again' : (e.message ?? e.code));
    }
    await _ensureUserDoc();
  }

  Future<void> _ensureUserDoc() async {
    final user = _auth.currentUser!;
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(UserProfile(uid: user.uid, phone: user.phoneNumber ?? '').toMap());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateProfile({String? name, UserRole? role, String? vehicle, String? plate, String? storeName}) =>
      _me().set({
        'name': ?name,
        'role': ?role?.name,
        'vehicle': ?vehicle,
        'plate': ?plate,
        'storeName': ?storeName,
      }, SetOptions(merge: true));

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
    final me = await _me().get();
    final trip = Trip(
      id: '',
      riderId: uid!,
      riderName: (me.data()?['name'] ?? '') as String,
      service: service,
      pickup: pickup,
      dropoff: dropoff,
      offeredFare: offeredFare,
      payment: payment,
      note: note,
    );
    final ref = await _trips.add(trip.toMap());
    return ref.id;
  }

  @override
  Stream<Trip?> watchTrip(String tripId) =>
      _trips.doc(tripId).snapshots().map((s) => s.exists ? Trip.fromMap(s.id, s.data()!) : null);

  @override
  Stream<List<Bid>> watchBids(String tripId) => _trips
      .doc(tripId)
      .collection('bids')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map((d) => Bid.fromMap(d.data())).toList());

  @override
  Future<void> acceptBid(String tripId, Bid bid) => _db.runTransaction((tx) async {
        final ref = _trips.doc(tripId);
        final snap = await tx.get(ref);
        if (snap.data()?['status'] != TripStatus.requested.name) {
          throw BackendException('This request is no longer open');
        }
        tx.update(ref, {
          'status': TripStatus.accepted.name,
          'finalFare': bid.amount,
          'driverId': bid.driverId,
          'driverName': bid.driverName,
          'driverVehicle': bid.vehicle,
          'driverPlate': bid.plate,
          'driverRating': bid.rating,
        });
      });

  @override
  Future<void> cancelTrip(String tripId) => _trips.doc(tripId).update({'status': TripStatus.cancelled.name});

  @override
  Future<void> completeAndRate(String tripId, {required int stars, int tip = 0}) =>
      // Money moves server-side (functions/src/index.ts → settleTrip / settleTip).
      _trips.doc(tripId).update({'rating': stars, 'tip': tip, 'status': TripStatus.completed.name});

  @override
  Stream<List<Trip>> myTrips() => _trips
      .where('riderId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map((d) => Trip.fromMap(d.id, d.data())).toList());

  // ── Driver ────────────────────────────────────────────────
  @override
  Future<void> setOnline(bool online) => _me().update({'online': online});

  @override
  Stream<List<Trip>> openRequests() => _trips
      .where('status', isEqualTo: TripStatus.requested.name)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((q) => q.docs.map((d) => Trip.fromMap(d.id, d.data())).where((t) => t.riderId != uid).toList());

  @override
  Future<void> placeBid(String tripId, {required int amount, required int etaMin}) async {
    final me = UserProfile.fromMap(uid!, (await _me().get()).data() ?? {});
    await _trips.doc(tripId).collection('bids').doc(me.uid).set(Bid(
          driverId: me.uid,
          driverName: me.name,
          vehicle: me.vehicle,
          plate: me.plate,
          rating: me.rating,
          trips: me.trips,
          amount: amount,
          etaMin: etaMin,
        ).toMap());
  }

  static const _activeStates = ['accepted', 'arriving', 'inProgress'];

  @override
  Stream<Trip?> driverActiveTrip() => _trips
      .where('driverId', isEqualTo: uid)
      .where('status', whereIn: _activeStates)
      .limit(1)
      .snapshots()
      .map((q) => q.docs.isEmpty ? null : Trip.fromMap(q.docs.first.id, q.docs.first.data()));

  @override
  Future<void> setTripStatus(String tripId, TripStatus status) async {
    await _trips.doc(tripId).update({'status': status.name});
    if (status == TripStatus.completed) {
      await _me().update({'trips': FieldValue.increment(1)});
    }
  }

  @override
  Future<void> updateDriverLocation(String tripId, double lat, double lng) =>
      _trips.doc(tripId).update({'driverLat': lat, 'driverLng': lng});

  @override
  Stream<List<Trip>> driverTrips() => _trips
      .where('driverId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map((d) => Trip.fromMap(d.id, d.data())).toList());

  // ── Chat ──────────────────────────────────────────────────
  @override
  Stream<List<ChatMessage>> chat(String tripId) => _trips
      .doc(tripId)
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map((q) => q.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  @override
  Future<void> sendMessage(String tripId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _trips.doc(tripId).collection('messages').add(ChatMessage(id: '', senderId: uid!, text: t).toMap());
  }

  // ── Push ──────────────────────────────────────────────────
  @override
  Future<void> registerPushToken(String token) =>
      _me().set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));

  // ── Wallet ────────────────────────────────────────────────
  @override
  Stream<List<WalletTxn>> transactions() => _me()
      .collection('transactions')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map((d) => WalletTxn.fromMap(d.id, d.data())).toList());

  @override
  Future<void> topUp(int amount, String method) async {
    if (amount <= 0) throw BackendException('Enter an amount');
    final ref = await _db.collection('topups').add({
      'uid': uid,
      'amount': amount,
      'method': method,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    // Wait briefly for the server to confirm (instant with ALLOW_FAKE_TOPUPS;
    // with a real provider the doc gets a checkoutUrl / is paid via webhook).
    try {
      final done = await ref.snapshots().firstWhere((d) => d.data()?['status'] != 'pending').timeout(const Duration(seconds: 20));
      if (done.data()?['status'] == 'rejected') throw BackendException('Top-up was rejected');
    } on TimeoutException {
      throw BackendException('Top-up is pending payment confirmation');
    }
  }

  // ── Account ───────────────────────────────────────────────
  @override
  Stream<List<AppNotification>> notifications() => _me()
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());

  @override
  Future<void> markNotificationsRead() async {
    final q = await _me().collection('notifications').where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Stream<List<Place>> savedPlaces() => _me()
      .collection('places')
      .snapshots()
      .map((q) => q.docs.map((d) => Place.fromMap({...d.data(), 'id': d.id})).toList());

  @override
  Future<void> savePlace(Place place) => _me().collection('places').doc(place.id).set(place.toMap());

  @override
  Future<void> deletePlace(String id) => _me().collection('places').doc(id).delete();

  // ── Food & store ──────────────────────────────────────────
  @override
  Future<String> placeFoodOrder({required Restaurant restaurant, required List<OrderLine> lines, required int total}) async {
    final me = UserProfile.fromMap(uid!, (await _me().get()).data() ?? {});
    if (me.balance < total) throw BackendException('Insufficient wallet balance — top up first');
    // The wallet is charged by the onOrderCreated Cloud Function.
    final ref = await _orders.add(StoreOrder(
      id: '',
      storeId: restaurant.id,
      customerId: me.uid,
      customerName: me.name,
      lines: lines,
      total: total,
    ).toMap());
    return ref.id;
  }

  @override
  Stream<List<StoreOrder>> myOrders() => _orders
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((q) => q.docs.map((d) => StoreOrder.fromMap(d.id, d.data())).toList());

  @override
  Stream<List<StoreOrder>> storeOrders() async* {
    // The store user's `storeName` field holds the restaurant id they manage.
    final me = await _me().get();
    final storeId = (me.data()?['storeName'] ?? '') as String;
    yield* _orders
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((q) => q.docs.map((d) => StoreOrder.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<void> setOrderStatus(String orderId, OrderStatus status) =>
      _orders.doc(orderId).update({'status': status.name});
}
