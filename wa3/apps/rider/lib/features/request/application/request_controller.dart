import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:wa3_core/wa3_core.dart';

import '../../places/domain/places_repository.dart';
import '../../trips/domain/trip_repository.dart';

/// Progressive request: places → category → server draft (route + price) →
/// fare within the quote → confirm. Each step appears only when needed.
class RequestController extends ChangeNotifier {
  RequestController({
    required this._trips,
    required this._places,
    required this.lang,
    this.pickup,
    required this.dropoff,
    this.category,
    DraftResult? initialDraft,
    this.preferredFare,
  }) {
    if (initialDraft != null) {
      final f = preferredFare;
      priceRefreshed = f != null && !initialDraft.quote.contains(f);
      _useDraft(initialDraft);
    }
    _labelPickup();
  }

  final TripRepository _trips;
  final PlacesRepository _places;
  final String lang;

  Place? pickup;
  Place dropoff;
  Category? category;

  /// A fare the rider asked for before (retry); used when still in range.
  int? preferredFare;

  DraftResult? draft;
  bool drafting = false;
  ApiFailure? draftError;

  /// Selected fare; null while the typed amount is not a valid number.
  int? fare;

  /// The draft was re-created after confirm failed (e.g. it expired).
  bool priceRefreshed = false;
  int _seq = 0;
  bool _disposed = false;

  bool get fareValid => draft != null && fare != null && draft!.quote.contains(fare!);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// "Current location" pickups start unlabeled; ask the server for a name.
  Future<void> _labelPickup() async {
    final p = pickup;
    if (p == null || p.label.isNotEmpty) return;
    try {
      final label = await _places.label(p.point, lang: lang);
      if (identical(pickup, p)) {
        pickup = Place(point: p.point, label: label);
        _notify();
      }
    } catch (_) {
      // The server falls back to coordinates; the screen says "Current location".
    }
  }

  void setPickup(Place p) {
    pickup = p;
    _labelPickup();
    _placesChanged();
  }

  void setDropoff(Place p) {
    dropoff = p;
    _placesChanged();
  }

  void _placesChanged() {
    draft = null;
    draftError = null;
    _notify();
    if (category != null) createDraft();
  }

  Future<void> selectCategory(Category c) async {
    if (c == category && (draft != null || drafting)) return;
    category = c;
    await createDraft();
  }

  Future<void> createDraft() async {
    final p = pickup, c = category;
    if (p == null || c == null) return;
    final seq = ++_seq;
    drafting = true;
    draftError = null;
    draft = null;
    _notify();
    try {
      final d = await _trips.createDraft(pickup: p, dropoff: dropoff, category: c, key: IntentKey.generate());
      if (seq != _seq) return;
      _useDraft(d);
    } on ApiFailure catch (e) {
      if (seq != _seq) return;
      draftError = e;
    } finally {
      if (seq == _seq) {
        drafting = false;
        _notify();
      }
    }
  }

  void _useDraft(DraftResult d) {
    draft = d;
    final want = preferredFare ?? fare ?? d.quote.referenceFare;
    fare = want.clamp(d.quote.minFare, d.quote.maxFare);
  }

  void setFare(int? value) {
    fare = value;
    _notify();
  }

  /// `confirmRequest`; returns the trip id. A failure that means the draft is
  /// gone (expired/replaced) fetches a new price, then rethrows to explain.
  Future<String> confirm() async {
    final d = draft!;
    try {
      await _trips.confirmRequest(tripId: d.tripId, proposedFare: fare!, expectedRevision: d.revision, key: IntentKey.generate());
      return d.tripId;
    } on ApiFailure catch (e) {
      if (e.code == 'invalid_transition' || e.code == 'not_found' || e.isStale) {
        preferredFare = fare;
        priceRefreshed = true;
        createDraft();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
