import 'models.dart';

/// Everything the UI needs from the server. Two implementations:
///  * [FirebaseBackend] — Firebase Auth (phone OTP) + Cloud Firestore.
///  * [DemoBackend] — in-memory, with simulated drivers, so the app is fully
///    usable before a Firebase project is connected.
abstract class WasilhaBackend {
  bool get isDemo;

  // ── Auth ──────────────────────────────────────────────────
  String? get uid;
  Stream<UserProfile?> profile();

  /// Sends an SMS code. [phone] in E.164 (e.g. +249912345678).
  Future<void> sendCode(String phone);

  /// Verifies the 6-digit code; creates the user document on first sign-in.
  Future<void> verifyCode(String code);
  Future<void> signOut();
  Future<void> updateProfile({
    String? name,
    UserRole? role,
    String? vehicle,
    String? plate,
    String? storeName,
  });

  // ── Rider: trips ──────────────────────────────────────────
  /// Creates a trip in `requested` state; nearby drivers can bid on it.
  Future<String> requestTrip({
    required ServiceType service,
    required Place pickup,
    required Place dropoff,
    required int offeredFare,
    String payment = 'wallet',
    String note = '',
  });
  Stream<Trip?> watchTrip(String tripId);
  Stream<List<Bid>> watchBids(String tripId);
  Future<void> acceptBid(String tripId, Bid bid);
  Future<void> cancelTrip(String tripId);

  /// Rates a completed trip, adds optional tip, and charges the wallet.
  Future<void> completeAndRate(String tripId, {required int stars, int tip = 0});
  Stream<List<Trip>> myTrips();

  // ── Driver ────────────────────────────────────────────────
  Future<void> setOnline(bool online);
  Stream<List<Trip>> openRequests();
  Future<void> placeBid(String tripId, {required int amount, required int etaMin});
  Stream<Trip?> driverActiveTrip();
  Future<void> setTripStatus(String tripId, TripStatus status);
  Stream<List<Trip>> driverTrips();

  // ── Wallet ────────────────────────────────────────────────
  Stream<List<WalletTxn>> transactions();

  /// Records a top-up. Real money movement requires a payment provider
  /// (e.g. Bankak / mBOK / card acquirer) — see README.
  Future<void> topUp(int amount, String method);

  // ── Account data ──────────────────────────────────────────
  Stream<List<AppNotification>> notifications();
  Future<void> markNotificationsRead();
  Stream<List<Place>> savedPlaces();
  Future<void> savePlace(Place place);
  Future<void> deletePlace(String id);

  // ── Food & store ──────────────────────────────────────────
  Future<String> placeFoodOrder({
    required Restaurant restaurant,
    required List<OrderLine> lines,
    required int total,
  });
  Stream<List<StoreOrder>> myOrders();

  /// Orders for the store the signed-in store user manages.
  Stream<List<StoreOrder>> storeOrders();
  Future<void> setOrderStatus(String orderId, OrderStatus status);
}

class BackendException implements Exception {
  BackendException(this.message);
  final String message;
  @override
  String toString() => message;
}
